"""Carga publicaciones de ejemplo para ver la página con contenido.

Uso (desde backend_API):   python seed.py
No borra nada; solo agrega las publicaciones que aún no existan (por título).
Los pósters se dejan vacíos: la app muestra un diseño de relleno. Puedes pegar
la URL de un póster al editar cada publicación.
"""
from datetime import datetime, timedelta

from sqlalchemy import select

from database import SessionLocal
from migrar import migrar
from models import Blog

EJEMPLOS = [
    ("Dune: Parte Dos", "pelicula", "Ciencia ficción", 2024,
     "Villeneuve cierra la historia de Paul Atreides con un espectáculo visual enorme. "
     "Mantiene la tensión política del libro y entrega secuencias de batalla memorables.", "épica, desierto", 1),
    ("The Batman", "pelicula", "Crimen", 2022,
     "Una versión oscura y detectivesca del caballero de la noche, con una Gotham lluviosa "
     "y una atmósfera que recuerda al cine negro.", "dc, noir", 0),
    ("Interstellar", "pelicula", "Ciencia ficción", 2014,
     "Nolan combina física, emoción familiar y una banda sonora inolvidable en un viaje "
     "por el espacio y el tiempo.", "espacio, nolan", 0),
    ("Oppenheimer", "pelicula", "Biográfica", 2023,
     "Una obra brillante que combina historia, tensión y una dirección impecable. "
     "Nolan logra un relato profundo sobre el poder, la ciencia y sus consecuencias.", "historia, nolan", 1),
    ("La La Land", "pelicula", "Musical", 2016,
     "Un musical romántico lleno de color y nostalgia sobre perseguir los sueños "
     "y lo que cuesta alcanzarlos.", "romance, jazz", 0),
    ("Wicked", "pelicula", "Fantasía", 2024,
     "La historia de las brujas de Oz con números musicales espectaculares "
     "y dos actuaciones protagónicas muy sólidas.", "musical, fantasía", 0),
    ("Gladiator II", "pelicula", "Acción", 2024,
     "Una secuela con escenas de acción enormes que revisita el espíritu del Coliseo romano.", "épica, roma", 0),
    ("Breaking Bad", "serie", "Drama", 2008,
     "La transformación de un profesor de química en criminal es una de las mejores "
     "narraciones televisivas de la historia.", "crimen, clásico", 0),
    ("Cómo leer una película: guía para principiantes", "articulo", "Análisis", None,
     "Encuadre, montaje, sonido y color: cuatro elementos para empezar a ver cine "
     "con ojos de crítico y disfrutarlo todavía más.", "guía, análisis", 0),
]


def main():
    migrar()
    db = SessionLocal()
    try:
        agregadas = 0
        for i, (titulo, tipo, genero, anio, texto, tags, destacado) in enumerate(EJEMPLOS):
            if db.scalar(select(Blog.id_blog).where(Blog.titulo == titulo)):
                continue
            db.add(Blog(
                titulo=titulo, tipo=tipo, genero=genero, anio=anio,
                descripcion=texto, tags=tags, destacado=destacado,
                fecha=datetime.now() - timedelta(hours=i * 7),
            ))
            agregadas += 1
        db.commit()
        print(f"Publicaciones agregadas: {agregadas}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
