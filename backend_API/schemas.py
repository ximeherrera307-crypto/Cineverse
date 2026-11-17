import re
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

TIPOS_PUBLICACION = ("pelicula", "serie", "articulo")
REACCIONES = ("like", "love", "fire", "wow", "sad")

_PATRON_CORREO = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def _validar_password(valor: str) -> str:
    if not re.search(r"[A-Za-z]", valor) or not re.search(r"\d", valor):
        raise ValueError("La contraseña debe incluir letras y números")
    return valor


def _validar_correo(valor: str) -> str:
    valor = valor.strip()
    if not _PATRON_CORREO.match(valor):
        raise ValueError("Ingresa un correo válido")
    return valor


# ---------- Usuarios ----------

class UsuarioCrear(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str = Field(min_length=8, max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int = 2

    _v_mail = field_validator("mail")(_validar_correo)
    _v_pass = field_validator("password")(_validar_password)


class UsuarioActualizar(BaseModel):
    nom_usr: str = Field(min_length=2, max_length=100)
    mail: str = Field(min_length=5, max_length=150)
    password: str | None = Field(default=None, min_length=8, max_length=128)
    dir_usr: str | None = Field(default=None, max_length=200)
    tip_usu: int | None = None

    _v_mail = field_validator("mail")(_validar_correo)

    @field_validator("password")
    @classmethod
    def _v_pass(cls, valor):
        return _validar_password(valor) if valor else valor


class UsuarioRespuesta(BaseModel):
    id_usr: int
    nom_usr: str
    mail: str
    dir_usr: str | None = None
    tip_usu: int

    model_config = ConfigDict(from_attributes=True)


class LoginRequest(BaseModel):
    mail: str = Field(min_length=3, max_length=150)
    password: str = Field(min_length=1, max_length=128)


class LoginRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta


# ---------- Publicaciones ----------

class _BlogBase(BaseModel):
    titulo: str = Field(min_length=2, max_length=150)
    descripcion: str = Field(min_length=1, max_length=20000)
    tipo: str = "articulo"
    genero: str = Field(min_length=2, max_length=60)
    anio: int | None = Field(default=None, ge=1888, le=2100)
    img: str | None = Field(default=None, max_length=500)
    tags: str | None = Field(default=None, max_length=255)
    destacado: bool = False

    @field_validator("tipo")
    @classmethod
    def _v_tipo(cls, valor):
        valor = valor.strip().lower()
        if valor not in TIPOS_PUBLICACION:
            raise ValueError("El tipo debe ser pelicula, serie o articulo")
        return valor

    @field_validator("img")
    @classmethod
    def _v_img(cls, valor):
        if valor and valor.strip():
            valor = valor.strip()
            if not valor.lower().startswith(("http://", "https://")):
                raise ValueError("La imagen debe ser una URL http o https")
            return valor
        return None


class BlogCrear(_BlogBase):
    pass


class BlogActualizar(_BlogBase):
    pass


class BlogRespuesta(BaseModel):
    id_blog: int
    titulo: str
    descripcion: str | None = None
    img: str | None = None
    tags: str | None = None
    tipo: str = "articulo"
    genero: str | None = None
    anio: int | None = None
    fecha: datetime | None = None
    destacado: bool = False
    autor_id: int | None = None
    autor: str | None = None
    promedio: float | None = None
    total_valoraciones: int = 0
    guardado: bool = False
    mi_valoracion: int | None = None


# ---------- Valoraciones ----------

class ValoracionCrear(BaseModel):
    puntos: int = Field(ge=1, le=5)


class ValoracionRespuesta(BaseModel):
    promedio: float | None
    total_valoraciones: int
    mi_valoracion: int | None


# ---------- Comentarios ----------

class ComentarioCrear(BaseModel):
    comentario: str = Field(min_length=1, max_length=500)
    blog_id: int

    @field_validator("comentario")
    @classmethod
    def _v_texto(cls, valor):
        valor = valor.strip()
        if not valor:
            raise ValueError("El comentario no puede estar vacío")
        return valor


class ComentarioRespuesta(BaseModel):
    id_com: int
    comentario: str
    fecha: datetime
    estatus: int
    usr_id: int
    blog_id: int
    autor: str | None = None
    blog_titulo: str | None = None
    reacciones: dict[str, int] = {}
    mi_reaccion: str | None = None


class ReaccionCrear(BaseModel):
    tipo: str

    @field_validator("tipo")
    @classmethod
    def _v_tipo(cls, valor):
        if valor not in REACCIONES:
            raise ValueError("Reacción no disponible")
        return valor


# ---------- Inicio ----------

class HomeRespuesta(BaseModel):
    destacados: list[BlogRespuesta]
    tendencias: list[BlogRespuesta]
    estrenos: list[BlogRespuesta]
    comentarios_recientes: list[ComentarioRespuesta]


# ---------- Recuperar contraseña ----------

class RecuperarSolicitud(BaseModel):
    mail: str = Field(min_length=3, max_length=150)


class RecuperarConfirmacion(BaseModel):
    mail: str = Field(min_length=3, max_length=150)
    codigo: str = Field(min_length=6, max_length=6, pattern=r"^\d{6}$")
    password: str = Field(min_length=8, max_length=128)

    _v_pass = field_validator("password")(_validar_password)


# ---------- Notificaciones ----------

class NotificacionRespuesta(BaseModel):
    id: int
    tipo: str
    texto: str
    blog_id: int | None = None
    fecha: datetime
    leida: bool


class NotificacionesRespuesta(BaseModel):
    no_leidas: int
    items: list[NotificacionRespuesta]
