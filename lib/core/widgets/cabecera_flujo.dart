import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';

/// Cabecera de color de cada pantalla. El fondo llega a los bordes; el contenido
/// se alinea con la columna del flujo.
class CabeceraFlujo extends StatelessWidget {
  const CabeceraFlujo({
    super.key,
    required this.titulo,
    this.color = AppColors.cafe,
    this.eyebrow,
    this.eyebrowMono = true,
    this.onAtras,
    this.accion,
    this.abajo,
  });

  final String titulo;
  final Color color;

  /// Línea pequeña sobre el título (dominio, rol, saludo…).
  final String? eyebrow;
  final bool eyebrowMono;

  /// Si se pasa, aparece la flecha de regreso.
  final VoidCallback? onAtras;

  /// Widget al final de la fila del título (por ejemplo «Salir»).
  final Widget? accion;

  /// Contenido bajo el título (por ejemplo un buscador).
  final Widget? abajo;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Container(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 16, m, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onAtras != null) ...[
                    BotonAtras(onPressed: onAtras!),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (eyebrow != null)
                          Text(
                            eyebrowMono ? eyebrow!.toUpperCase() : eyebrow!,
                            style: eyebrowMono
                                ? AppTheme.mono(13,
                                    color: Colors.white.withValues(alpha: 0.72), letterSpacing: 1)
                                : AppTheme.cuerpo(19, color: AppColors.azulClaro),
                          ),
                        Semantics(
                          header: true,
                          child: Text(titulo, style: AppTheme.titulo(27, color: Colors.white, height: 1.15)),
                        ),
                      ],
                    ),
                  ),
                  ?accion,
                ],
              ),
              if (abajo != null) ...[const SizedBox(height: 14), abajo!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Flecha de regreso de 48 px sobre la cabecera.
class BotonAtras extends StatelessWidget {
  const BotonAtras({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Volver',
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(13),
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onPressed,
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.chevron_left_rounded, color: Colors.white, size: 34),
            ),
          ),
        ),
      );
}
