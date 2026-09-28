import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Ficha cuadrada con la letra de la ronda: azul con la letra blanca, o al
/// revés con [clara] (sobre fondos azules).
class FichaLetra extends StatelessWidget {
  const FichaLetra(this.letra, {super.key, this.tamano = 64, this.borde, this.clara = false});

  final String letra;
  final double tamano;
  final Color? borde;
  final bool clara;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Letra $letra',
        excludeSemantics: true,
        child: Container(
          width: tamano,
          height: tamano,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: clara ? Colors.white : AppColors.azul,
            borderRadius: BorderRadius.circular(tamano * 0.22),
            border: borde == null ? null : Border.all(color: borde!, width: 3),
          ),
          child: Text(
            letra,
            textScaler: TextScaler.noScaling,
            style: AppTheme.titulo(tamano * 0.6, color: clara ? AppColors.azul : Colors.white, height: 1),
          ),
        ),
      );
}
