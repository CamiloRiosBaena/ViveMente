import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// Cómo le fue en la práctica y paso a la ronda medida.
class TrenFinPracticaView extends ConsumerWidget {
  const TrenFinPracticaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trenSenalesProvider);
    final notifier = ref.read(trenSenalesProvider.notifier);
    final m = s.metricas;
    final color = s.objetivo.etiqueta;
    final plural = s.objetivo.plural;

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: TrenSenalesGame.idJuego, onAtras: notifier.verInstrucciones),
      cuerpo: CuerpoElastico(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.verdeSuave,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.check_rounded, size: 46, color: AppColors.verde),
            ),
            const SizedBox(height: 22),
            Semantics(header: true, child: Text('Terminó la práctica', style: AppTheme.titulo(32, height: 1.15))),
            const SizedBox(height: 12),
            Text(
              'Tocó a tiempo ${m.aciertos} de ${m.objetivos} trenes $plural.',
              style: AppTheme.cuerpo(21, color: AppColors.texto, height: 1.4),
            ),
            if (m.comisiones > 0) ...[
              const SizedBox(height: 8),
              Text('Recuerde: solo el tren $color cuenta.', style: AppTheme.cuerpo(20, height: 1.4)),
            ],
            const SizedBox(height: 16),
            Text(
              'Ahora empieza el nivel ${s.nivel.dificultad.nivel}. Dura ${s.nivel.etiquetaDuracion} '
              'y ya no aparecerá la pista «¡Ahora!».',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const Spacer(),
          ],
        ),
      ),
      pie: Column(
        children: [
          BotonGrande(texto: 'Empezar', onPressed: notifier.empezarPrueba),
          const SizedBox(height: 12),
          BotonSecundario(texto: 'Repetir la práctica', onPressed: notifier.empezarPractica),
        ],
      ),
    );
  }
}
