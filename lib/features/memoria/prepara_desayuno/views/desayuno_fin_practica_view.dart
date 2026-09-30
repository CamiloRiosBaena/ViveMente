import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/prepara_desayuno_game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';

/// Cómo le fue en la práctica y paso a la ronda medida.
class DesayunoFinPracticaView extends ConsumerWidget {
  const DesayunoFinPracticaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(preparaDesayunoProvider);
    final notifier = ref.read(preparaDesayunoProvider.notifier);
    final m = s.metricas;
    final nivel = s.nivel;

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: PreparaDesayunoGame.idJuego, onAtras: notifier.verInstrucciones),
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
              nivel.conOrden
                  ? 'Recordó ${m.aciertos} de ${m.lista.length} alimentos '
                      'y puso ${m.enOrden} en su puesto.'
                  : 'Recordó ${m.aciertos} de ${m.lista.length} alimentos.',
              style: AppTheme.cuerpo(21, color: AppColors.texto, height: 1.4),
            ),
            if (m.errores > 0) ...[
              const SizedBox(height: 8),
              Text('Recuerde: ponga solo lo que estaba en la lista.', style: AppTheme.cuerpo(20, height: 1.4)),
            ],
            const SizedBox(height: 16),
            Text(
              'Ahora empieza el nivel ${nivel.dificultad.nivel}, con otra lista de '
              '${nivel.textoElementos}${nivel.conOrden ? ' en orden' : ''}. '
              'Ya no se dirá si cada alimento está bien.',
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
