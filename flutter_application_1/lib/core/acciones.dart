import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../services/post_service.dart';
import 'session.dart';

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

/// Guarda o quita de guardados. Actualiza al instante y revierte si falla.
Future<void> alternarGuardado(
  BuildContext context,
  PostModel post,
  VoidCallback alActualizar,
) async {
  if (!Session.logueado) {
    mostrarMensaje(context, 'Inicia sesión para guardar publicaciones');
    return;
  }

  final servicio = PostService();
  final eraGuardado = post.guardado;
  post.guardado = !eraGuardado;
  alActualizar();

  try {
    if (eraGuardado) {
      await servicio.quitarGuardado(post.id);
    } else {
      await servicio.guardar(post.id);
    }
  } catch (e) {
    post.guardado = eraGuardado;
    alActualizar();
    if (context.mounted) mostrarMensaje(context, e.toString());
  }
}

/// Pide confirmación y elimina la publicación. Devuelve true si se eliminó.
Future<bool> confirmarYEliminarPost(BuildContext context, PostModel post) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar publicación'),
      content: Text(
        '¿Seguro que quieres eliminar "${post.titulo}"? '
        'También se borrarán sus comentarios y valoraciones. '
        'Esta acción no se puede deshacer.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar'),
        ),
      ],
    ),
  );
  if (confirmar != true) return false;

  try {
    await PostService().eliminarPost(post.id);
    if (context.mounted) mostrarMensaje(context, 'Publicación eliminada');
    return true;
  } catch (e) {
    if (context.mounted) mostrarMensaje(context, e.toString());
    return false;
  }
}
