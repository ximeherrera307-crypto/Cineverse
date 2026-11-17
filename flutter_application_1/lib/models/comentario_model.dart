class ComentarioModel {
  final int id;
  final String comentario;
  final DateTime? fecha;
  final int usuarioId;
  final int blogId;
  final String autor;
  final String blogTitulo;
  Map<String, int> reacciones;
  String? miReaccion;

  ComentarioModel({
    required this.id,
    required this.comentario,
    required this.fecha,
    required this.usuarioId,
    required this.blogId,
    required this.autor,
    required this.blogTitulo,
    required this.reacciones,
    this.miReaccion,
  });

  String get autorAlias => '@${autor.replaceAll(' ', '').toLowerCase()}';

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final crudas = (json['reacciones'] as Map?) ?? const {};
    return ComentarioModel(
      id: json['id_com'] as int,
      comentario: json['comentario'] as String,
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      usuarioId: json['usr_id'] as int,
      blogId: json['blog_id'] as int,
      autor: json['autor'] as String? ?? 'Usuario',
      blogTitulo: json['blog_titulo'] as String? ?? '',
      reacciones: crudas.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      ),
      miReaccion: json['mi_reaccion'] as String?,
    );
  }
}
