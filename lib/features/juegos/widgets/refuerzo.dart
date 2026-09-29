import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Lo que dice el globo de refuerzo. [id] cambia con cada respuesta para que
/// dos refuerzos iguales seguidos se animen los dos.
class MensajeRefuerzo {
  const MensajeRefuerzo({required this.texto, required this.icono, required this.color, required this.id});

  final String texto;
  final IconData icono;
  final Color color;
  final int id;
}

/// Globo breve sobre el área de juego: aparece con un pequeño rebote y se
/// desvanece. Con [mensaje] nulo no ocupa nada visible pero guarda su alto,
/// para que el tablero no salte.
class GloboRefuerzo extends StatelessWidget {
  const GloboRefuerzo({super.key, required this.mensaje, this.alto = 76, this.tamano = 24});

  final MensajeRefuerzo? mensaje;
  final double alto;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final m = mensaje;

    return SizedBox(
      height: alto,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animacion) => ScaleTransition(
            scale: CurvedAnimation(parent: animacion, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: animacion, child: child),
          ),
          child: m == null
              ? const SizedBox.shrink()
              : Semantics(
                  liveRegion: true,
                  key: ValueKey('${m.id}-${m.texto}'),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: tamano * 0.9, vertical: tamano * 0.45),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: m.color, width: 3),
                      boxShadow: [
                        BoxShadow(color: m.color.withValues(alpha: 0.25), blurRadius: 18, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icono, color: m.color, size: tamano * 1.4),
                        SizedBox(width: tamano * 0.4),
                        Flexible(child: Text(m.texto, style: AppTheme.titulo(tamano, color: m.color))),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Marco de color que se enciende y se apaga con cada refuerzo. Con [color]
/// nulo no pinta nada. No intercepta toques.
class DestelloRefuerzo extends StatelessWidget {
  const DestelloRefuerzo({super.key, required this.color, required this.id, this.intensidad = 1});

  final Color? color;
  final int id;

  /// 1 es el destello completo; valores menores lo hacen más discreto.
  final double intensidad;

  @override
  Widget build(BuildContext context) {
    final c = color;
    if (c == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(id),
        tween: Tween(begin: intensidad, end: 0),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOut,
        builder: (_, valor, _) => DecoratedBox(
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.10 * valor),
            border: Border.all(color: c.withValues(alpha: 0.85 * valor), width: 12),
          ),
        ),
      ),
    );
  }
}

/// Frases de elogio para los aciertos. Se van turnando con el id del refuerzo
/// para que no se repita siempre la misma.
const _elogios = ['¡Muy bien!', '¡Excelente!', '¡Así se hace!', '¡Bien hecho!'];

String elogioRefuerzo(int id) => _elogios[id % _elogios.length];

/// El refuerzo también se siente en la mano, en equipos con vibración.
void vibrarRefuerzo({required bool positivo}) =>
    positivo ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
