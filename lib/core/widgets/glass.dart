import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radio = 18,
    this.padding = const EdgeInsets.all(16),
    this.opacidad = 0.55,
    this.blur = 16,
    this.tinte,
    this.borde,
    this.anchoBorde = 1,
  });

  final Widget child;
  final double radio;
  final EdgeInsets padding;
  final double opacidad;
  final double blur;
  final Color? tinte;
  final Color? borde;
  final double anchoBorde;

  @override
  Widget build(BuildContext context) {
    final base = tinte ?? Colors.white;
    final arriba = (opacidad + 0.12).clamp(0.0, 1.0);
    final abajo = (opacidad - 0.12).clamp(0.0, 1.0);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radio),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(alpha: arriba),
                  base.withValues(alpha: abajo),
                ],
              ),
              borderRadius: BorderRadius.circular(radio),
              border: Border.all(
                color: borde ?? AppColors.borde.withValues(alpha: 0.45),
                width: anchoBorde,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}