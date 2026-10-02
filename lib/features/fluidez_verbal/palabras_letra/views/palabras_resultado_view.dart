import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/metricas_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/palabras_letra_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/providers/palabras_letra_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/widgets/ficha_letra.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// «¡Actividad finalizada!» con las cifras de la ronda y las palabras dichas.
/// El resultado ya quedó registrado al confirmar la revisión.
class PalabrasResultadoView extends ConsumerWidget {
  const PalabrasResultadoView({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasLetraProvider);
    final m = s.metricas;
    final tramos = m.porTramo(s.nivel.duracion);

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: PalabrasLetraGame.idJuego),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('¡Actividad finalizada!', style: AppTheme.titulo(32, height: 1.15)),
            ),
            const SizedBox(height: 8),
            Text(
              m.validas >= m.meta
                  ? 'Alcanzó la meta del nivel ${s.nivel.dificultad.nivel} con la letra ${s.letra}.'
                  : 'Terminó el nivel ${s.nivel.dificultad.nivel} con la letra ${s.letra}.',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const SizedBox(height: 18),
            _Puntaje(letra: s.letra, validas: m.validas, meta: m.meta),
            const SizedBox(height: 12),
            _Cifra(etiqueta: 'Palabras válidas', valor: '${m.validas}'),
            _Cifra(etiqueta: 'Repetidas', valor: '${m.repetidas}'),
            _Cifra(etiqueta: 'Con otra letra', valor: '${m.otraLetra}'),
            _Cifra(etiqueta: 'No eran palabras', valor: '${m.noValidas}'),
            _Cifra(
              etiqueta: 'Ritmo',
              valor: m.validas == 0 ? '—' : '${(m.ritmoMs / 1000).toStringAsFixed(1).replaceAll('.', ',')} s por palabra',
            ),
            _Cifra(etiqueta: 'Por tramos de 15 s', valor: tramos.join(' · ')),
            _Cifra(etiqueta: 'Tiempo', valor: formatoReloj(m.tiempo)),
            if (m.palabras.isNotEmpty) ...[
              const SizedBox(height: 8),
              const EtiquetaCampo('Palabras que dijo'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in m.palabras)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.azulSuave,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.azulBorde),
                      ),
                      child: Text(p.texto, style: AppTheme.titulo(17, color: AppColors.azul)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: Column(
        children: [
          BotonGrande(texto: 'Volver al menú', onPressed: onVolver),
          const SizedBox(height: 12),
          BotonSecundario(
            texto: 'Repetir',
            icono: Icons.replay_rounded,
            onPressed: ref.read(palabrasLetraProvider.notifier).repetir,
          ),
        ],
      ),
    );
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje({required this.letra, required this.validas, required this.meta});

  final String letra;
  final int validas;
  final int meta;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Letra $letra. $validas palabras válidas; la meta era $meta',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.verdeSuave,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.verde, width: 2),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  FichaLetra(letra),
                  const SizedBox(height: 4),
                  Text('Letra', style: AppTheme.cuerpo(15, color: AppColors.verdeTexto)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PALABRAS', style: AppTheme.mono(13, color: AppColors.verdeTexto, letterSpacing: 1)),
                  Text('$validas', style: AppTheme.titulo(48, color: AppColors.verdeTexto, height: 1)),
                  Text('meta: $meta', style: AppTheme.cuerpo(15, color: AppColors.verdeTexto)),
                ],
              ),
            ],
          ),
        ),
      );
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(etiqueta, style: AppTheme.cuerpo(19, color: AppColors.texto))),
            const SizedBox(width: 10),
            Text(valor, style: AppTheme.titulo(22, color: AppColors.texto)),
          ],
        ),
      );
}
