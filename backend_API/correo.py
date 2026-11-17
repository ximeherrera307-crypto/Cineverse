"""Envío de correos por SMTP (Gmail con contraseña de aplicación)."""
import os
import traceback
import smtplib
import ssl
from email.header import Header
from email.mime.text import MIMEText
from email.utils import formataddr

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.gmail.com")
SMTP_PORT = int(os.getenv("SMTP_PORT", "587"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "").replace(" ", "")
SMTP_FROM = os.getenv("SMTP_FROM") or SMTP_USER

CORREO_CONFIGURADO = bool(SMTP_USER and SMTP_PASSWORD)


def enviar_correo(destino: str, asunto: str, cuerpo: str) -> bool:
    """Devuelve True si se envió. Nunca lanza: un fallo se imprime en consola."""
    if not CORREO_CONFIGURADO:
        print(f"[correo] SMTP sin configurar; no se envió a {destino}.")
        return False
    try:
        # MIMEText con utf-8 explícito: acentos y ñ viajan bien codificados.
        msg = MIMEText(cuerpo, "plain", "utf-8")
        msg["Subject"] = Header(asunto, "utf-8")
        msg["From"] = formataddr((str(Header("Cineverse", "utf-8")), SMTP_FROM))
        msg["To"] = destino
        if SMTP_PORT == 465:  # SSL directo (útil si el puerto 587 está bloqueado)
            conexion = smtplib.SMTP_SSL(SMTP_HOST, SMTP_PORT, timeout=15,
                                        local_hostname="localhost",
                                        context=ssl.create_default_context())
        else:
            conexion = smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=15,
                                    local_hostname="localhost")
        with conexion as servidor:
            if SMTP_PORT != 465:
                servidor.starttls(context=ssl.create_default_context())
            servidor.login(SMTP_USER, SMTP_PASSWORD)
            servidor.sendmail(SMTP_FROM, [destino], msg.as_string())
        return True
    except Exception as error:  # noqa: BLE001
        print(f"[correo] No se pudo enviar a {destino}: {error}")
        traceback.print_exc()
        for nombre, valor in (("SMTP_USER", SMTP_USER), ("SMTP_PASSWORD", SMTP_PASSWORD),
                              ("SMTP_FROM", SMTP_FROM), ("SMTP_HOST", SMTP_HOST)):
            if not valor.isascii():
                print(f"[correo] OJO: {nombre} tiene caracteres no ASCII (ñ, acentos, espacios raros). Revisa el .env")
        return False