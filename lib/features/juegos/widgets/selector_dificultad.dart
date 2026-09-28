import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

/// Tres fichas «Nivel 1 · Fácil», «Nivel 2 · Medio», «Nivel 3 · Difícil» para
/// elegir la dificultad de un juego, con una marca en los niveles ya hechos.
/// Sirve para cualquier minijuego.
class SelectorDificultad extends ConsumerWidget {
  const SelectorDificultad({super.key, required this.juegoId});

  final String juegoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(dificultadJuegoProvider(juegoId));
    final hechos = ref.watch(nivelesHechosProvider(juegoId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EtiquetaCampo('Nivel'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final d in Dificultad.values) ...[
              if (d != Dificultad.values.first) const SizedBox(width: 10),
              Expanded(
                child: _Ficha(
                  dificultad: d,
                  elegida: d == actual,
                  hecho: hechos.contains(d),
                  onTap: () => ref.read(dificultadJuegoProvider(juegoId).notifier).elegir(d),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Ficha extends StatelessWidget {
  const _Ficha({required this.dificultad, required this.elegida, required this.hecho, required this.onTap});

  final Dificultad dificultad;
  final bool elegida;
  final bool hecho;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(16);

    return Semantics(
      button: true,
      selected: elegida,
      label: 'Nivel ${dificultad.nivel}, ${dificultad.etiqueta}${hecho ? ', hecho' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: elegida ? AppColors.naranjaSuave : Colors.white,
          borderRadius: borde,
          border: Border.all(
            color: elegida ? AppColors.naranja : AppColors.borde,
            width: elegida ? 3 : 2,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: borde,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                children: [
                  Text(
                    'Nivel ${dificultad.nivel}',
                    style: AppTheme.titulo(19, color: elegida ? AppColors.naranjaTexto : AppColors.texto),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hecho) ...[
                        const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.verde),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          hecho ? 'Hecho' : dificultad.etiqueta,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.cuerpo(
                            15,
                            color: hecho
                                ? AppColors.verdeTexto
                                : elegida
                                    ? AppColors.naranjaTexto
                                    : AppColors.textoSuave,
                            weight: hecho ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
