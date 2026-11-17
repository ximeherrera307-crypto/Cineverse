import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_shell.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget _fila(IconData icono, String titulo, String detalle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icono, color: Colores.rojo),
      title: Text(titulo),
      subtitle: Text(detalle, style: const TextStyle(color: Colores.textoSuave)),
      trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = Session.usuario;
    return AppShell(
      ruta: '/config',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Configuración', style: estiloTitulo(size: 28)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colores.superficie,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colores.borde),
            ),
            child: Column(
              children: [
                _fila(
                  Icons.person_outline_rounded,
                  'Cuenta',
                  u == null ? 'Navegando como visitante' : '${u.nombre} · ${u.rol}',
                  onTap: u == null
                      ? null
                      : () => Navigator.pushNamed(context, '/perfil'),
                ),
                const Divider(height: 1),
                _fila(Icons.timer_outlined, 'Sesión',
                    'Se cierra automáticamente a los 60 minutos de iniciarla.'),
                const Divider(height: 1),
                _fila(Icons.dns_outlined, 'Servidor', Api.baseUrl),
                if (Session.esAdmin) ...[
                  const Divider(height: 1),
                  _fila(Icons.people_alt_outlined, 'Gestión de usuarios',
                      'Ver, cambiar roles y eliminar usuarios.',
                      onTap: () => Navigator.pushNamed(context, '/usuarios')),
                  const Divider(height: 1),
                  _fila(Icons.person_add_alt_1_outlined, 'Registrar usuario',
                      'Crear un usuario general o administrador.',
                      onTap: () => Navigator.pushNamed(context, '/registrar')),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (u != null)
            OutlinedButton.icon(
              onPressed: () async {
                await AuthService().cerrarSesion();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (r) => false);
                }
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
        ],
      ),
    );
  }
}
