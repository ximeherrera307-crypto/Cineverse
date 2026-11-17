"""Tokens de sesión firmados (HS256, formato JWT) usando solo la biblioteca estándar."""
import base64
import hashlib
import hmac
import json
import os
import secrets
import time

SECRET_KEY = os.getenv("SECRET_KEY") or secrets.token_urlsafe(48)
SECRET_DEFINIDA = bool(os.getenv("SECRET_KEY"))
MINUTOS_TOKEN = int(os.getenv("TOKEN_MINUTES", "60"))

# Tokens cerrados con "Cerrar sesión": jti -> momento en que expiran.
_revocados: dict[str, int] = {}


def _b64(datos: bytes) -> str:
    return base64.urlsafe_b64encode(datos).rstrip(b"=").decode()


def _desb64(texto: str) -> bytes:
    return base64.urlsafe_b64decode(texto + "=" * (-len(texto) % 4))


def _firma(mensaje: str) -> str:
    return _b64(hmac.new(SECRET_KEY.encode(), mensaje.encode(), hashlib.sha256).digest())


def crear_token(id_usuario: int, tipo: int) -> str:
    encabezado = _b64(json.dumps({"alg": "HS256", "typ": "JWT"}).encode())
    cuerpo = _b64(
        json.dumps(
            {
                "sub": str(id_usuario),
                "tip": tipo,
                "jti": secrets.token_hex(8),
                "exp": int(time.time()) + MINUTOS_TOKEN * 60,
            }
        ).encode()
    )
    mensaje = f"{encabezado}.{cuerpo}"
    return f"{mensaje}.{_firma(mensaje)}"


def leer_token(token: str) -> dict | None:
    """Devuelve el contenido del token, o None si es inválido, vencido o cerrado."""
    try:
        encabezado, cuerpo, firma = token.split(".")
        if not hmac.compare_digest(_firma(f"{encabezado}.{cuerpo}"), firma):
            return None
        datos = json.loads(_desb64(cuerpo))
    except Exception:
        return None

    ahora = int(time.time())
    if datos.get("exp", 0) < ahora:
        return None

    # Limpia revocaciones ya vencidas y revisa si este token fue cerrado.
    for jti in [j for j, exp in _revocados.items() if exp < ahora]:
        _revocados.pop(jti, None)
    if datos.get("jti") in _revocados:
        return None

    return datos


def revocar_token(datos: dict) -> None:
    jti = datos.get("jti")
    if jti:
        _revocados[jti] = int(datos.get("exp", 0))
