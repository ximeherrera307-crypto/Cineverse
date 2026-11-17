import '../core/api.dart';
import '../models/home_model.dart';
import '../models/post_model.dart';

class ValoracionResumen {
  final double? promedio;
  final int total;
  final int? miValoracion;

  ValoracionResumen(this.promedio, this.total, this.miValoracion);
}

class PostService {
  Future<HomeModel> obtenerInicio() async {
    final datos = await Api.get('/home') as Map<String, dynamic>;
    return HomeModel.fromJson(datos);
  }

  /// [tipo]: pelicula | serie | articulo (null = todos).
  /// [orden]: recientes | mejor.
  Future<List<PostModel>> obtenerPosts({
    String? q,
    String? tipo,
    String? genero,
    bool mias = false,
    bool guardados = false,
    String orden = 'recientes',
    int limit = 20,
    int offset = 0,
  }) async {
    final datos = await Api.get('/blog', query: {
      'q': q?.trim(),
      'tipo': tipo,
      'genero': genero,
      if (mias) 'mias': 'true',
      if (guardados) 'guardados': 'true',
      'orden': orden,
      'limit': '$limit',
      'offset': '$offset',
    }) as List;
    return datos
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> obtenerGeneros() async {
    final datos = await Api.get('/blog/generos') as List;
    return datos.map((e) => e.toString()).toList();
  }

  Future<PostModel> obtenerPost(int id) async {
    final datos = await Api.get('/blog/$id') as Map<String, dynamic>;
    return PostModel.fromJson(datos);
  }

  Map<String, dynamic> _cuerpo({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String genero,
    int? anio,
    String? imagen,
    String? tags,
    bool destacado = false,
  }) {
    return {
      'titulo': titulo.trim(),
      'descripcion': descripcion.trim(),
      'tipo': tipo,
      'genero': genero.trim(),
      'anio': anio,
      'img': (imagen ?? '').trim().isEmpty ? null : imagen!.trim(),
      'tags': (tags ?? '').trim().isEmpty ? null : tags!.trim(),
      'destacado': destacado,
    };
  }

  Future<PostModel> agregarPost({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String genero,
    int? anio,
    String? imagen,
    String? tags,
    bool destacado = false,
  }) async {
    final datos = await Api.post(
      '/blog',
      body: _cuerpo(
        titulo: titulo,
        descripcion: descripcion,
        tipo: tipo,
        genero: genero,
        anio: anio,
        imagen: imagen,
        tags: tags,
        destacado: destacado,
      ),
    );
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<PostModel> actualizarPost(
    int id, {
    required String titulo,
    required String descripcion,
    required String tipo,
    required String genero,
    int? anio,
    String? imagen,
    String? tags,
    bool destacado = false,
  }) async {
    final datos = await Api.put(
      '/blog/$id',
      body: _cuerpo(
        titulo: titulo,
        descripcion: descripcion,
        tipo: tipo,
        genero: genero,
        anio: anio,
        imagen: imagen,
        tags: tags,
        destacado: destacado,
      ),
    );
    return PostModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarPost(int id) async {
    await Api.delete('/blog/$id');
  }

  Future<ValoracionResumen> valorar(int id, int puntos) async {
    final datos = await Api.put(
      '/blog/$id/valoracion',
      body: {'puntos': puntos},
    ) as Map<String, dynamic>;
    return ValoracionResumen(
      (datos['promedio'] as num?)?.toDouble(),
      (datos['total_valoraciones'] as num?)?.toInt() ?? 0,
      (datos['mi_valoracion'] as num?)?.toInt(),
    );
  }

  /// Sube un póster desde la computadora y devuelve su URL.
  Future<String> subirImagen(List<int> bytes, String nombre) async {
    final datos = await Api.subirArchivo(
      '/blog/imagen',
      campo: 'archivo',
      bytes: bytes,
      nombre: nombre,
    ) as Map<String, dynamic>;
    return datos['url'] as String;
  }

  Future<void> guardar(int id) async {
    await Api.post('/blog/$id/guardar');
  }

  Future<void> quitarGuardado(int id) async {
    await Api.delete('/blog/$id/guardar');
  }
}
