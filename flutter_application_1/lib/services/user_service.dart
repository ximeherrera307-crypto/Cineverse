import '../core/api.dart';
import '../models/user_model.dart';

class UserService {
  Future<List<UserModel>> obtenerUsuarios() async {
    final datos = await Api.get('/usuarios') as List;
    return datos
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Registro público (crea usuario general) o, con sesión de administrador,
  /// también permite crear administradores.
  Future<UserModel> agregarUsuario(UserModel usuario) async {
    final datos = await Api.post('/usuarios', body: usuario.toJsonCrear());
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<UserModel> actualizarUsuario(
    UserModel usuario, {
    String? nuevaPassword,
  }) async {
    final datos = await Api.put('/usuarios/${usuario.id}', body: {
      'nom_usr': usuario.nombre,
      'mail': usuario.correo,
      'dir_usr': usuario.direccion,
      'tip_usu': usuario.tipoUsuario,
      if (nuevaPassword != null && nuevaPassword.isNotEmpty)
        'password': nuevaPassword,
    });
    return UserModel.fromJson(datos as Map<String, dynamic>);
  }

  Future<void> eliminarUsuario(int id) async {
    await Api.delete('/usuarios/$id');
  }
}
