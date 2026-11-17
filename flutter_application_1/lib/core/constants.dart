/// Reacciones disponibles en los comentarios (clave del API -> emoji).
const Map<String, String> reaccionesDisponibles = {
  'like': '👍',
  'love': '❤️',
  'fire': '🔥',
  'wow': '😮',
  'sad': '😢',
};

/// Tipos de publicación (clave del API -> etiqueta).
const Map<String, String> tiposPublicacion = {
  'pelicula': 'Película',
  'serie': 'Serie',
  'articulo': 'Artículo',
};

const List<String> generosSugeridos = [
  'Acción',
  'Análisis',
  'Animación',
  'Aventura',
  'Biográfica',
  'Ciencia ficción',
  'Comedia',
  'Crimen',
  'Documental',
  'Drama',
  'Fantasía',
  'Musical',
  'Romance',
  'Suspenso',
  'Terror',
];

const int tipoAdmin = 1;
const int tipoGeneral = 2;
