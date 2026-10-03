import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/persona.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/features/session/widgets/barra_progreso.dart';

class SaludoInicio extends StatelessWidget {
  const SaludoInicio({super.key, required this.saludo, required this.adulto});

  final String saludo;
  final Adulto adulto;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              saludo,
              style: AppTheme.cuerpo(
                19,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 2),
            Semantics(
              header: true,
              child: Text(
                adulto.primerNombre,
                style: AppTheme.titulo(32, color: Colors.white, height: 1.15),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 16),
      Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Text(
          adulto.iniciales,
          style: AppTheme.titulo(19, color: Colors.white),
        ),
      ),
    ],
  );
}

class TarjetaProgreso extends StatelessWidget {
  const TarjetaProgreso({super.key, required this.nivelesHechos, required this.totalNiveles});

  final int nivelesHechos;
  final int totalNiveles;

  @override
  Widget build(BuildContext context) {
    final valor = totalNiveles == 0 ? 0.0 : nivelesHechos / totalNiveles;
    final porcentaje = (valor * 100).round();

    return Semantics(
      label: 'Tu avance en la valoración: $porcentaje por ciento completado',
      excludeSemantics: true,
      child: Glass(
        radio: 20,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        opacidad: 0.16,
        tinte: Colors.white,
        borde: Colors.white.withValues(alpha: 0.30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu avance en la valoración',
              style: AppTheme.cuerpo(
                16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BarraProgreso(
                    valor: valor,
                    color: AppColors.ambar,
                    fondo: Colors.white24,
                    alto: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$porcentaje %',
                  style: AppTheme.titulo(20, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
