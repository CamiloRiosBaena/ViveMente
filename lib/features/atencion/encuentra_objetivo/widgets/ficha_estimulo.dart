import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';

/// Símbolo de un estímulo, a [tamano]. Letras y números van en la fuente de
/// títulos; las figuras se dibujan con íconos de Material (vienen dentro de
/// la app, así que se ven igual en cualquier equipo) y las frutas son emoji.
class TextoEstimulo extends StatelessWidget {
  const TextoEstimulo(this.estimulo, {super.key, required this.tamano, this.color = AppColors.texto});

  final Estimulo estimulo;
  final double tamano;
  final Color color;

  static const _cuarto = math.pi / 2;

  /// Ícono y giro de cada figura.
  static const figuras = <String, (IconData, double)>{
    '○': (Icons.circle_outlined, 0),
    '●': (Icons.circle, 0),
    '◎': (Icons.radio_button_checked, 0),
    '□': (Icons.check_box_outline_blank_rounded, 0),
    '■': (Icons.square_rounded, 0),
    '▢': (Icons.crop_din, 0),
    '▭': (Icons.rectangle_outlined, 0),
    '◇': (Icons.check_box_outline_blank_rounded, math.pi / 4),
    '◆': (Icons.square_rounded, math.pi / 4),
    '△': (Icons.change_history_rounded, 0),
    '▽': (Icons.change_history_rounded, math.pi),
    '◁': (Icons.change_history_rounded, -_cuarto),
    '▷': (Icons.change_history_rounded, _cuarto),
    '▲': (Icons.play_arrow_rounded, -_cuarto),
    '★': (Icons.star_rounded, 0),
    '☆': (Icons.star_border_rounded, 0),
    '✦': (Icons.star_half_rounded, 0),
    '✱': (Icons.emergency, 0),
    '♥': (Icons.favorite, 0),
  };

  @override
  Widget build(BuildContext context) {
    final figura = figuras[estimulo.simbolo];
    if (figura != null) {
      final (icono, giro) = figura;
      return Transform.rotate(angle: giro, child: Icon(icono, size: tamano * 1.15, color: color));
    }

    final alfanumerico = switch (estimulo.tipo) {
      TipoEstimulo.letra || TipoEstimulo.minuscula || TipoEstimulo.numero => true,
      TipoEstimulo.figura || TipoEstimulo.fruta => false,
    };

    return Text(
      estimulo.simbolo,
      textScaler: TextScaler.noScaling,
      style: alfanumerico
          ? AppTheme.titulo(tamano, color: color, height: 1)
          : TextStyle(fontSize: tamano * 0.95, color: color, height: 1),
    );
  }
}

/// Ficha cuadrada con un estímulo grande, para mostrar el objetivo.
class FichaEstimulo extends StatelessWidget {
  const FichaEstimulo(
    this.estimulo, {
    super.key,
    this.tamano = 64,
    this.fondo = Colors.white,
    this.borde = AppColors.borde,
  });

  final Estimulo estimulo;
  final double tamano;
  final Color fondo;
  final Color borde;

  @override
  Widget build(BuildContext context) => Container(
        width: tamano,
        height: tamano,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(tamano * 0.22),
          border: Border.all(color: borde, width: 2.5),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: TextoEstimulo(estimulo, tamano: tamano * 0.6),
        ),
      );
}
