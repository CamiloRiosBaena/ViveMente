import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Botón blanco con borde, para la acción que acompaña a [BotonGrande].
class BotonSecundario extends StatelessWidget {
  const BotonSecundario({super.key, required this.texto, required this.onPressed, this.icono});

  final String texto;
  final IconData? icono;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 64,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.naranjaTexto,
            side: const BorderSide(color: AppColors.borde, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            textStyle: AppTheme.titulo(20),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[Icon(icono, size: 26), const SizedBox(width: 10)],
                Text(texto, maxLines: 1),
              ],
            ),
          ),
        ),
      );
}
