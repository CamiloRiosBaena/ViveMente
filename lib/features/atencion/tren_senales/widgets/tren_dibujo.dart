import 'package:flutter/material.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/tren_colores.dart';

/// Locomotora (a la izquierda, mira hacia donde avanza) y sus vagones. Todas
/// las medidas se multiplican por [escala].
class TrenDibujo extends StatelessWidget {
  const TrenDibujo({
    super.key,
    required this.locomotora,
    required this.vagones,
    this.escala = 1,
    this.conEtiqueta = false,
  });

  final ColorTren locomotora;
  final List<ColorTren> vagones;
  final double escala;

  /// Escribe el color sobre la locomotora (ejemplos y práctica).
  final bool conEtiqueta;

  static const _anchoLoco = 96.0;
  static const _anchoVagon = 58.0;
  static const _enganche = 8.0;
  static const alto = 74.0;

  /// Ancho total, para que la vía sepa cuándo el tren salió del todo.
  static double ancho(int vagones, double escala) =>
      (_anchoLoco + vagones * (_anchoVagon + _enganche)) * escala;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Tren ${locomotora.etiqueta}',
        excludeSemantics: true,
        child: SizedBox(
          height: alto * escala,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Locomotora(color: locomotora, escala: escala, conEtiqueta: conEtiqueta),
              for (final v in vagones) ...[
                _Enganche(escala: escala),
                _Vagon(color: v, escala: escala),
              ],
            ],
          ),
        ),
      );
}

class _Locomotora extends StatelessWidget {
  const _Locomotora({required this.color, required this.escala, required this.conEtiqueta});

  final ColorTren color;
  final double escala;
  final bool conEtiqueta;

  @override
  Widget build(BuildContext context) {
    final e = escala;
    return SizedBox(
      width: TrenDibujo._anchoLoco * e,
      height: TrenDibujo.alto * e,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Humo
          Positioned(
            left: 20 * e,
            top: 0,
            child: _Circulo(d: 9 * e, color: Colors.white.withValues(alpha: 0.85)),
          ),
          Positioned(
            left: 27 * e,
            top: -5 * e,
            child: _Circulo(d: 7 * e, color: Colors.white.withValues(alpha: 0.6)),
          ),
          // Chimenea
          Positioned(
            left: 18 * e,
            top: 9 * e,
            child: _Caja(w: 12 * e, h: 16 * e, color: color.sombra, r: 2 * e),
          ),
          // Caldera
          Positioned(
            left: 4 * e,
            top: 24 * e,
            child: _Caja(w: 52 * e, h: 34 * e, color: color.cuerpo, r: 6 * e),
          ),
          // Farol
          Positioned(
            left: 0,
            top: 32 * e,
            child: _Caja(w: 6 * e, h: 10 * e, color: const Color(0xFFFFC94A), r: 2 * e),
          ),
          // Cabina
          Positioned(
            left: 50 * e,
            top: 8 * e,
            child: _Caja(w: 44 * e, h: 50 * e, color: color.cuerpo, r: 6 * e),
          ),
          Positioned(
            left: 46 * e,
            top: 4 * e,
            child: _Caja(w: 50 * e, h: 7 * e, color: color.sombra, r: 3 * e),
          ),
          // Ventana
          Positioned(
            left: 60 * e,
            top: 16 * e,
            child: _Caja(w: 24 * e, h: 16 * e, color: const Color(0xFFDCEBF5), r: 4 * e),
          ),
          if (conEtiqueta)
            Positioned(
              left: 4 * e,
              width: 52 * e,
              top: 34 * e,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  color.etiqueta,
                  textScaler: TextScaler.noScaling,
                  style: AppTheme.titulo(12 * e, color: color.tinta),
                ),
              ),
            ),
          // Ruedas
          for (final x in [8.0, 32.0, 62.0])
            Positioned(left: x * e, bottom: 0, child: _Rueda(d: 20 * e, color: color)),
        ],
      ),
    );
  }
}

class _Vagon extends StatelessWidget {
  const _Vagon({required this.color, required this.escala});

  final ColorTren color;
  final double escala;

  @override
  Widget build(BuildContext context) {
    final e = escala;
    return SizedBox(
      width: TrenDibujo._anchoVagon * e,
      height: 52 * e,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _Caja(w: TrenDibujo._anchoVagon * e, h: 40 * e, color: color.cuerpo, r: 6 * e),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: _Caja(w: TrenDibujo._anchoVagon * e, h: 6 * e, color: color.sombra, r: 3 * e),
          ),
          Positioned(
            left: 8 * e,
            right: 8 * e,
            top: 12 * e,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 3; i++)
                  _Caja(w: 10 * e, h: 11 * e, color: Colors.white.withValues(alpha: 0.85), r: 2 * e),
              ],
            ),
          ),
          for (final x in [8.0, 34.0])
            Positioned(left: x * e, bottom: 0, child: _Rueda(d: 16 * e, color: color)),
        ],
      ),
    );
  }
}

class _Enganche extends StatelessWidget {
  const _Enganche({required this.escala});
  final double escala;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: 16 * escala),
        child: _Caja(w: TrenDibujo._enganche * escala, h: 4 * escala, color: const Color(0xFF4A3426), r: 1),
      );
}

class _Rueda extends StatelessWidget {
  const _Rueda({required this.d, required this.color});
  final double d;
  final ColorTren color;

  @override
  Widget build(BuildContext context) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: const Color(0xFF3A2A20),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: d * 0.12),
        ),
        alignment: Alignment.center,
        child: _Circulo(d: d * 0.35, color: color.cuerpo),
      );
}

class _Caja extends StatelessWidget {
  const _Caja({required this.w, required this.h, required this.color, this.r = 0});
  final double w;
  final double h;
  final Color color;
  final double r;

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(r)),
      );
}

class _Circulo extends StatelessWidget {
  const _Circulo({required this.d, required this.color});
  final double d;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
