import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/metricas_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/nivel_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/widgets/ficha_categoria.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// «¡Actividad finalizada!» con las cifras de la ronda, las palabras válidas y
/// las que no contaron, para que el profesional las revise. El resultado ya
/// quedó registrado al terminar.
class CategoriaResultadoView extends ConsumerWidget {
  const CategoriaResultadoView({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasCategoriaProvider);
    final m = s.metricas;
    final tramos = m.porTramo(NivelCategoria.duracion);
    final categoria = s.categoria.nombre.toLowerCase();

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: PalabrasCategoriaGame.idJuego),
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
                  ? 'Alcanzó la meta del nivel ${s.nivel.dificultad.nivel} con $categoria.'
                  : 'Terminó el nivel ${s.nivel.dificultad.nivel} con $categoria.',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const SizedBox(height: 18),
            _Puntaje(categoria: s.categoria, validas: m.validas, meta: m.meta),
            const SizedBox(height: 12),
            _Cifra(etiqueta: 'Palabras válidas', valor: '${m.validas}'),
            _Cifra(etiqueta: 'Repetidas', valor: '${m.repetidas}'),
            _Cifra(etiqueta: 'De otra categoría', valor: '${m.otraCategoria.length}'),
            _Cifra(etiqueta: 'No reconocidas', valor: '${m.noReconocidas.length}'),
            _Cifra(
              etiqueta: 'Ritmo',
              valor: m.validas == 0 ? '—' : '${(m.ritmoMs / 1000).toStringAsFixed(1).replaceAll('.', ',')} s por palabra',
            ),
            _Cifra(etiqueta: 'Por tramos de 15 s', valor: tramos.join(' · ')),
            _Cifra(etiqueta: 'Tiempo', valor: formatoReloj(m.tiempo)),
            if (m.palabras.isNotEmpty)
              _Lista(
                titulo: 'Palabras que dijo',
                palabras: m.palabras.map((p) => p.texto).toList(),
                fondo: AppColors.azulSuave,
                borde: AppColors.azulBorde,
                texto: AppColors.azul,
              ),
            if (m.otraCategoria.isNotEmpty)
              _Lista(
                titulo: 'De otra categoría',
                palabras: m.otraCategoria,
                fondo: const Color(0xFFFDE4E1),
                borde: AppColors.rojo.withValues(alpha: 0.4),
                texto: AppColors.rojo,
              ),
            if (m.noReconocidas.isNotEmpty)
              _Lista(
                titulo: 'No reconocidas',
                nota: 'No están en el diccionario de la app. Revise si alguna era válida.',
                palabras: m.noReconocidas,
                fondo: AppColors.naranjaSuave,
                borde: AppColors.naranja.withValues(alpha: 0.4),
                texto: AppColors.naranjaTexto,
              ),
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
            onPressed: ref.read(palabrasCategoriaProvider.notifier).repetir,
          ),
        ],
      ),
    );
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje({required this.categoria, required this.validas, required this.meta});

  final Categoria categoria;
  final int validas;
  final int meta;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Categoría ${categoria.nombre}. $validas palabras válidas; la meta era $meta',
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
                  EmojiCategoria(categoria, tamano: 44),
                  const SizedBox(height: 4),
                  Text(categoria.nombre, style: AppTheme.cuerpo(15, color: AppColors.verdeTexto)),
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

/// Un grupo de palabras en fichas: las válidas, las de otra categoría o las
/// no reconocidas.
class _Lista extends StatelessWidget {
  const _Lista({
    required this.titulo,
    required this.palabras,
    required this.fondo,
    required this.borde,
    required this.texto,
    this.nota,
  });

  final String titulo;
  final String? nota;
  final List<String> palabras;
  final Color fondo;
  final Color borde;
  final Color texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetaCampo(titulo),
            if (nota != null) ...[
              const SizedBox(height: 2),
              Text(nota!, style: AppTheme.cuerpo(16, height: 1.35)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in palabras)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: fondo,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borde),
                    ),
                    child: Text(p, style: AppTheme.titulo(17, color: texto)),
                  ),
              ],
            ),
          ],
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
