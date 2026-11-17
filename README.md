# Cineverse — blog de reseñas de cine (UTEQ)

Flutter (web) + FastAPI + MySQL, siguiendo el boceto oscuro/rojo.

## 1. Backend (`backend_API/`)
```
cd backend_API
pip install -r requirements.txt      # ahora incluye python-multipart (subir pósters)
copy .env.example .env      # edita DB_* y pon un SECRET_KEY largo y aleatorio
uvicorn main:app --reload
```
- Al iniciar, la API **migra sola** tu base existente (crea tablas `valoraciones`, `reacciones`, `guardados` y agrega columnas nuevas a `blog`) sin borrar datos.
- Opcional: `python seed.py` carga 9 publicaciones de ejemplo.
- Documentación interactiva: http://127.0.0.1:8000/docs
- Para crear el primer administrador, registra un usuario y cambia su `tip_usu` a 1 en MySQL (`UPDATE usuario SET tip_usu=1 WHERE mail='...'`).

## 2. App (`flutter_application_1/`)
```
cd flutter_application_1
flutter pub add image_picker        # una sola vez (subir pósters)
flutter pub get
flutter run -d chrome
```
La URL del API está en `lib/core/api.dart` (`baseUrl`).

## Funcionalidad
- Visitantes: ven inicio, listados, detalle y comentarios. Para valorar, comentar, guardar o publicar se requiere sesión.
- Usuarios: publican/editan/eliminan sus reseñas, valoran (1–5, una por publicación, no la propia), comentan (500 car.), reaccionan con emoji y guardan.
- Administrador: además edita/elimina cualquier publicación o comentario, marca destacados y gestiona usuarios.
- Seguridad: contraseñas con argon2, token firmado con expiración de 60 min, cierre de sesión que invalida el token, bloqueo temporal tras 5 intentos fallidos de login, permisos validados en el servidor.

## Recuperar contraseña por correo (Gmail)
1. En tu cuenta de Google activa la verificación en dos pasos y crea una **contraseña de aplicación** (Cuenta de Google → Seguridad → Contraseñas de aplicaciones).
2. En `backend_API/.env` agrega:
   ```
   SMTP_USER=tu_correo@gmail.com
   SMTP_PASSWORD=la_contraseña_de_aplicación_de_16_letras
   ```
3. Reinicia uvicorn. En la app: Login → "¿Olvidaste tu contraseña?" → recibes un código de 6 dígitos (vence en 15 min, máximo 5 intentos).
Sin `SMTP_*` el código se imprime en la terminal de uvicorn (modo pruebas).

## Pósters desde la computadora
En "Nueva reseña" pulsa **Subir** y elige una imagen JPG, PNG o WEBP (máx. 3 MB). Se guarda en `backend_API/uploads/` y se borra sola si eliminas la reseña o cambias el póster.

## Notificaciones
La campana avisa cuando comentan, reaccionan o valoran tus publicaciones (contador en rojo, se actualiza cada 45 s).
