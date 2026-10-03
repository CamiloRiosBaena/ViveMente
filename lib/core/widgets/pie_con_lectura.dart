import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Pie de las instrucciones: el botón para escuchar la consigna, compacto, al
/// lado del botón de avance. En una fila ocupan la mitad del alto que
/// apilados y le dejan más pantalla al contenido.
class PieConLectura extends StatelessWidget {
  const PieConLectura({
    super.key,
    required this.principal,
    required this.leyendo,
    required this.onEscuchar,
    this.queSeLee = 'la instrucción',
  });

  /// Normalmente un [BotonGrande].
  final Widget principal;
  final bool leyendo;
  final VoidCallback onEscuchar;

  /// Para el lector de pantalla: «Escuchar la instrucción».
  final String queSeLee;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          _BotonEscuchar(leyendo: leyendo, queSeLee: queSeLee, onPressed: onEscuchar),
          const SizedBox(width: 12),
          Expanded(child: principal),
        ],
      );
}

class _BotonEscuchar extends StatelessWidget {
  const _BotonEscuchar({required this.leyendo, required this.queSeLee, required this.onPressed});

  final bool leyendo;
  final String queSeLee;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: leyendo ? 'Detener la lectura' : 'Escuchar $queSeLee',
        excludeSemantics: true,
        child: SizedBox(
          width: 104,
          height: 76,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              backgroundColor: leyendo ? AppColors.naranjaSuave : Colors.white,
              foregroundColor: AppColors.naranjaTexto,
              side: BorderSide(color: leyendo ? AppColors.naranja : AppColors.borde, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(leyendo ? Icons.stop_rounded : Icons.volume_up_rounded, size: 30),
                  const SizedBox(height: 2),
                  Text(
                    leyendo ? 'Detener' : 'Escuchar',
                    maxLines: 1,
                    style: AppTheme.titulo(16, color: AppColors.naranjaTexto),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
