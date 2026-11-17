import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/post_model.dart';
import 'poster_image.dart';
import 'star_rating.dart';

enum AccionReview { guardar, editar, eliminar }

/// Fila de reseña con póster, título, estrellas, extracto y autor.
class ReviewTile extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final ValueChanged<AccionReview> onAccion;

  const ReviewTile({
    super.key,
    required this.post,
    required this.onTap,
    required this.onAccion,
  });

  @override
  Widget build(BuildContext context) {
    final puedeGestionar = Session.puedeGestionar(post.autorId);

    final autor = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Avatar(texto: post.autor ?? 'C', radio: 12),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(post.autorAlias,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(fechaCorta(post.fecha),
                style: const TextStyle(
                    fontSize: 11, color: Colores.textoSuave)),
          ],
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colores.superficie,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(builder: (context, c) {
            final ancho = c.maxWidth > 560;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 96,
                    height: 128,
                    child: PosterImage(
                      url: post.imagen,
                      titulo: post.titulo,
                      semilla: post.id,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.tituloConAnio,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (ancho) ...[const SizedBox(width: 12), autor],
                          PopupMenuButton<AccionReview>(
                            tooltip: 'Más opciones',
                            icon: const Icon(Icons.more_horiz,
                                color: Colores.textoSuave),
                            color: Colores.superficie2,
                            onSelected: onAccion,
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: AccionReview.guardar,
                                child: Text(post.guardado
                                    ? 'Quitar de guardados'
                                    : 'Guardar'),
                              ),
                              if (puedeGestionar)
                                const PopupMenuItem(
                                  value: AccionReview.editar,
                                  child: Text('Editar'),
                                ),
                              if (puedeGestionar)
                                const PopupMenuItem(
                                  value: AccionReview.eliminar,
                                  child: Text('Eliminar'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      Text(post.meta,
                          style: const TextStyle(
                              fontSize: 13, color: Colores.textoSuave)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StarsDisplay(valor: post.promedio),
                          const SizedBox(width: 8),
                          Text(
                            post.promedio == null
                                ? 'Sin valoraciones'
                                : post.promedio!.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13.5, color: Color(0xFFD0D0D6)),
                      ),
                      if (!ancho) ...[const SizedBox(height: 10), autor],
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
