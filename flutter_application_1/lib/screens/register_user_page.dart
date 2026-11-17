import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/constants.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';

/// Registro público (crea usuario general). Si quien entra es administrador
/// también puede elegir el rol del nuevo usuario.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  final _auth = AuthService();

  int _rol = tipoGeneral;
  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    final fallo = _auth.validarRegistro(
      nombre: _nombre.text,
      correo: _correo.text,
      password: _password.text,
      confirmarPassword: _confirmar.text,
    );
    if (fallo != null) {
      setState(() => _error = fallo);
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await UserService().agregarUsuario(UserModel(
        id: 0,
        nombre: _nombre.text.trim(),
        correo: _correo.text.trim().toLowerCase(),
        password: _password.text,
        direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
        tipoUsuario: Session.esAdmin ? _rol : tipoGeneral,
      ));
      if (!mounted) return;

      if (Session.esAdmin) {
        mostrarMensaje(context, 'Usuario registrado correctamente');
        Navigator.pop(context, true);
      } else {
        mostrarMensaje(context, 'Cuenta creada. Ya puedes iniciar sesión');
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = Session.esAdmin;

    return AuthLayout(
      mostrarAtras: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(admin ? 'Registrar usuario' : 'Crear cuenta',
              style: estiloTitulo(size: 26), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            admin
                ? 'Da de alta un usuario general o un administrador.'
                : 'Únete para publicar reseñas, comentar y valorar.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colores.textoSuave),
          ),
          const SizedBox(height: 20),
          MensajeError(_error),
          CustomTextField(
            controller: _nombre,
            label: 'Nombre de usuario *',
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _correo,
            label: 'Correo electrónico *',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _direccion,
            label: 'Dirección (opcional)',
            prefixIcon: Icons.home_outlined,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _password,
            label: 'Contraseña * (8+, letras y números)',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _ocultar,
            suffixIcon: IconButton(
              icon: Icon(_ocultar
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _ocultar = !_ocultar),
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _confirmar,
            label: 'Confirmar contraseña *',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _ocultar,
            onSubmitted: (_) => _registrar(),
          ),
          if (admin) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _rol,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.admin_panel_settings_outlined),
              ),
              dropdownColor: Colores.superficie2,
              items: const [
                DropdownMenuItem(value: tipoGeneral, child: Text('Usuario general')),
                DropdownMenuItem(value: tipoAdmin, child: Text('Administrador')),
              ],
              onChanged: (v) => setState(() => _rol = v ?? tipoGeneral),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargando ? null : _registrar,
            child: _cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(admin ? 'Registrar usuario' : 'Registrarse'),
          ),
        ],
      ),
    );
  }
}
