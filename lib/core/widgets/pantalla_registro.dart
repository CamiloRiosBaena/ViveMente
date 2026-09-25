import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';

/// Esqueleto de los tres pasos de registro (evaluador, cédula, datos): sin
/// cabecera de color; título grande, cuerpo, botón y, al pie, los puntos de
/// avance con el logo de la UNAD.
class PantallaRegistro extends StatelessWidget {
  const PantallaRegistro({
    super.key,
    required this.paso,
    required this.titulo,
    required this.cuerpo,
    required this.boton,
    this.subtitulo,
    this.icono,
    this.onAtras,
  });

  static const totalPasos = 3;

  /// Paso actual, de 1 a [totalPasos].
  final int paso;
  final String titulo;
  final String? subtitulo;
  final Widget cuerpo;
  final Widget boton;

  /// Ficha con ícono sobre el título (primer paso).
  final IconData? icono;

  /// Si se pasa, arriba aparecen la flecha de regreso y la barra «n de 3».
  final VoidCallback? onAtras;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(m, 16, m, 16),
                child: CuerpoElastico(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onAtras != null) _BarraPaso(paso: paso, onAtras: onAtras!),
                      // El bloque queda centrado entre la barra de paso y el
                      // botón: el aire sobrante se reparte parejo arriba y
                      // abajo en vez de acumularse en un hueco.
                      const Spacer(),
                      const SizedBox(height: 20),
                      if (icono != null) ...[
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.naranjaSuave,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(icono, size: 42, color: AppColors.textoSuave),
                        ),
                        const SizedBox(height: 22),
                      ],
                      Semantics(header: true, child: Text(titulo, style: AppTheme.titulo(34, height: 1.15))),
                      if (subtitulo != null) ...[
                        const SizedBox(height: 12),
                        Text(subtitulo!, style: AppTheme.cuerpo(20, height: 1.45)),
                      ],
                      const SizedBox(height: 28),
                      cuerpo,
                      const SizedBox(height: 20),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(m, 0, m, 14),
              child: Column(
                children: [
                  boton,
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _Puntos(paso: paso),
                      const Spacer(),
                      Image.asset('assets/Logo_unad_color.png', height: 36, semanticLabel: 'UNAD'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarraPaso extends StatelessWidget {
  const _BarraPaso({required this.paso, required this.onAtras});

  final int paso;
  final VoidCallback onAtras;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            button: true,
            label: 'Volver',
            child: Material(
              color: AppColors.crema,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: onAtras,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.chevron_left_rounded, size: 32, color: AppColors.textoSuave),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: paso / PantallaRegistro.totalPasos,
                minHeight: 8,
                color: AppColors.naranja,
                backgroundColor: AppColors.borde,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            '$paso de ${PantallaRegistro.totalPasos}',
            style: AppTheme.cuerpo(16, color: AppColors.textoSuave, weight: FontWeight.w600),
          ),
        ],
      );
}

class _Puntos extends StatelessWidget {
  const _Puntos({required this.paso});

  final int paso;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Paso $paso de ${PantallaRegistro.totalPasos}',
        excludeSemantics: true,
        child: Row(
          children: [
            for (var i = 1; i <= PantallaRegistro.totalPasos; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                width: i == paso ? 26 : 9,
                height: 9,
                decoration: BoxDecoration(
                  color: i == paso ? AppColors.naranja : AppColors.borde,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      );
}
