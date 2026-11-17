# Cineverse — blog de reseñas de cine y series

Blog web **adaptable (responsive)** para publicar y comentar reseñas de películas, series y artículos. Se ve bien en **celular, tablet y computadora**.

- **Frontend:** Flutter (Material 3, tema oscuro con rojo)
- **API:** FastAPI + SQLAlchemy
- **Base de datos:** MySQL (XAMPP / MySQL 8)

**Autor:** _[equipo Cineverse] · UTEQ · _[LITIID013]_

---

## Funciones

| Rol | Qué puede hacer |
|---|---|
| Visitante | Ver inicio, listados, detalle de reseñas y comentarios |
| Usuario | Publicar, editar y eliminar sus reseñas · valorar de 1 a 5 (una vez por publicación, no la propia) · comentar (500 caracteres) · reaccionar con emoji · guardar favoritas |
| Administrador | Todo lo anterior, más editar o eliminar cualquier publicación o comentario, marcar destacados y gestionar usuarios |

Además:
- **Recuperar contraseña por correo real** (código de 6 dígitos, vence en 15 min, máximo 5 intentos).
- **Subir pósters desde el equipo** (JPG, PNG o WEBP, máximo 3 MB).
- **Notificaciones** con campana: avisan cuando comentan, reaccionan o valoran tus publicaciones.

## Seguridad
- Contraseñas guardadas con hash **argon2** (nunca en claro).
- Token de sesión firmado, con expiración de 60 min; al cerrar sesión se invalida.
- Bloqueo temporal tras 5 intentos fallidos de inicio de sesión.
- Permisos validados en el servidor, no solo en la app.
- Las imágenes subidas se validan por su contenido real, no solo por la extensión.
- Los secretos (`.env`) **no** se suben al repositorio.

## Estructura

```
Cineverse/
├── backend_API/            API en FastAPI
│   ├── main.py             endpoints
│   ├── models.py           tablas (SQLAlchemy)
│   ├── schemas.py          validación de datos
│   ├── security.py         contraseñas y tokens
│   ├── correo.py           envío de correos (SMTP)
│   ├── migrar.py           crea/actualiza tablas al iniciar
│   ├── seed.py             publicaciones de ejemplo (opcional)
│   ├── uploads/            pósters subidos
│   └── .env.example        plantilla de configuración
├── database/
│   └── cineverse.sql       script de la base de datos MySQL
└── flutter_application_1/  app Flutter
    └── lib/
        ├── core/           tema, rutas, API, sesión
        ├── models/         modelos de datos
        ├── services/       llamadas a la API
        ├── screens/        pantallas
        └── widgets/        componentes reutilizables
```

## Requisitos
- Python 3.10 o superior
- MySQL (por ejemplo XAMPP)
- Flutter SDK y Google Chrome

## Instalación paso a paso

### 1. Base de datos
1. Inicia **MySQL** (en XAMPP, botón *Start*).
2. Abre phpMyAdmin → pestaña **SQL** → pega el contenido de `database/cineverse.sql` y ejecútalo.
   (También puedes usar `mysql -u root -p < database/cineverse.sql`.)

Esto crea la base `cineverse` con sus 8 tablas.

### 2. API (backend)
```
cd backend_API
pip install -r requirements.txt
copy .env.example .env
```
Abre `.env` y revisa los datos de conexión (en XAMPP: usuario `root`, contraseña vacía). Cambia `SECRET_KEY` por una clave larga y aleatoria. Luego:
```
uvicorn main:app --reload
```
- Documentación interactiva: http://127.0.0.1:8000/docs
- Opcional: `python seed.py` carga publicaciones de ejemplo.

**Crear el primer administrador:** registra un usuario en la app y en MySQL ejecuta:
```
UPDATE usuario SET tip_usu = 1 WHERE mail = 'tu_correo@ejemplo.com';
```

### 3. App (Flutter)
```
cd flutter_application_1
flutter pub get
flutter run -d chrome
```
La dirección de la API está en `lib/core/api.dart`. Por defecto es `http://127.0.0.1:8000`.

## Probar el diseño adaptable
Con la app abierta en Chrome pulsa **F12** y luego **Ctrl+Shift+M** (modo dispositivo). Elige celular, tablet o escritorio:
- Menos de 900 px: el menú pasa a un cajón lateral con botón de hamburguesa.
- 900 px o más: barra lateral fija.

## Recuperar contraseña por correo (Gmail)
1. En tu cuenta de Google activa la **verificación en 2 pasos**.
2. Crea una **contraseña de aplicación** en https://myaccount.google.com/apppasswords
3. En `backend_API/.env` agrega (sin comillas ni símbolos `<>`):
   ```
   SMTP_USER=tu_correo@gmail.com
   SMTP_PASSWORD=las_16_letras_que_te_da_google
   ```
4. Reinicia uvicorn.

Si no configuras el correo, el código de recuperación se imprime en la terminal de uvicorn (modo pruebas).

