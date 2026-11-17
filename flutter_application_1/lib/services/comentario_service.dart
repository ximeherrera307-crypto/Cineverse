import '../core/api.dart';
import '../models/comentario_model.dart';

class ComentarioService {
  Future<List<ComentarioModel>> obtenerComentarios(int blogId) async {
    final datos = await Api.get('/comentarios', query: {'blog_id': '$blogId'})
        as List;
    return datos
        .map((e) => ComentarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ComentarioModel>> obtenerRecientes({int limit = 3}) async {
    final datos = await Api.get('/comentarios/recientes',
        query: {'limit': '$limit'}) as List;
    return datos
        .map((e) => ComentarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// El autor lo toma el servidor de la sesión, no se envía desde la app.
  Future<ComentarioModel> agregarComentario({
    required int blogId,
    required String comentario,
  }) async {
    final datos = await Api.post('/comentarios', body: {
      'comentario': comentario.trim(),
      'blog_id': blogId,
    });
    return ComentarioModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarComentario(int id) async {
    await Api.delete('/comentarios/$id');
  }

  Future<void> reaccionar(int comentarioId, String tipo) async {
    await Api.put('/comentarios/$comentarioId/reaccion', body: {'tipo': tipo});
  }

  Future<void> quitarReaccion(int comentarioId) async {
    await Api.delete('/comentarios/$comentarioId/reaccion');
  }
}
