import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:vivamente/core/constants/app_colors.dart';

abstract final class AppTheme {
  /// Títulos: Nunito ExtraBold.
  static TextStyle titulo(double size, {Color color = AppColors.texto, double? height}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        height: height,
        letterSpacing: -size * 0.02,
      );

  /// Cuerpo: Source Sans 3.
  static TextStyle cuerpo(
    double size, {
    Color color = AppColors.textoSuave,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) =>
      GoogleFonts.sourceSans3(fontSize: size, color: color, fontWeight: weight, height: height);

  /// Etiquetas, cifras y códigos: IBM Plex Mono.
  static TextStyle mono(
    double size, {
    Color color = AppColors.textoTenue,
    double letterSpacing = 0,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color,
        letterSpacing: letterSpacing,
        fontWeight: weight,
      );

  static OutlineInputBorder _borde(Color color, double ancho) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: color, width: ancho),
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.papel,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.azul,
        primary: AppColors.azul,
        secondary: AppColors.naranja,
        error: AppColors.rojo,
        surface: AppColors.papel,
      ),
    );

    final texto = base.textTheme.apply(bodyColor: AppColors.texto, displayColor: AppColors.texto);

    return base.copyWith(
      textTheme: texto.copyWith(
        // Títulos -> Nunito
        displayLarge: GoogleFonts.nunito(textStyle: texto.displayLarge, fontWeight: FontWeight.w800),
        displayMedium: GoogleFonts.nunito(textStyle: texto.displayMedium, fontWeight: FontWeight.w800),
        displaySmall: GoogleFonts.nunito(textStyle: texto.displaySmall, fontWeight: FontWeight.w800),
        headlineLarge: GoogleFonts.nunito(textStyle: texto.headlineLarge, fontWeight: FontWeight.w800),
        headlineMedium: GoogleFonts.nunito(textStyle: texto.headlineMedium, fontWeight: FontWeight.w800),
        headlineSmall: GoogleFonts.nunito(textStyle: texto.headlineSmall, fontWeight: FontWeight.w800),
        titleLarge: GoogleFonts.nunito(textStyle: texto.titleLarge, fontWeight: FontWeight.w800),
        titleMedium: GoogleFonts.nunito(textStyle: texto.titleMedium, fontWeight: FontWeight.w700),
        titleSmall: GoogleFonts.nunito(textStyle: texto.titleSmall, fontWeight: FontWeight.w700),
        // Cuerpo y etiquetas -> Source Sans 3
        bodyLarge: GoogleFonts.sourceSans3(textStyle: texto.bodyLarge),
        bodyMedium: GoogleFonts.sourceSans3(textStyle: texto.bodyMedium),
        bodySmall: GoogleFonts.sourceSans3(textStyle: texto.bodySmall),
        labelLarge: GoogleFonts.sourceSans3(textStyle: texto.labelLarge),
        labelMedium: GoogleFonts.sourceSans3(textStyle: texto.labelMedium),
        labelSmall: GoogleFonts.sourceSans3(textStyle: texto.labelSmall),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.azul,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.azul.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white,
          textStyle: GoogleFonts.nunito(fontSize: 24, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hoverColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        labelStyle: cuerpo(19),
        floatingLabelStyle: cuerpo(18, color: AppColors.naranja, weight: FontWeight.w600),
        errorStyle: cuerpo(16, color: AppColors.rojo),
        border: _borde(AppColors.borde, 2),
        enabledBorder: _borde(AppColors.borde, 2),
        disabledBorder: _borde(AppColors.borde, 2),
        focusedBorder: _borde(AppColors.naranja, 2.5),
        errorBorder: _borde(AppColors.rojo, 2),
        focusedErrorBorder: _borde(AppColors.rojo, 3),
      ),
    );
  }
}
