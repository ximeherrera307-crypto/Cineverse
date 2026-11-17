import 'package:flutter/material.dart';

import '../models/post_model.dart';
import '../screens/post_detail_page.dart';
import '../screens/post_form_page.dart';
import 'acciones.dart';
import 'session.dart';

/// Abre el detalle de una publicación. Devuelve true si algo cambió
/// (se eliminó, se editó, se guardó...) para que la pantalla recargue.
Future<bool> abrirDetalle(BuildContext context, PostModel post) async {
  final cambio = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => PostDetailPage(postId: post.id)),
  );
  return cambio ?? false;
}

/// Abre el formulario para crear (post == null) o editar una publicación.
Future<bool> abrirFormulario(BuildContext context, {PostModel? post}) async {
  if (!Session.logueado) {
    mostrarMensaje(context, 'Inicia sesión para publicar reseñas');
    return false;
  }
  final cambio = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => PostFormPage(post: post)),
  );
  return cambio ?? false;
}

/// Abre el detalle de una publicación a partir de su id (por ejemplo, desde
/// una notificación).
Future<bool> abrirDetalleId(BuildContext context, int id) async {
  final cambio = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => PostDetailPage(postId: id)),
  );
  return cambio ?? false;
}
