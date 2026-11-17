import '../core/api.dart';
import '../core/session.dart';
import '../models/user_model.dart';
import 'notificacion_service.dart';

class AuthService {
  String? validarLogin({required String usuario, required String password}) {
    if (usuario.trim().isEmpty || password.isEmpty) {
      return 'Completa el correo y la contraseña';
    }
    return null;
  }

  /// Reglas de R002: campos completos, correo válido, contraseña de 8+
  /// caracteres con letras y números, y confirmación igual.
  String? validarRegistro({
    required String nombre,
    required String correo,
    required String password,
    required String confirmarPassword,
  }) {
    if (nombre.trim().isEmpty ||
        correo.trim().isEmpty ||
        password.isEmpty ||
        confirmarPassword.isEmpty) {
      return 'Completa todos los campos obligatorios';
    }
    if (nombre.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo.trim())) {
      return 'Ingresa un correo válido';
    }
    return validarPassword(password) ??
        (password != confirmarPassword ? 'Las contraseñas no coinciden' : null);
  }

  String? validarPassword(String password) {
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return 'La contraseña debe incluir letras y números';
    }
    return null;
  }

  /// Inicia sesión y guarda token + usuario en [Session].
  Future<UserModel> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final datos = await Api.post('/login', body: {
      'mail': correo.trim().toLowerCase(),
      'password': password,
    }) as Map<String, dynamic>;

    final usuario = UserModel.fromJson(datos['usuario'] as Map<String, dynamic>);
    Session.iniciar(datos['access_token'] as String, usuario);
    return usuario;
  }

  Future<void> cerrarSesion() async {
    try {
      await Api.post('/logout');
    } catch (_) {
      // Aunque falle la red, la sesión local se cierra igual.
    }
    Session.limpiar();
    NotificacionService.detener();
  }

  /// Pide un código de 6 dígitos por correo. La respuesta es la misma
  /// exista o no el correo.
  Future<String> solicitarCodigo(String correo) async {
    final datos = await Api.post('/recuperar/solicitar',
        body: {'mail': correo.trim().toLowerCase()}) as Map<String, dynamic>;
    return datos['mensaje'] as String? ?? 'Revisa tu correo';
  }

  Future<String> restablecerPassword({
    required String correo,
    required String codigo,
    required String password,
  }) async {
    final datos = await Api.post('/recuperar/confirmar', body: {
      'mail': correo.trim().toLowerCase(),
      'codigo': codigo.trim(),
      'password': password,
    }) as Map<String, dynamic>;
    return datos['mensaje'] as String? ?? 'Contraseña actualizada';
  }
}
