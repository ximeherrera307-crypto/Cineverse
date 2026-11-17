import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Estrellas de solo lectura (admite medias estrellas).
class StarsDisplay extends StatelessWidget {
  final double? valor;
  final double size;

  const StarsDisplay({super.key, required this.valor, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final v = valor ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icono;
        if (v >= i + 0.75) {
          icono = Icons.star_rounded;
        } else if (v >= i + 0.25) {
          icono = Icons.star_half_rounded;
        } else {
          icono = Icons.star_outline_rounded;
        }
        return Icon(icono, size: size, color: Colores.estrella);
      }),
    );
  }
}

/// Estrellas para calificar de 1 a 5.
class StarsInput extends StatelessWidget {
  final int valor;
  final ValueChanged<int> onChanged;
  final double size;

  const StarsInput({
    super.key,
    required this.valor,
    required this.onChanged,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final activa = i < valor;
        return IconButton(
          tooltip: '${i + 1} ${i == 0 ? 'estrella' : 'estrellas'}',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: size + 6, minHeight: size + 6),
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            activa ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: activa ? Colores.estrella : Colores.textoSuave,
          ),
        );
      }),
    );
  }
}

/// "★ 4.7" compacto para tarjetas.
class PromedioChip extends StatelessWidget {
  final double? promedio;
  final double size;

  const PromedioChip({super.key, required this.promedio, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: Colores.estrella, size: size + 2),
        const SizedBox(width: 3),
        Text(
          promedio == null ? 'Nuevo' : promedio!.toStringAsFixed(1),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
