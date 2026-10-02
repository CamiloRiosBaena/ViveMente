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
  });

  final Widget child;
  final double radio;
  final EdgeInsets padding;
  final double opacidad;
  final double blur;
  final Color? tinte;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radio),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: (tinte ?? Colors.white).withValues(alpha: opacidad),
              borderRadius: BorderRadius.circular(radio),
              border: Border.all(
                color: AppColors.borde.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
}