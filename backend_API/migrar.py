"""Actualiza la base de datos existente sin borrar datos.

- Crea las tablas nuevas (valoraciones, reacciones, guardados).
- Agrega a la tabla `blog` las columnas nuevas si todavía no existen.

Se ejecuta automáticamente al iniciar la API, y también se puede correr a
mano con:  python migrar.py
"""
from sqlalchemy import inspect, text

from database import Base, engine
import models  # noqa: F401  (registra los modelos en Base.metadata)


def _columnas_blog(es_sqlite: bool) -> dict[str, str]:
    fecha = "DATETIME NULL" if es_sqlite else "DATETIME NULL DEFAULT CURRENT_TIMESTAMP"
    return {
        "tipo": "VARCHAR(20) NOT NULL DEFAULT 'articulo'",
        "genero": "VARCHAR(60) NULL",
        "anio": "INT NULL",
        "usr_id": "INT NULL",
        "fecha": fecha,
        "destacado": "INT NOT NULL DEFAULT 0",
    }


def migrar() -> None:
    Base.metadata.create_all(engine)

    inspector = inspect(engine)
    existentes = {c["name"] for c in inspector.get_columns("blog")}
    es_sqlite = engine.dialect.name == "sqlite"

    with engine.begin() as conexion:
        for nombre, definicion in _columnas_blog(es_sqlite).items():
            if nombre not in existentes:
                conexion.execute(
                    text(f"ALTER TABLE blog ADD COLUMN {nombre} {definicion}")
                )


if __name__ == "__main__":
    migrar()
    print("Base de datos actualizada.")
