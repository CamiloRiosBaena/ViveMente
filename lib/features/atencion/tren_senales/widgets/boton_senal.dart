import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Botón rojo grande «¡SEÑAL!». Responde al apoyar el dedo, no al soltarlo,
/// para que la latencia medida sea la del gesto.
class BotonSenal extends StatefulWidget {
  const BotonSenal({super.key, required this.onSenal, this.alto = 110});

  final VoidCallback onSenal;
  final double alto;

  @override
  State<BotonSenal> createState() => _BotonSenalState();
}

class _BotonSenalState extends State<BotonSenal> {
  static const _borde = Color(0xFF7A1712);
  static const _fondo = 9.0;

  bool _apretado = false;

  void _abajo(PointerDownEvent _) {
    setState(() => _apretado = true);
    widget.onSenal();
  }

  void _arriba() => setState(() => _apretado = false);

  @override
  Widget build(BuildContext context) {
    final bajada = _apretado ? _fondo - 2 : 0.0;

    return Semantics(
      button: true,
      label: 'Señal',
      onTap: widget.onSenal,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: _abajo,
        onPointerUp: (_) => _arriba(),
        onPointerCancel: (_) => _arriba(),
        child: SizedBox(
          height: widget.alto + _fondo,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: widget.alto,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: _borde, borderRadius: BorderRadius.circular(26)),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 60),
                left: 0,
                right: 0,
                top: bajada,
                height: widget.alto,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.rojo,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 16),
                        Text('¡SEÑAL!', style: AppTheme.titulo(40, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
