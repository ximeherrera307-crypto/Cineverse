# Cambios para los apartados funcionales

Se integraron estos cambios sobre la estructura existente:

- Agregar blog: se conserva el formulario y el POST `/blog` que registra la publicación.
- Registrar usuario: ahora envía los datos a POST `/usuarios`, permite elegir Administrador (1) o Usuario general (2), y valida contraseña y confirmación.
- Mi perfil: ahora el backend incluye PUT `/usuarios/{usuario_id}` para guardar los cambios del perfil.
- Gestión de usuarios: se añadió PUT para actualizar y DELETE para eliminar; el borrado devuelve un error claro si existen comentarios relacionados.

## Configuración

El archivo `.env` original no se incluye en este ZIP por seguridad. Conserva tu `.env` local o crea uno a partir de `backend_API/.env.example` con las credenciales de tu MySQL.

## Ejecutar

Backend (desde `backend_API`):
    uvicorn main:app --reload

Flutter (desde `flutter_application_1`):
    flutter pub get
    flutter run -d chrome

La URL `http://127.0.0.1:8000` funciona para Flutter Web en la misma computadora. Para Android físico/emulador se debe ajustar `baseUrl` según el dispositivo.

Los archivos Python pasaron revisión de sintaxis. No fue posible ejecutar `flutter analyze` en este entorno porque no está instalado Flutter/Dart.
