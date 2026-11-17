import 'package:flutter/material.dart';

import '../core/acciones.dart';
import '../core/constants.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../widgets/app_shell.dart';
import '../widgets/poster_image.dart';

/// Gestión de usuarios (solo administrador).
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _servicio = UserService();
  List<UserModel> _usuarios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (Session.esAdmin) {
      _cargar();
    } else {
      _cargando = false;
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final l = await _servicio.obtenerUsuarios();
      if (!mounted) return;
      setState(() {
        _usuarios = l;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _editar(UserModel u) async {
    final nombre = TextEditingController(text: u.nombre);
    final correo = TextEditingController(text: u.correo);
    final direccion = TextEditingController(text: u.direccion ?? '');
    final password = TextEditingController();
    int rol = u.tipoUsuario;
    final propio = u.id == Session.usuario?.id;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Editar usuario'),
          content: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nombre,
                      decoration: const InputDecoration(labelText: 'Nombre')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: correo,
                      decoration: const InputDecoration(labelText: 'Correo')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: direccion,
                      decoration: const InputDecoration(labelText: 'Dirección')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Nueva contraseña (opcional)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: rol,
                    decoration: InputDecoration(
                        labelText: 'Rol',
                        helperText:
                            propio ? 'No puedes cambiar tu propio rol' : null),
                    dropdownColor: Colores.superficie2,
                    items: const [
                      DropdownMenuItem(
                          value: tipoGeneral, child: Text('Usuario general')),
                      DropdownMenuItem(
                          value: tipoAdmin, child: Text('Administrador')),
                    ],
                    onChanged:
                        propio ? null : (v) => setD(() => rol = v ?? rol),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Guardar')),
          ],
        ),
      ),
    );

    final nuevaPass = password.text;
    final datos = UserModel(
      id: u.id,
      nombre: nombre.text.trim(),
      correo: correo.text.trim().toLowerCase(),
      direccion: direccion.text.trim().isEmpty ? null : direccion.text.trim(),
      tipoUsuario: rol,
    );
    nombre.dispose();
    correo.dispose();
    direccion.dispose();
    password.dispose();
    if (guardar != true) return;

    try {
      await _servicio.actualizarUsuario(datos, nuevaPassword: nuevaPass);
      if (!mounted) return;
      mostrarMensaje(context, 'Usuario actualizado');
      _cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  Future<void> _eliminar(UserModel u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Eliminar a ${u.nombre}? Se borrarán sus comentarios, '
            'valoraciones y guardados. Sus publicaciones se conservan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _servicio.eliminarUsuario(u.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Usuario eliminado');
      _cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      ruta: '/usuarios',
      child: !Session.esAdmin
          ? const Center(
              child: Text('Esta sección es solo para administradores.',
                  style: TextStyle(color: Colores.textoSuave)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('Gestión de usuarios',
                            style: estiloTitulo(size: 28))),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/registrar');
                        _cargar();
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_cargando)
                  const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator())),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colores.error)),
                ..._usuarios.map((u) => Card(
                      color: Colores.superficie,
                      surfaceTintColor: Colors.transparent,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Colores.borde),
                      ),
                      child: ListTile(
                        leading: Avatar(texto: u.nombre),
                        title: Text(u.nombre),
                        subtitle: Text('${u.correo} · ${u.rol}',
                            style: const TextStyle(color: Colores.textoSuave)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _editar(u)),
                            if (u.id != Session.usuario?.id)
                              IconButton(
                                  tooltip: 'Eliminar',
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  onPressed: () => _eliminar(u)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }
}
