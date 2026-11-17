import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/poster_image.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nombre = TextEditingController();
  final _correo = TextEditingController();
  final _direccion = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = Session.usuario;
    if (u != null) {
      _nombre.text = u.nombre;
      _correo.text = u.correo;
      _direccion.text = u.direccion ?? '';
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _direccion.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final auth = AuthService();
    if (_nombre.text.trim().length < 2) {
      setState(() => _error = 'El nombre debe tener al menos 2 caracteres');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_correo.text.trim())) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    if (_password.text.isNotEmpty) {
      final f = auth.validarPassword(_password.text);
      if (f != null) {
        setState(() => _error = f);
        return;
      }
      if (_password.text != _confirmar.text) {
        setState(() => _error = 'Las contraseñas no coinciden');
        return;
      }
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final actual = Session.usuario!;
    try {
      final nuevo = await UserService().actualizarUsuario(
        UserModel(
          id: actual.id,
          nombre: _nombre.text.trim(),
          correo: _correo.text.trim().toLowerCase(),
          direccion: _direccion.text.trim().isEmpty ? null : _direccion.text.trim(),
          tipoUsuario: actual.tipoUsuario,
        ),
        nuevaPassword: _password.text,
      );
      Session.usuario = nuevo;
      _password.clear();
      _confirmar.clear();
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, 'Perfil actualizado');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guardando = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.usuario;
    return AppShell(
      ruta: '/perfil',
      child: u == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Inicia sesión para ver tu perfil.',
                      style: TextStyle(color: Colores.textoSuave)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (r) => false),
                    child: const Text('Iniciar sesión'),
                  ),
                ],
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: Avatar(texto: u.nombre, radio: 40)),
                      const SizedBox(height: 12),
                      Text(u.nombre,
                          textAlign: TextAlign.center,
                          style: estiloTitulo(size: 26)),
                      Text('${u.alias} · ${u.rol}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colores.textoSuave)),
                      const SizedBox(height: 24),
                      MensajeError(_error),
                      CustomTextField(
                          controller: _nombre,
                          label: 'Nombre de usuario',
                          prefixIcon: Icons.person_outline_rounded),
                      const SizedBox(height: 12),
                      CustomTextField(
                          controller: _correo,
                          label: 'Correo electrónico',
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      CustomTextField(
                          controller: _direccion,
                          label: 'Dirección',
                          prefixIcon: Icons.home_outlined),
                      const SizedBox(height: 22),
                      const Text('Cambiar contraseña (opcional)',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      CustomTextField(
                          controller: _password,
                          label: 'Nueva contraseña',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true),
                      const SizedBox(height: 12),
                      CustomTextField(
                          controller: _confirmar,
                          label: 'Confirmar nueva contraseña',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _guardando ? null : _guardar,
                        child: _guardando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4, color: Colors.white))
                            : const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
