class NotificacionModel {
  final int id;
  final String tipo; // comentario | reaccion | valoracion
  final String texto;
  final int? blogId;
  final DateTime? fecha;
  final bool leida;

  NotificacionModel({
    required this.id,
    required this.tipo,
    required this.texto,
    required this.blogId,
    required this.fecha,
    required this.leida,
  });

  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      id: json['id'] as int,
      tipo: json['tipo'] as String? ?? 'comentario',
      texto: json['texto'] as String? ?? '',
      blogId: (json['blog_id'] as num?)?.toInt(),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      leida: json['leida'] as bool? ?? false,
    );
  }
}
