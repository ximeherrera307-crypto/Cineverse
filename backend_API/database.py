import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.engine import URL
from sqlalchemy.orm import DeclarativeBase, sessionmaker

load_dotenv()

# DATABASE_URL permite usar otra base (por ejemplo SQLite en pruebas).
# Si no existe, se arma la conexión MySQL con las variables de .env.
_database_url = os.getenv("DATABASE_URL")

if _database_url:
    url = _database_url
else:
    url = URL.create(
        drivername="mysql+pymysql",
        username=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        database=os.getenv("DB_NAME", "bd_aplicacion_movil"),
        query={"charset": "utf8mb4"},
    )

engine = create_engine(url, pool_pre_ping=True)

SessionLocal = sessionmaker(
    bind=engine,
    autocommit=False,
    autoflush=False,
)


class Base(DeclarativeBase):
    pass


def obtener_sesion():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
