import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';

/// El emoji de la categoría a [tamano], sin que lo agrande la escala de texto
/// del equipo.
class EmojiCategoria extends StatelessWidget {
  const EmojiCategoria(this.categoria, {super.key, required this.tamano});

  final Categoria categoria;
  final double tamano;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: tamano * 1.15,
        child: Center(
          child: Text(
            categoria.emoji,
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: tamano, height: 1),
          ),
        ),
      );
}

/// Ficha con el emoji y el nombre de la categoría, para la presentación y el
/// resultado.
class FichaCategoria extends StatelessWidget {
  const FichaCategoria(this.categoria, {super.key, this.tamanoEmoji = 64, this.clara = false});

  final Categoria categoria;
  final double tamanoEmoji;

  /// Sobre fondo de color: borde ámbar y texto blanco.
  final bool clara;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(horizontal: tamanoEmoji * 0.4, vertical: tamanoEmoji * 0.3),
        decoration: BoxDecoration(
          color: clara ? Colors.white.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: clara ? AppColors.ambar : AppColors.borde, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmojiCategoria(categoria, tamano: tamanoEmoji),
            SizedBox(height: tamanoEmoji * 0.15),
            Text(
              categoria.nombre,
              textAlign: TextAlign.center,
              style: AppTheme.titulo(tamanoEmoji * 0.5, color: clara ? Colors.white : AppColors.texto, height: 1.1),
            ),
          ],
        ),
      );
}
