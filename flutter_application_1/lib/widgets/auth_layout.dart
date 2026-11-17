import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

/// Fondo oscuro con resplandor rojo y tarjeta centrada para login/registro.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool mostrarAtras;

  const AuthLayout({super.key, required this.child, this.mostrarAtras = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.9, -1),
            radius: 1.4,
            colors: [Color(0xFF3A0C0C), Colores.fondo],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: Colores.superficie,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colores.borde),
                          ),
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (mostrarAtras)
                Positioned(
                  top: 4,
                  left: 4,
                  child: IconButton(
                    tooltip: 'Volver',
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.movie_filter_rounded, color: Colores.rojo, size: 38),
        const SizedBox(width: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'Cine'),
              TextSpan(text: 'verse', style: TextStyle(color: Colores.rojo)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mensaje de error en rojo para formularios.
class MensajeError extends StatelessWidget {
  final String? texto;

  const MensajeError(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    if (texto == null || texto!.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x22FF6B6B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66FF6B6B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colores.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texto!,
                style: const TextStyle(color: Colores.error, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}
