import hmac
import hashlib
import secrets
import time
from contextlib import asynccontextmanager
from datetime import datetime, timedelta
from pathlib import Path

from fastapi import (
    BackgroundTasks,
    Depends,
    FastAPI,
    File,
    HTTPException,
    Query,
    Request,
    Response,
    UploadFile,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pwdlib import PasswordHash
from sqlalchemy import delete, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from database import obtener_sesion
from migrar import migrar
from correo import CORREO_CONFIGURADO, enviar_correo
from models import (
    Blog,
    Comentario,
    Guardado,
    Notificacion,
    Reaccion,
    Recuperacion,
    Usuario,
    Valoracion,
)
from schemas import (
    BlogActualizar,
    BlogCrear,
    BlogRespuesta,
    ComentarioCrear,
    ComentarioRespuesta,
    HomeRespuesta,
    LoginRequest,
    LoginRespuesta,
    NotificacionesRespuesta,
    ReaccionCrear,
    RecuperarConfirmacion,
    RecuperarSolicitud,
    UsuarioActualizar,
    UsuarioCrear,
    UsuarioRespuesta,
    ValoracionCrear,
    ValoracionRespuesta,
)
from security import SECRET_DEFINIDA, SECRET_KEY, crear_token, leer_token, revocar_token

ADMIN = 1
GENERAL = 2

password_hash = PasswordHash.recommended()
# Hash de relleno para que el login tarde lo mismo exista o no el correo.
_HASH_RELLENO = password_hash.hash("relleno-no-usar-1")


@asynccontextmanager
async def lifespan(app: FastAPI):
    migrar()  # crea tablas y columnas nuevas sin tocar los datos existentes
    if not SECRET_DEFINIDA:
        print(
            "AVISO: no hay SECRET_KEY en .env; se usa una clave temporal "
            "y las sesiones se cierran al reiniciar la API."
        )
    yield


app = FastAPI(title="API de Cineverse", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

bearer = HTTPBearer(auto_error=False)

# Pósters subidos desde la computadora se guardan aquí y se sirven en /uploads.
CARPETA_UPLOADS = Path(__file__).resolve().parent / "uploads"
CARPETA_UPLOADS.mkdir(exist_ok=True)
app.mount("/uploads", StaticFiles(directory=CARPETA_UPLOADS), name="uploads")


# =====================================================================
# Seguridad: sesión y permisos (siempre se comprueban en el servidor)
# =====================================================================

def usuario_opcional(
    credenciales: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(obtener_sesion),
) -> Usuario | None:
    if credenciales is None:
        return None
    datos = leer_token(credenciales.credentials)
    if datos is None:
        raise HTTPException(
            status_code=401, detail="Tu sesión expiró. Inicia sesión de nuevo"
        )
    usuario = db.get(Usuario, int(datos["sub"]))
    if usuario is None:
        raise HTTPException(status_code=401, detail="Sesión no válida")
    return usuario


def usuario_actual(usuario: Usuario | None = Depends(usuario_opcional)) -> Usuario:
    if usuario is None:
        raise HTTPException(status_code=401, detail="Inicia sesión para continuar")
    return usuario


def solo_admin(usuario: Usuario = Depends(usuario_actual)) -> Usuario:
    if usuario.tip_usu != ADMIN:
        raise HTTPException(status_code=403, detail="Solo el administrador puede hacer esto")
    return usuario


# Intentos fallidos de login: (ip, correo) -> momentos de cada intento.
_intentos: dict[tuple[str, str], list[float]] = {}
MAX_INTENTOS = 5
VENTANA_SEG = 300


def _limitar_intentos(clave: tuple[str, str]) -> None:
    ahora = time.time()
    recientes = [t for t in _intentos.get(clave, []) if ahora - t < VENTANA_SEG]
    _intentos[clave] = recientes
    if len(recientes) >= MAX_INTENTOS:
        raise HTTPException(
            status_code=429,
            detail="Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo",
        )


@app.get("/")
def inicio():
    return {"mensaje": "API de Cineverse funcionando correctamente"}


@app.post("/login", response_model=LoginRespuesta)
def iniciar_sesion(
    datos: LoginRequest,
    request: Request,
    db: Session = Depends(obtener_sesion),
):
    correo = datos.mail.strip().lower()
    ip = request.client.host if request.client else "?"
    clave = (ip, correo)
    _limitar_intentos(clave)

    usuario = db.scalar(select(Usuario).where(func.lower(Usuario.mail) == correo))
    hash_guardado = usuario.pass_hash if usuario else _HASH_RELLENO
    correcto = password_hash.verify(datos.password, hash_guardado)

    # Mismo mensaje si falla el correo o la contraseña (RNF002).
    if usuario is None or not correcto:
        _intentos.setdefault(clave, []).append(time.time())
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")

    _intentos.pop(clave, None)
    return {
        "access_token": crear_token(usuario.id_usr, usuario.tip_usu),
        "token_type": "bearer",
        "usuario": usuario,
    }


@app.post("/logout", status_code=204)
def cerrar_sesion(
    credenciales: HTTPAuthorizationCredentials | None = Depends(bearer),
):
    if credenciales is not None:
        datos = leer_token(credenciales.credentials)
        if datos is not None:
            revocar_token(datos)
    return Response(status_code=204)


@app.get("/yo", response_model=UsuarioRespuesta)
def mi_usuario(usuario: Usuario = Depends(usuario_actual)):
    return usuario


# =====================================================================
# Notificaciones (la campana)
# =====================================================================

def _notificar(
    db: Session,
    destino_id: int | None,
    actor: Usuario,
    tipo: str,
    blog_id: int | None,
    ref_id: int,
    texto: str,
) -> None:
    """Crea un aviso para el autor (nunca para uno mismo). No hace commit."""
    if destino_id is None or destino_id == actor.id_usr:
        return
    # Si el mismo usuario repite la acción (cambia su estrella o su emoji),
    # se reemplaza el aviso anterior en lugar de llenar la campana.
    if tipo in ("valoracion", "reaccion"):
        db.execute(
            delete(Notificacion).where(
                Notificacion.usr_id == destino_id,
                Notificacion.actor_id == actor.id_usr,
                Notificacion.tipo == tipo,
                Notificacion.ref_id == ref_id,
            )
        )
    db.add(
        Notificacion(
            usr_id=destino_id,
            actor_id=actor.id_usr,
            tipo=tipo,
            blog_id=blog_id,
            ref_id=ref_id,
            texto=texto[:300],
            fecha=datetime.now(),
            leida=0,
        )
    )


@app.get("/notificaciones", response_model=NotificacionesRespuesta)
def listar_notificaciones(
    limit: int = Query(30, ge=1, le=100),
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    items = db.scalars(
        select(Notificacion)
        .where(Notificacion.usr_id == usuario.id_usr)
        .order_by(Notificacion.fecha.desc(), Notificacion.id.desc())
        .limit(limit)
    ).all()
    no_leidas = db.scalar(
        select(func.count())
        .select_from(Notificacion)
        .where(Notificacion.usr_id == usuario.id_usr, Notificacion.leida == 0)
    )
    return {
        "no_leidas": no_leidas or 0,
        "items": [
            {
                "id": n.id,
                "tipo": n.tipo,
                "texto": n.texto,
                "blog_id": n.blog_id,
                "fecha": n.fecha,
                "leida": bool(n.leida),
            }
            for n in items
        ],
    }


@app.post("/notificaciones/leidas", status_code=204)
def marcar_notificaciones_leidas(
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    db.query(Notificacion).filter(
        Notificacion.usr_id == usuario.id_usr, Notificacion.leida == 0
    ).update({Notificacion.leida: 1})
    db.commit()
    return Response(status_code=204)


@app.delete("/notificaciones", status_code=204)
def borrar_notificaciones(
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    db.execute(delete(Notificacion).where(Notificacion.usr_id == usuario.id_usr))
    db.commit()
    return Response(status_code=204)


# =====================================================================
# Recuperar contraseña por correo
# =====================================================================

MINUTOS_CODIGO = 15
MAX_INTENTOS_CODIGO = 5
_pedidos_recuperacion: dict[str, list[float]] = {}


def _hash_codigo(usuario_id: int, codigo: str) -> str:
    return hmac.new(
        SECRET_KEY.encode(), f"{usuario_id}:{codigo}".encode(), hashlib.sha256
    ).hexdigest()


def _limitar_recuperacion(request: Request, maximo: int = 8) -> None:
    ip = request.client.host if request.client else "?"
    ahora = time.time()
    recientes = [t for t in _pedidos_recuperacion.get(ip, []) if ahora - t < 900]
    if len(recientes) >= maximo:
        raise HTTPException(
            status_code=429, detail="Demasiadas solicitudes. Espera unos minutos"
        )
    recientes.append(ahora)
    _pedidos_recuperacion[ip] = recientes


def _enviar_codigo(correo: str, nombre: str, codigo: str) -> None:
    cuerpo = (
        f"Hola {nombre},\n\n"
        f"Tu código para restablecer tu contraseña de Cineverse es: {codigo}\n\n"
        f"Vence en {MINUTOS_CODIGO} minutos. Si no lo pediste tú, ignora este mensaje.\n"
    )
    enviado = enviar_correo(correo, "Código para restablecer tu contraseña", cuerpo)
    if not enviado and not CORREO_CONFIGURADO:
        # Modo pruebas: sin SMTP el código se ve en la terminal de uvicorn.
        print(f"[recuperación] Código para {correo}: {codigo}")


MENSAJE_SOLICITUD = (
    "Si el correo está registrado, te enviamos un código de 6 dígitos. "
    f"Vence en {MINUTOS_CODIGO} minutos."
)


@app.post("/recuperar/solicitar")
def solicitar_recuperacion(
    datos: RecuperarSolicitud,
    request: Request,
    tareas: BackgroundTasks,
    db: Session = Depends(obtener_sesion),
):
    _limitar_recuperacion(request)
    correo = datos.mail.strip().lower()
    usuario = db.scalar(select(Usuario).where(func.lower(Usuario.mail) == correo))

    if usuario is not None:
        codigo = f"{secrets.randbelow(10**6):06d}"
        db.execute(delete(Recuperacion).where(Recuperacion.usr_id == usuario.id_usr))
        db.add(
            Recuperacion(
                usr_id=usuario.id_usr,
                codigo_hash=_hash_codigo(usuario.id_usr, codigo),
                expira=datetime.now() + timedelta(minutes=MINUTOS_CODIGO),
                intentos=0,
            )
        )
        db.commit()
        # En segundo plano: la respuesta tarda igual exista o no el correo.
        tareas.add_task(_enviar_codigo, usuario.mail, usuario.nom_usr, codigo)

    return {"mensaje": MENSAJE_SOLICITUD}


@app.post("/recuperar/confirmar")
def confirmar_recuperacion(
    datos: RecuperarConfirmacion,
    request: Request,
    db: Session = Depends(obtener_sesion),
):
    _limitar_recuperacion(request, maximo=15)
    invalido = HTTPException(status_code=400, detail="Código inválido o vencido")

    correo = datos.mail.strip().lower()
    usuario = db.scalar(select(Usuario).where(func.lower(Usuario.mail) == correo))
    if usuario is None:
        raise invalido

    reg = db.scalar(select(Recuperacion).where(Recuperacion.usr_id == usuario.id_usr))
    if reg is None or reg.expira < datetime.now():
        raise invalido
    if reg.intentos >= MAX_INTENTOS_CODIGO:
        db.delete(reg)
        db.commit()
        raise invalido

    if not hmac.compare_digest(reg.codigo_hash, _hash_codigo(usuario.id_usr, datos.codigo)):
        reg.intentos += 1
        db.commit()
        raise invalido

    usuario.pass_hash = password_hash.hash(datos.password)
    db.execute(delete(Recuperacion).where(Recuperacion.usr_id == usuario.id_usr))
    db.commit()
    return {"mensaje": "Contraseña actualizada. Ya puedes iniciar sesión"}


# =====================================================================
# Usuarios
# =====================================================================

@app.get("/usuarios", response_model=list[UsuarioRespuesta])
def listar_usuarios(
    _: Usuario = Depends(solo_admin),
    db: Session = Depends(obtener_sesion),
):
    return db.scalars(select(Usuario).order_by(Usuario.id_usr)).all()


@app.post("/usuarios", response_model=UsuarioRespuesta, status_code=201)
def crear_usuario(
    datos: UsuarioCrear,
    quien: Usuario | None = Depends(usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    # El registro público siempre crea usuarios generales.
    # Solo un administrador puede crear otro administrador.
    es_admin = quien is not None and quien.tip_usu == ADMIN
    tipo = datos.tip_usu if es_admin and datos.tip_usu in (ADMIN, GENERAL) else GENERAL

    nombre = datos.nom_usr.strip()
    correo = datos.mail.strip().lower()

    if db.scalar(select(Usuario.id_usr).where(func.lower(Usuario.nom_usr) == nombre.lower())):
        raise HTTPException(status_code=409, detail="El nombre de usuario ya está registrado")
    if db.scalar(select(Usuario.id_usr).where(func.lower(Usuario.mail) == correo)):
        raise HTTPException(status_code=409, detail="El correo ya está registrado")

    usuario = Usuario(
        nom_usr=nombre,
        mail=correo,
        pass_hash=password_hash.hash(datos.password),
        dir_usr=datos.dir_usr.strip() if datos.dir_usr and datos.dir_usr.strip() else None,
        tip_usu=tipo,
    )
    db.add(usuario)
    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="El correo ya está registrado")
    return usuario


@app.put("/usuarios/{usuario_id}", response_model=UsuarioRespuesta)
def actualizar_usuario(
    usuario_id: int,
    datos: UsuarioActualizar,
    quien: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    es_admin = quien.tip_usu == ADMIN
    if quien.id_usr != usuario_id and not es_admin:
        raise HTTPException(status_code=403, detail="No puedes modificar a otro usuario")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    nombre = datos.nom_usr.strip()
    correo = datos.mail.strip().lower()

    if db.scalar(
        select(Usuario.id_usr).where(
            func.lower(Usuario.mail) == correo, Usuario.id_usr != usuario_id
        )
    ):
        raise HTTPException(status_code=409, detail="El correo ya está registrado por otro usuario")
    if db.scalar(
        select(Usuario.id_usr).where(
            func.lower(Usuario.nom_usr) == nombre.lower(), Usuario.id_usr != usuario_id
        )
    ):
        raise HTTPException(status_code=409, detail="El nombre de usuario ya está registrado")

    usuario.nom_usr = nombre
    usuario.mail = correo
    usuario.dir_usr = datos.dir_usr.strip() if datos.dir_usr and datos.dir_usr.strip() else None

    # Solo un administrador cambia el rol, y nunca el suyo propio
    # (para no quedarse sin administradores).
    if es_admin and quien.id_usr != usuario_id and datos.tip_usu in (ADMIN, GENERAL):
        usuario.tip_usu = datos.tip_usu

    if datos.password:
        usuario.pass_hash = password_hash.hash(datos.password)

    try:
        db.commit()
        db.refresh(usuario)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="No se pudieron guardar los cambios")
    return usuario


@app.delete("/usuarios/{usuario_id}", status_code=204)
def eliminar_usuario(
    usuario_id: int,
    quien: Usuario = Depends(solo_admin),
    db: Session = Depends(obtener_sesion),
):
    if quien.id_usr == usuario_id:
        raise HTTPException(status_code=400, detail="No puedes eliminar tu propia cuenta")

    usuario = db.get(Usuario, usuario_id)
    if usuario is None:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    # Se elimina su actividad; sus publicaciones se conservan sin autor.
    ids_comentarios = select(Comentario.id_com).where(Comentario.usr_id == usuario_id)
    db.execute(delete(Reaccion).where(Reaccion.com_id.in_(ids_comentarios)))
    db.execute(delete(Reaccion).where(Reaccion.usr_id == usuario_id))
    db.execute(delete(Comentario).where(Comentario.usr_id == usuario_id))
    db.execute(delete(Valoracion).where(Valoracion.usr_id == usuario_id))
    db.execute(delete(Guardado).where(Guardado.usr_id == usuario_id))
    db.execute(delete(Recuperacion).where(Recuperacion.usr_id == usuario_id))
    db.execute(
        delete(Notificacion).where(
            or_(Notificacion.usr_id == usuario_id, Notificacion.actor_id == usuario_id)
        )
    )
    for blog in db.scalars(select(Blog).where(Blog.usr_id == usuario_id)).all():
        blog.usr_id = None
    db.delete(usuario)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="No se pudo eliminar el usuario")
    return Response(status_code=204)


# =====================================================================
# Publicaciones (blog)
# =====================================================================

def _consulta_blog():
    """SELECT de publicaciones con autor y promedio de valoraciones."""
    val = (
        select(
            Valoracion.blog_id.label("blog_id"),
            func.avg(Valoracion.puntos).label("prom"),
            func.count(Valoracion.id).label("total"),
        )
        .group_by(Valoracion.blog_id)
        .subquery()
    )
    consulta = (
        select(Blog, Usuario.nom_usr, val.c.prom, val.c.total)
        .outerjoin(Usuario, Usuario.id_usr == Blog.usr_id)
        .outerjoin(val, val.c.blog_id == Blog.id_blog)
    )
    return consulta, val


def _blog_dict(fila, guardados: set[int], mi_valoracion: int | None = None) -> dict:
    blog, autor, prom, total = fila
    return {
        "id_blog": blog.id_blog,
        "titulo": blog.titulo,
        "descripcion": blog.descripcion,
        "img": blog.img,
        "tags": blog.tags,
        "tipo": blog.tipo or "articulo",
        "genero": blog.genero,
        "anio": blog.anio,
        "fecha": blog.fecha,
        "destacado": bool(blog.destacado),
        "autor_id": blog.usr_id,
        "autor": autor,
        "promedio": round(float(prom), 1) if prom is not None else None,
        "total_valoraciones": int(total or 0),
        "guardado": blog.id_blog in guardados,
        "mi_valoracion": mi_valoracion,
    }


def _ids_guardados(db: Session, usuario: Usuario | None) -> set[int]:
    if usuario is None:
        return set()
    return set(db.scalars(select(Guardado.blog_id).where(Guardado.usr_id == usuario.id_usr)).all())


def _lista(db: Session, consulta, usuario: Usuario | None) -> list[dict]:
    guardados = _ids_guardados(db, usuario)
    return [_blog_dict(fila, guardados) for fila in db.execute(consulta).all()]


@app.get("/blog", response_model=list[BlogRespuesta])
def listar_blog(
    q: str | None = None,
    tipo: str | None = None,
    genero: str | None = None,
    anio: int | None = None,
    mias: bool = False,
    guardados: bool = False,
    orden: str = "recientes",
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    usuario: Usuario | None = Depends(usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    if (mias or guardados) and usuario is None:
        raise HTTPException(status_code=401, detail="Inicia sesión para continuar")

    consulta, val = _consulta_blog()

    if q and q.strip():
        patron = f"%{q.strip().lower()}%"
        consulta = consulta.where(
            or_(
                func.lower(Blog.titulo).like(patron),
                func.lower(func.coalesce(Blog.tags, "")).like(patron),
                func.lower(func.coalesce(Blog.genero, "")).like(patron),
                func.lower(func.coalesce(Blog.descripcion, "")).like(patron),
            )
        )
    if tipo:
        consulta = consulta.where(Blog.tipo == tipo.strip().lower())
    if genero:
        consulta = consulta.where(func.lower(Blog.genero) == genero.strip().lower())
    if anio:
        consulta = consulta.where(Blog.anio == anio)
    if mias:
        consulta = consulta.where(Blog.usr_id == usuario.id_usr)
    if guardados:
        consulta = consulta.where(
            Blog.id_blog.in_(select(Guardado.blog_id).where(Guardado.usr_id == usuario.id_usr))
        )

    if orden == "mejor":
        consulta = consulta.order_by(
            func.coalesce(val.c.prom, 0).desc(),
            func.coalesce(val.c.total, 0).desc(),
            Blog.id_blog.desc(),
        )
    else:
        consulta = consulta.order_by(Blog.fecha.desc(), Blog.id_blog.desc())

    return _lista(db, consulta.limit(limit).offset(offset), usuario)


@app.get("/blog/generos", response_model=list[str])
def listar_generos(db: Session = Depends(obtener_sesion)):
    filas = db.scalars(
        select(Blog.genero).where(Blog.genero.is_not(None)).distinct().order_by(Blog.genero)
    ).all()
    return [g for g in filas if g and g.strip()]


@app.get("/blog/{blog_id}", response_model=BlogRespuesta)
def obtener_blog(
    blog_id: int,
    usuario: Usuario | None = Depends(usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    consulta, _ = _consulta_blog()
    fila = db.execute(consulta.where(Blog.id_blog == blog_id)).first()
    if fila is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    mi_valoracion = None
    if usuario is not None:
        mi_valoracion = db.scalar(
            select(Valoracion.puntos).where(
                Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario.id_usr
            )
        )
    return _blog_dict(fila, _ids_guardados(db, usuario), mi_valoracion)


# ---------- Pósters subidos desde la computadora ----------

MAX_BYTES_IMAGEN = 3 * 1024 * 1024


def _extension_imagen(datos: bytes) -> str | None:
    """Detecta el tipo real por los primeros bytes (no confía en el nombre)."""
    if datos.startswith(b"\xff\xd8\xff"):
        return ".jpg"
    if datos.startswith(b"\x89PNG\r\n\x1a\n"):
        return ".png"
    if datos[:4] == b"RIFF" and datos[8:12] == b"WEBP":
        return ".webp"
    return None


def _borrar_imagen_local(url: str | None) -> None:
    """Borra el archivo si la URL apunta a un póster subido por esta API."""
    if not url or "/uploads/" not in url:
        return
    nombre = Path(url.split("/uploads/", 1)[1]).name  # solo el nombre, sin rutas
    ruta = CARPETA_UPLOADS / nombre
    try:
        if ruta.is_file() and ruta.parent == CARPETA_UPLOADS:
            ruta.unlink()
    except OSError:
        pass


def _hay_multipart() -> bool:
    for modulo in ("python_multipart", "multipart"):
        try:
            __import__(modulo)
            return True
        except ImportError:
            continue
    return False


if _hay_multipart():

    @app.post("/blog/imagen")
    async def subir_imagen(
        request: Request,
        archivo: UploadFile = File(...),
        usuario: Usuario = Depends(usuario_actual),
    ):
        contenido = await archivo.read(MAX_BYTES_IMAGEN + 1)
        if len(contenido) > MAX_BYTES_IMAGEN:
            raise HTTPException(status_code=413, detail="La imagen no debe pesar más de 3 MB")
        extension = _extension_imagen(contenido)
        if extension is None:
            raise HTTPException(
                status_code=400, detail="Formato no válido. Usa una imagen JPG, PNG o WEBP"
            )
        nombre = f"{secrets.token_hex(12)}{extension}"
        (CARPETA_UPLOADS / nombre).write_bytes(contenido)
        return {"url": f"{str(request.base_url).rstrip('/')}/uploads/{nombre}"}

else:
    print(
        "AVISO: falta python-multipart; la subida de pósters está desactivada. "
        "Ejecuta: pip install -r requirements.txt"
    )


@app.post("/blog", response_model=BlogRespuesta, status_code=201)
def crear_blog(
    datos: BlogCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    nuevo = Blog(
        titulo=datos.titulo.strip(),
        descripcion=datos.descripcion.strip(),
        img=datos.img,
        tags=datos.tags.strip() if datos.tags and datos.tags.strip() else None,
        tipo=datos.tipo,
        genero=datos.genero.strip(),
        anio=datos.anio,
        usr_id=usuario.id_usr,
        fecha=datetime.now(),
        # Solo el administrador puede marcar una publicación como destacada.
        destacado=1 if datos.destacado and usuario.tip_usu == ADMIN else 0,
    )
    db.add(nuevo)
    db.commit()
    return obtener_blog(nuevo.id_blog, usuario, db)


def _blog_con_permiso(db: Session, blog_id: int, usuario: Usuario) -> Blog:
    blog = db.get(Blog, blog_id)
    if blog is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    if blog.usr_id != usuario.id_usr and usuario.tip_usu != ADMIN:
        raise HTTPException(
            status_code=403, detail="Solo puedes modificar tus propias publicaciones"
        )
    return blog


@app.put("/blog/{blog_id}", response_model=BlogRespuesta)
def actualizar_blog(
    blog_id: int,
    datos: BlogActualizar,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    blog = _blog_con_permiso(db, blog_id, usuario)
    imagen_anterior = blog.img
    blog.titulo = datos.titulo.strip()
    blog.descripcion = datos.descripcion.strip()
    blog.img = datos.img
    blog.tags = datos.tags.strip() if datos.tags and datos.tags.strip() else None
    blog.tipo = datos.tipo
    blog.genero = datos.genero.strip()
    blog.anio = datos.anio
    if usuario.tip_usu == ADMIN:
        blog.destacado = 1 if datos.destacado else 0
    db.commit()
    if imagen_anterior and imagen_anterior != blog.img:
        _borrar_imagen_local(imagen_anterior)
    return obtener_blog(blog_id, usuario, db)


@app.delete("/blog/{blog_id}", status_code=204)
def eliminar_blog(
    blog_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    blog = _blog_con_permiso(db, blog_id, usuario)

    ids_comentarios = select(Comentario.id_com).where(Comentario.blog_id == blog_id)
    db.execute(delete(Reaccion).where(Reaccion.com_id.in_(ids_comentarios)))
    db.execute(delete(Comentario).where(Comentario.blog_id == blog_id))
    db.execute(delete(Valoracion).where(Valoracion.blog_id == blog_id))
    db.execute(delete(Guardado).where(Guardado.blog_id == blog_id))
    db.execute(delete(Notificacion).where(Notificacion.blog_id == blog_id))
    imagen = blog.img
    db.delete(blog)
    db.commit()
    _borrar_imagen_local(imagen)
    return Response(status_code=204)


# ---------- Valoraciones y guardados ----------

def _resumen_valoracion(db: Session, blog_id: int, usuario_id: int) -> dict:
    prom, total = db.execute(
        select(func.avg(Valoracion.puntos), func.count(Valoracion.id)).where(
            Valoracion.blog_id == blog_id
        )
    ).one()
    mia = db.scalar(
        select(Valoracion.puntos).where(
            Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario_id
        )
    )
    return {
        "promedio": round(float(prom), 1) if prom is not None else None,
        "total_valoraciones": int(total or 0),
        "mi_valoracion": mia,
    }


@app.put("/blog/{blog_id}/valoracion", response_model=ValoracionRespuesta)
def valorar(
    blog_id: int,
    datos: ValoracionCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    blog = db.get(Blog, blog_id)
    if blog is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    if blog.usr_id == usuario.id_usr:
        raise HTTPException(
            status_code=403, detail="No puedes valorar tu propia publicación"
        )

    existente = db.scalar(
        select(Valoracion).where(
            Valoracion.blog_id == blog_id, Valoracion.usr_id == usuario.id_usr
        )
    )
    if existente is None:
        db.add(Valoracion(blog_id=blog_id, usr_id=usuario.id_usr, puntos=datos.puntos))
    else:
        existente.puntos = datos.puntos
        existente.fecha = datetime.now()

    _notificar(
        db,
        blog.usr_id,
        usuario,
        "valoracion",
        blog_id,
        blog_id,
        f'{usuario.nom_usr} valoró "{blog.titulo}" con {datos.puntos} de 5 estrellas',
    )
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="No se pudo registrar la valoración")
    return _resumen_valoracion(db, blog_id, usuario.id_usr)


@app.post("/blog/{blog_id}/guardar", status_code=204)
def guardar(
    blog_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    if db.get(Blog, blog_id) is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    ya = db.scalar(
        select(Guardado.id).where(
            Guardado.blog_id == blog_id, Guardado.usr_id == usuario.id_usr
        )
    )
    if ya is None:
        db.add(Guardado(blog_id=blog_id, usr_id=usuario.id_usr))
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
    return Response(status_code=204)


@app.delete("/blog/{blog_id}/guardar", status_code=204)
def quitar_guardado(
    blog_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    db.execute(
        delete(Guardado).where(
            Guardado.blog_id == blog_id, Guardado.usr_id == usuario.id_usr
        )
    )
    db.commit()
    return Response(status_code=204)


# =====================================================================
# Comentarios y reacciones
# =====================================================================

def _comentarios_dict(
    db: Session, filas, usuario: Usuario | None
) -> list[dict]:
    """Arma los comentarios con autor, conteo de reacciones y mi reacción."""
    ids = [c.id_com for c, _, _ in filas]
    conteos: dict[int, dict[str, int]] = {}
    mias: dict[int, str] = {}

    if ids:
        for com_id, tipo, total in db.execute(
            select(Reaccion.com_id, Reaccion.tipo, func.count(Reaccion.id))
            .where(Reaccion.com_id.in_(ids))
            .group_by(Reaccion.com_id, Reaccion.tipo)
        ).all():
            conteos.setdefault(com_id, {})[tipo] = int(total)
        if usuario is not None:
            for com_id, tipo in db.execute(
                select(Reaccion.com_id, Reaccion.tipo).where(
                    Reaccion.com_id.in_(ids), Reaccion.usr_id == usuario.id_usr
                )
            ).all():
                mias[com_id] = tipo

    return [
        {
            "id_com": c.id_com,
            "comentario": c.comentario,
            "fecha": c.fecha,
            "estatus": c.estatus,
            "usr_id": c.usr_id,
            "blog_id": c.blog_id,
            "autor": autor,
            "blog_titulo": titulo,
            "reacciones": conteos.get(c.id_com, {}),
            "mi_reaccion": mias.get(c.id_com),
        }
        for c, autor, titulo in filas
    ]


def _consulta_comentarios():
    return (
        select(Comentario, Usuario.nom_usr, Blog.titulo)
        .join(Usuario, Usuario.id_usr == Comentario.usr_id)
        .join(Blog, Blog.id_blog == Comentario.blog_id)
        .where(Comentario.estatus == 1)
    )


@app.get("/comentarios/recientes", response_model=list[ComentarioRespuesta])
def comentarios_recientes(
    limit: int = Query(5, ge=1, le=20),
    db: Session = Depends(obtener_sesion),
):
    filas = db.execute(
        _consulta_comentarios().order_by(Comentario.fecha.desc(), Comentario.id_com.desc()).limit(limit)
    ).all()
    return _comentarios_dict(db, filas, None)


@app.get("/comentarios", response_model=list[ComentarioRespuesta])
def listar_comentarios(
    blog_id: int | None = None,
    usuario: Usuario | None = Depends(usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    consulta = _consulta_comentarios()
    if blog_id is not None:
        consulta = consulta.where(Comentario.blog_id == blog_id)
    filas = db.execute(consulta.order_by(Comentario.fecha.asc(), Comentario.id_com.asc())).all()
    return _comentarios_dict(db, filas, usuario)


@app.post("/comentarios", response_model=ComentarioRespuesta, status_code=201)
def crear_comentario(
    datos: ComentarioCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    blog = db.get(Blog, datos.blog_id)
    if blog is None:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")

    nuevo = Comentario(
        comentario=datos.comentario,
        usr_id=usuario.id_usr,  # el autor sale de la sesión, no del cliente
        blog_id=datos.blog_id,
        estatus=1,
        fecha=datetime.now(),
    )
    db.add(nuevo)
    db.flush()  # para conocer el id del comentario
    _notificar(
        db,
        blog.usr_id,
        usuario,
        "comentario",
        blog.id_blog,
        nuevo.id_com,
        f'{usuario.nom_usr} comentó en "{blog.titulo}"',
    )
    db.commit()

    fila = db.execute(_consulta_comentarios().where(Comentario.id_com == nuevo.id_com)).all()
    return _comentarios_dict(db, fila, usuario)[0]


@app.delete("/comentarios/{comentario_id}", status_code=204)
def eliminar_comentario(
    comentario_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    comentario = db.get(Comentario, comentario_id)
    if comentario is None:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")
    if comentario.usr_id != usuario.id_usr and usuario.tip_usu != ADMIN:
        raise HTTPException(
            status_code=403, detail="Solo puedes eliminar tus propios comentarios"
        )
    db.execute(delete(Reaccion).where(Reaccion.com_id == comentario_id))
    db.execute(
        delete(Notificacion).where(
            Notificacion.tipo.in_(("comentario", "reaccion")),
            Notificacion.ref_id == comentario_id,
        )
    )
    db.delete(comentario)
    db.commit()
    return Response(status_code=204)


@app.put("/comentarios/{comentario_id}/reaccion", status_code=204)
def reaccionar(
    comentario_id: int,
    datos: ReaccionCrear,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    comentario = db.get(Comentario, comentario_id)
    if comentario is None:
        raise HTTPException(status_code=404, detail="Comentario no encontrado")

    existente = db.scalar(
        select(Reaccion).where(
            Reaccion.com_id == comentario_id, Reaccion.usr_id == usuario.id_usr
        )
    )
    if existente is None:
        db.add(Reaccion(com_id=comentario_id, usr_id=usuario.id_usr, tipo=datos.tipo))
    else:
        existente.tipo = datos.tipo  # una sola reacción por usuario: se cambia

    emoji = {"like": "👍", "love": "❤️", "fire": "🔥", "wow": "😮", "sad": "😢"}[datos.tipo]
    blog = db.get(Blog, comentario.blog_id)
    _notificar(
        db,
        comentario.usr_id,
        usuario,
        "reaccion",
        comentario.blog_id,
        comentario_id,
        f'{usuario.nom_usr} reaccionó {emoji} a tu comentario en "{blog.titulo if blog else "una publicación"}"',
    )

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="No se pudo registrar la reacción")
    return Response(status_code=204)


@app.delete("/comentarios/{comentario_id}/reaccion", status_code=204)
def quitar_reaccion(
    comentario_id: int,
    usuario: Usuario = Depends(usuario_actual),
    db: Session = Depends(obtener_sesion),
):
    db.execute(
        delete(Reaccion).where(
            Reaccion.com_id == comentario_id, Reaccion.usr_id == usuario.id_usr
        )
    )
    db.commit()
    return Response(status_code=204)


# =====================================================================
# Pantalla de inicio
# =====================================================================

@app.get("/home", response_model=HomeRespuesta)
def inicio_blog(
    usuario: Usuario | None = Depends(usuario_opcional),
    db: Session = Depends(obtener_sesion),
):
    consulta, val = _consulta_blog()

    destacados = _lista(
        db,
        consulta.order_by(Blog.destacado.desc(), Blog.fecha.desc(), Blog.id_blog.desc()).limit(3),
        usuario,
    )

    tendencias = _lista(
        db,
        consulta.where(Blog.tipo.in_(("pelicula", "serie")))
        .order_by(
            func.coalesce(val.c.prom, 0).desc(),
            func.coalesce(val.c.total, 0).desc(),
            Blog.id_blog.desc(),
        )
        .limit(8),
        usuario,
    )

    estrenos = _lista(
        db,
        consulta.where(Blog.tipo.in_(("pelicula", "serie")))
        .order_by(Blog.anio.desc(), Blog.fecha.desc(), Blog.id_blog.desc())
        .limit(3),
        usuario,
    )

    filas = db.execute(
        _consulta_comentarios().order_by(Comentario.fecha.desc(), Comentario.id_com.desc()).limit(3)
    ).all()

    return {
        "destacados": destacados,
        "tendencias": tendencias,
        "estrenos": estrenos,
        "comentarios_recientes": _comentarios_dict(db, filas, None),
    }
