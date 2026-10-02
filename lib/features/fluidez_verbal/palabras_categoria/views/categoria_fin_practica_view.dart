import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/fluidez_verbal/comun/widgets/revision_respuestas.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/views/categoria_revision_view.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// Cómo le fue en la práctica, palabra por palabra, y paso a la ronda medida.
class CategoriaFinPracticaView extends ConsumerWidget {
  const CategoriaFinPracticaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasCategoriaProvider);
    final notifier = ref.read(palabrasCategoriaProvider.notifier);
    final m = s.metricas;

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: PalabrasCategoriaGame.idJuego, onAtras: notifier.verInstrucciones),
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
              m.validas == 1 ? 'Dijo 1 color.' : 'Dijo ${m.validas} colores.',
              style: AppTheme.cuerpo(21, color: AppColors.texto, height: 1.4),
            ),
            if (m.errores > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Recuerde: solo cuentan las palabras de la categoría, sin repetir.',
                style: AppTheme.cuerpo(20, height: 1.4),
              ),
            ],
            if (s.respuestas.isNotEmpty) ...[
              const SizedBox(height: 14),
              ListaRevision(items: itemsRevision(s)),
            ],
            const SizedBox(height: 16),
            Text(
              'Al terminar la ronda podrá revisar las palabras. Ahora empieza el nivel ${s.nivel.dificultad.nivel}: verá la categoría y tendrá 60 segundos.',
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
