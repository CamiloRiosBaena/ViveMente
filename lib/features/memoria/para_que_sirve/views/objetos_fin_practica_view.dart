import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/nivel_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/para_que_sirve_game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';

/// Cómo le fue en la práctica y paso a la ronda medida.
class ObjetosFinPracticaView extends ConsumerWidget {
  const ObjetosFinPracticaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(paraQueSirveProvider);
    final notifier = ref.read(paraQueSirveProvider.notifier);
    final m = s.metricas;

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: ParaQueSirveGame.idJuego, onAtras: notifier.verInstrucciones),
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
              'Acertó ${m.aciertos} de ${m.total} preguntas.',
              style: AppTheme.cuerpo(21, color: AppColors.texto, height: 1.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Ahora empieza el nivel ${s.nivel.dificultad.nivel}: ${NivelObjetos.preguntas} preguntas con '
              'otros objetos. Después de cada una verá la explicación.',
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
