import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta de Cineverse (negro cinematográfico con rojo).
class Colores {
  static const Color fondo = Color(0xFF0A0A0C);
  static const Color superficie = Color(0xFF131316);
  static const Color superficie2 = Color(0xFF1B1B20);
  static const Color borde = Color(0xFF2A2A30);
  static const Color rojo = Color(0xFFD62828);
  static const Color rojoOscuro = Color(0xFF7A1010);
  static const Color texto = Color(0xFFF3F3F5);
  static const Color textoSuave = Color(0xFFA0A0A8);
  static const Color estrella = Color(0xFFF5B301);
  static const Color error = Color(0xFFFF6B6B);
  static const Color ok = Color(0xFF4CC38A);
}

/// Estilo serif de los títulos, como en el boceto.
TextStyle estiloTitulo({double size = 22, Color color = Colores.texto}) {
  return GoogleFonts.playfairDisplay(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
  );
}

ThemeData construirTema() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colores.fondo,
    colorScheme: const ColorScheme.dark(
      primary: Colores.rojo,
      secondary: Colores.rojo,
      surface: Colores.superficie,
      error: Colores.error,
    ),
  );

  OutlineInputBorder borde(Color color, [double ancho = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: ancho),
      );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.inter().fontFamily,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colores.fondo,
      foregroundColor: Colores.texto,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    dividerColor: Colores.borde,
    cardColor: Colores.superficie,
    drawerTheme: const DrawerThemeData(backgroundColor: Colores.fondo),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colores.superficie2,
      labelStyle: const TextStyle(color: Colores.textoSuave),
      hintStyle: const TextStyle(color: Colores.textoSuave),
      prefixIconColor: Colores.textoSuave,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      enabledBorder: borde(Colores.borde),
      focusedBorder: borde(Colores.rojo, 1.6),
      errorBorder: borde(Colores.error),
      focusedErrorBorder: borde(Colores.error, 1.6),
      border: borde(Colores.borde),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colores.rojo,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colores.texto,
        side: const BorderSide(color: Colores.borde, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colores.rojo,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colores.superficie2,
      contentTextStyle: const TextStyle(color: Colores.texto),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colores.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
