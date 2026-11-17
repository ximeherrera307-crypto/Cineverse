import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';

/// Recuperar contraseña en dos pasos: 1) pedir el código por correo,
/// 2) escribir el código y la contraseña nueva.
class RecoverPasswordPage extends StatefulWidget {
  const RecoverPasswordPage({super.key});

  @override
  State<RecoverPasswordPage> createState() => _RecoverPasswordPageState();
}

class _RecoverPasswordPageState extends State<RecoverPasswordPage> {
  final _correo = TextEditingController();
  final _codigo = TextEditingController();
  final _password = TextEditingController();
  final _confirmar = TextEditingController();
  final _auth = AuthService();

  bool _paso2 = false;
  bool _cargando = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _correo.dispose();
    _codigo.dispose();
    _password.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  Future<void> _pedirCodigo() async {
    final correo = _correo.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      setState(() => _error = 'Ingresa un correo válido');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final mensaje = await _auth.solicitarCodigo(correo);
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _paso2 = true;
        _info = mensaje;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _restablecer() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_codigo.text.trim())) {
      setState(() => _error = 'El código tiene 6 dígitos');
      return;
    }
    final fallo = _auth.validarPassword(_password.text);
    if (fallo != null) {
      setState(() => _error = fallo);
      return;
    }
    if (_password.text != _confirmar.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final mensaje = await _auth.restablecerPassword(
        correo: _correo.text,
        codigo: _codigo.text,
        password: _password.text,
      );
      if (!mounted) return;
      mostrarMensaje(context, mensaje);
      Navigator.pop(context);
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
    return AuthLayout(
      mostrarAtras: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset_rounded, size: 46, color: Colores.rojo),
          const SizedBox(height: 12),
          Text('Recuperar contraseña',
              style: estiloTitulo(size: 24), textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            _paso2
                ? 'Escribe el código que te enviamos y tu nueva contraseña.'
                : 'Te enviaremos un código de 6 dígitos al correo de tu cuenta.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colores.textoSuave, height: 1.4),
          ),
          const SizedBox(height: 20),
          MensajeError(_error),
          if (_paso2 && _info != null && _error == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(_info!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colores.ok, fontSize: 13)),
            ),
          CustomTextField(
            controller: _correo,
            label: 'Correo electrónico',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _paso2 ? null : _pedirCodigo(),
          ),
          if (_paso2) ...[
            const SizedBox(height: 12),
            CustomTextField(
              controller: _codigo,
              label: 'Código de 6 dígitos',
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            CustomTextField(
              controller: _password,
              label: 'Nueva contraseña (8+, letras y números)',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: _confirmar,
              label: 'Confirmar nueva contraseña',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
              onSubmitted: (_) => _restablecer(),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargando ? null : (_paso2 ? _restablecer : _pedirCodigo),
            child: _cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white))
                : Text(_paso2 ? 'Cambiar contraseña' : 'Enviar código'),
          ),
          if (_paso2)
            TextButton(
              onPressed: _cargando ? null : _pedirCodigo,
              child: const Text('Reenviar código'),
            ),
        ],
      ),
    );
  }
}
