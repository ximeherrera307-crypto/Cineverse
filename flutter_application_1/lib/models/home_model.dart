import 'comentario_model.dart';
import 'post_model.dart';

class HomeModel {
  final List<PostModel> destacados;
  final List<PostModel> tendencias;
  final List<PostModel> estrenos;
  final List<ComentarioModel> comentarios;

  HomeModel({
    required this.destacados,
    required this.tendencias,
    required this.estrenos,
    required this.comentarios,
  });

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    List<PostModel> posts(String clave) => (json[clave] as List)
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return HomeModel(
      destacados: posts('destacados'),
      tendencias: posts('tendencias'),
      estrenos: posts('estrenos'),
      comentarios: (json['comentarios_recientes'] as List)
          .map((e) => ComentarioModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
