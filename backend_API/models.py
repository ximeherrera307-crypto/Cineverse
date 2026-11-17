from datetime import datetime

from sqlalchemy import (
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)

from database import Base


class Usuario(Base):
    __tablename__ = "usuario"

    id_usr = Column(Integer, primary_key=True, index=True)
    nom_usr = Column(String(100), nullable=False)
    mail = Column(String(150), unique=True, nullable=False)
    pass_hash = Column("pass", String(255), nullable=False)
    dir_usr = Column(String(200), nullable=True)
    # 1 = administrador, 2 = usuario general
    tip_usu = Column(Integer, nullable=False, default=2)


class Blog(Base):
    """Publicación del blog: reseña de película, serie o artículo."""

    __tablename__ = "blog"

    id_blog = Column(Integer, primary_key=True, index=True)
    titulo = Column(String(150), nullable=False)
    descripcion = Column("desc", Text, nullable=True)
    img = Column(String(500), nullable=True)
    tags = Column(String(255), nullable=True)

    # Columnas nuevas (se agregan solas a la tabla existente, ver migrar.py)
    tipo = Column(String(20), nullable=False, default="articulo")
    genero = Column(String(60), nullable=True)
    anio = Column(Integer, nullable=True)
    usr_id = Column(Integer, nullable=True)  # autor
    fecha = Column(DateTime, nullable=True, default=datetime.now)
    destacado = Column(Integer, nullable=False, default=0)


class Comentario(Base):
    __tablename__ = "comentarios"

    id_com = Column(Integer, primary_key=True, index=True)
    comentario = Column(Text, nullable=False)
    fecha = Column(
        DateTime,
        nullable=False,
        server_default=func.current_timestamp(),
    )
    estatus = Column(Integer, nullable=False, default=1)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False)


class Valoracion(Base):
    """Calificación de 1 a 5 estrellas. Una por usuario y publicación."""

    __tablename__ = "valoraciones"
    __table_args__ = (UniqueConstraint("blog_id", "usr_id", name="uq_valoracion"),)

    id = Column(Integer, primary_key=True)
    blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False, index=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    puntos = Column(Integer, nullable=False)
    fecha = Column(DateTime, nullable=False, default=datetime.now)


class Reaccion(Base):
    """Reacción (emoji) a un comentario. Una por usuario y comentario."""

    __tablename__ = "reacciones"
    __table_args__ = (UniqueConstraint("com_id", "usr_id", name="uq_reaccion"),)

    id = Column(Integer, primary_key=True)
    com_id = Column(Integer, ForeignKey("comentarios.id_com"), nullable=False, index=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)
    tipo = Column(String(20), nullable=False)


class Guardado(Base):
    """Publicaciones guardadas por un usuario."""

    __tablename__ = "guardados"
    __table_args__ = (UniqueConstraint("blog_id", "usr_id", name="uq_guardado"),)

    id = Column(Integer, primary_key=True)
    blog_id = Column(Integer, ForeignKey("blog.id_blog"), nullable=False, index=True)
    usr_id = Column(Integer, ForeignKey("usuario.id_usr"), nullable=False)


class Notificacion(Base):
    """Aviso para el autor: comentarios, reacciones y valoraciones recibidas."""

    __tablename__ = "notificaciones"

    id = Column(Integer, primary_key=True)
    usr_id = Column(Integer, nullable=False, index=True)  # quien la recibe
    actor_id = Column(Integer, nullable=True)  # quien la provocó
    tipo = Column(String(20), nullable=False)  # comentario | reaccion | valoracion
    blog_id = Column(Integer, nullable=True, index=True)
    ref_id = Column(Integer, nullable=True)  # comentario o publicación origen
    texto = Column(String(300), nullable=False)
    fecha = Column(DateTime, nullable=False, default=datetime.now)
    leida = Column(Integer, nullable=False, default=0)


class Recuperacion(Base):
    """Código de 6 dígitos (guardado con hash) para restablecer la contraseña."""

    __tablename__ = "recuperaciones"

    id = Column(Integer, primary_key=True)
    usr_id = Column(Integer, nullable=False, index=True)
    codigo_hash = Column(String(64), nullable=False)
    expira = Column(DateTime, nullable=False)
    intentos = Column(Integer, nullable=False, default=0)
