import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';

/// Tarjeta blanca tocable. Seleccionada: borde naranja de 4 px con sombra;
/// si no, borde suave de 2 px.
class TarjetaElegible extends StatelessWidget {
  const TarjetaElegible({
    super.key,
    required this.child,
    required this.onTap,
    this.seleccionada = false,
    this.radio = 20,
    this.padding = const EdgeInsets.all(18),
    this.etiquetaSemantica,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool seleccionada;
  final double radio;
  final EdgeInsetsGeometry padding;
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(radio);

    return Semantics(
      button: true,
      selected: seleccionada,
      label: etiquetaSemantica,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borde,
          border: Border.all(
            color: seleccionada ? AppColors.naranja : AppColors.borde,
            width: seleccionada ? 4 : 2,
          ),
          boxShadow: seleccionada
              ? [
                  BoxShadow(
                    color: AppColors.naranja.withValues(alpha: 0.16),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borde,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
