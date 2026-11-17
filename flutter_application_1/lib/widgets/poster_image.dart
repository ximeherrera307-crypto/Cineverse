import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Póster de una publicación. Si no tiene imagen (o falla al cargar),
/// muestra un diseño de relleno con el título.
class PosterImage extends StatelessWidget {
  final String url;
  final String titulo;
  final int semilla;
  final BoxFit fit;

  const PosterImage({
    super.key,
    required this.url,
    required this.titulo,
    required this.semilla,
    this.fit = BoxFit.cover,
  });

  static const List<List<Color>> _paletas = [
    [Color(0xFF7A1010), Color(0xFF1A0505)],
    [Color(0xFF3B1F5E), Color(0xFF0E0618)],
    [Color(0xFF0F3B52), Color(0xFF04141C)],
    [Color(0xFF5E3A0F), Color(0xFF1A0E03)],
    [Color(0xFF1F4D3A), Color(0xFF06170F)],
  ];

  @override
  Widget build(BuildContext context) {
    final relleno = _relleno();
    if (url.isEmpty) return relleno;

    return Image.network(
      url,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => relleno,
      loadingBuilder: (context, hijo, progreso) {
        if (progreso == null) return hijo;
        return relleno;
      },
    );
  }

  Widget _relleno() {
    final colores = _paletas[semilla.abs() % _paletas.length];
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colores,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_creation_outlined,
              color: Colors.white38, size: 28),
          const SizedBox(height: 8),
          Text(
            titulo.toUpperCase(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circular con la inicial del usuario.
class Avatar extends StatelessWidget {
  final String texto;
  final double radio;

  const Avatar({super.key, required this.texto, this.radio = 18});

  @override
  Widget build(BuildContext context) {
    final letra = texto.trim().isEmpty ? '?' : texto.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radio,
      backgroundColor: Colores.rojoOscuro,
      child: Text(
        letra,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radio * 0.9,
        ),
      ),
    );
  }
}
