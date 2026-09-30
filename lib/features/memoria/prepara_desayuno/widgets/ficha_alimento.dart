import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';

/// Emoji de un alimento a [tamano], sin que lo agrande la escala de texto del
/// equipo: el tamaño ya lo da el espacio disponible.
class EmojiAlimento extends StatelessWidget {
  const EmojiAlimento(this.alimento, {super.key, required this.tamano});

  final Alimento alimento;
  final double tamano;

  @override
  Widget build(BuildContext context) => Text(
        alimento.emoji,
        textScaler: TextScaler.noScaling,
        style: TextStyle(fontSize: tamano, height: 1),
      );
}

/// Ficha cuadrada con el emoji arriba y el nombre abajo, del tamaño que le den.
/// Sirve para la bandeja, el plato y la lista.
class FichaAlimento extends StatelessWidget {
  const FichaAlimento(
    this.alimento, {
    super.key,
    this.fondo = Colors.white,
    this.borde = AppColors.borde,
    this.anchoBorde = 2,
    this.colorNombre = AppColors.texto,
    this.marca,
  });

  final Alimento alimento;
  final Color fondo;
  final Color borde;
  final double anchoBorde;
  final Color colorNombre;

  /// Ícono pequeño en la esquina (hecho, número de puesto…).
  final Widget? marca;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, limites) {
          final lado = limites.biggest.shortestSide;
          return Container(
            decoration: BoxDecoration(
              color: fondo,
              borderRadius: BorderRadius.circular(lado * 0.18),
              border: Border.all(color: borde, width: anchoBorde),
            ),
            child: Stack(
              children: [
                // Ocupa toda la ficha para que emoji y nombre queden al centro.
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.all(lado * 0.07),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox.square(
                          dimension: lado * 0.46,
                          child: FittedBox(child: EmojiAlimento(alimento, tamano: lado * 0.46)),
                        ),
                        SizedBox(height: lado * 0.05),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              alimento.nombre,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              textScaler: TextScaler.noScaling,
                              style: AppTheme.titulo(lado * 0.17, color: colorNombre, height: 1.1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (marca != null) Positioned(right: lado * 0.05, top: lado * 0.05, child: marca!),
              ],
            ),
          );
        },
      );
}
