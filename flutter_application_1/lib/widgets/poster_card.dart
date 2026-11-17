import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/post_model.dart';
import 'poster_image.dart';
import 'star_rating.dart';

/// Tarjeta vertical de póster con promedio y botón de guardar.
class PosterCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onTap;
  final VoidCallback onGuardar;
  final double ancho;
  final double alto;

  const PosterCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.onGuardar,
    this.ancho = 170,
    this.alto = 250,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colores.superficie,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PosterImage(
                  url: post.imagen,
                  titulo: post.titulo,
                  semilla: post.id,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xCC000000)],
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Tooltip(
                    message: post.guardado ? 'Quitar de guardados' : 'Guardar',
                    child: InkWell(
                      onTap: onGuardar,
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          post.guardado
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 19,
                          color: post.guardado ? Colores.rojo : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    children: [
                      PromedioChip(promedio: post.promedio),
                      const Spacer(),
                      Flexible(
                        child: Text(
                          post.anio?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
