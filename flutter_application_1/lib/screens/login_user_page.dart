import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_layout.dart';
import '../widgets/custom_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _correo = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _ocultar = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final fallo = _auth.validarLogin(
      usuario: _correo.text,
      password: _password.text,
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
      await _auth.iniciarSesion(correo: _correo.text, password: _password.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Inicia sesión',
              style: estiloTitulo(size: 26), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          const Text(
            'Reseñas, análisis y más del mundo del cine.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colores.textoSuave),
          ),
          const SizedBox(height: 22),
          MensajeError(_error),
          CustomTextField(
            controller: _correo,
            label: 'Correo electrónico',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _password,
            label: 'Contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _ocultar,
            onSubmitted: (_) => _entrar(),
            suffixIcon: IconButton(
              tooltip: _ocultar ? 'Mostrar contraseña' : 'Ocultar contraseña',
              icon: Icon(_ocultar
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _ocultar = !_ocultar),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/recuperar'),
              child: const Text('¿Olvidaste tu contraseña?'),
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton(
            onPressed: _cargando ? null : _entrar,
            child: _cargando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : const Text('Entrar'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/registrar'),
            child: const Text('Crear cuenta'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/home', (r) => false),
            child: const Text('Continuar como visitante'),
          ),
        ],
      ),
    );
  }
}
