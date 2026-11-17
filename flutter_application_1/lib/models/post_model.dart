import '../core/constants.dart';

class PostModel {
  final int id;
  final String titulo;
  final String descripcion;
  final String imagen;
  final String tags;
  final String tipo; // pelicula | serie | articulo
  final String genero;
  final int? anio;
  final DateTime? fecha;
  final bool destacado;
  final int? autorId;
  final String? autor;
  double? promedio;
  int totalValoraciones;
  bool guardado;
  int? miValoracion;

  PostModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.imagen,
    required this.tags,
    required this.tipo,
    required this.genero,
    this.anio,
    this.fecha,
    this.destacado = false,
    this.autorId,
    this.autor,
    this.promedio,
    this.totalValoraciones = 0,
    this.guardado = false,
    this.miValoracion,
  });

  String get etiquetaTipo => tiposPublicacion[tipo] ?? 'Artículo';

  /// "Oppenheimer (2023)" o solo el título si no hay año.
  String get tituloConAnio => anio == null ? titulo : '$titulo ($anio)';

  /// "Película · Biográfica"
  String get meta => genero.isEmpty ? etiquetaTipo : '$etiquetaTipo · $genero';

  String get autorAlias {
    final nombre = (autor ?? '').trim();
    if (nombre.isEmpty) return 'Cineverse';
    return '@${nombre.replaceAll(' ', '').toLowerCase()}';
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id_blog'] as int,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      imagen: json['img'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'articulo',
      genero: json['genero'] as String? ?? '',
      anio: (json['anio'] as num?)?.toInt(),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      destacado: json['destacado'] as bool? ?? false,
      autorId: (json['autor_id'] as num?)?.toInt(),
      autor: json['autor'] as String?,
      promedio: (json['promedio'] as num?)?.toDouble(),
      totalValoraciones: (json['total_valoraciones'] as num?)?.toInt() ?? 0,
      guardado: json['guardado'] as bool? ?? false,
      miValoracion: (json['mi_valoracion'] as num?)?.toInt(),
    );
  }
}
