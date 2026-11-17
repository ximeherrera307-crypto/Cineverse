import '../models/user_model.dart';

/// Sesión activa en memoria: token y datos del usuario.
class Session {
  static String? token;
  static UserModel? usuario;

  static bool get logueado => token != null && usuario != null;
  static bool get esAdmin => usuario?.tipoUsuario == 1;

  /// ¿El usuario actual puede editar/eliminar algo creado por [autorId]?
  static bool puedeGestionar(int? autorId) {
    if (!logueado) return false;
    return esAdmin || (autorId != null && autorId == usuario!.id);
  }

  static void iniciar(String nuevoToken, UserModel nuevoUsuario) {
    token = nuevoToken;
    usuario = nuevoUsuario;
  }

  static void limpiar() {
    token = null;
    usuario = null;
  }
}
