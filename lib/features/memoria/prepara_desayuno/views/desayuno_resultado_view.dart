import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/metricas_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/prepara_desayuno_game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ficha_alimento.dart';

/// «¡Actividad finalizada!» con la lista revisada y las cifras de la ronda.
/// El resultado ya quedó registrado al terminar.
class DesayunoResultadoView extends ConsumerWidget {
  const DesayunoResultadoView({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(preparaDesayunoProvider);
    final m = s.metricas;
    final sobrantes = m.plato.whereType<Alimento>().where((a) => !m.lista.contains(a)).toList();

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: PreparaDesayunoGame.idJuego),
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
              m.omisiones == 0 && m.errores == 0
                  ? 'Recordó todo el desayuno del nivel ${s.nivel.dificultad.nivel}.'
                  : 'Terminó el desayuno del nivel ${s.nivel.dificultad.nivel}.',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const SizedBox(height: 18),
            _Puntaje(puntaje: m.puntaje),
            const SizedBox(height: 18),
            const EtiquetaCampo('La lista era'),
            const SizedBox(height: 8),
            for (var i = 0; i < m.lista.length; i++) _Revision(metricas: m, indice: i),
            if (sobrantes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const EtiquetaCampo('No estaban en la lista'),
              const SizedBox(height: 8),
              for (final a in sobrantes) _Sobrante(alimento: a),
            ],
            const SizedBox(height: 14),
            _Cifra(etiqueta: 'Recordados', valor: '${m.aciertos}/${m.lista.length}'),
            if (m.conOrden) _Cifra(etiqueta: 'En su puesto', valor: '${m.enOrden}/${m.lista.length}'),
            _Cifra(etiqueta: 'Olvidados', valor: '${m.omisiones}'),
            _Cifra(etiqueta: 'Errores', valor: '${m.errores}'),
            _Cifra(etiqueta: 'Tiempo', valor: formatoReloj(m.tiempo)),
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
            onPressed: ref.read(preparaDesayunoProvider.notifier).repetir,
          ),
        ],
      ),
    );
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje({required this.puntaje});

  final int puntaje;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Puntaje $puntaje de 100',
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
              const Text('🍳', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 52, height: 1)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PUNTAJE', style: AppTheme.mono(13, color: AppColors.verdeTexto, letterSpacing: 1)),
                  Text('$puntaje', style: AppTheme.titulo(48, color: AppColors.verdeTexto, height: 1)),
                  Text('de 100', style: AppTheme.cuerpo(15, color: AppColors.verdeTexto)),
                ],
              ),
            ],
          ),
        ),
      );
}

/// Un alimento de la lista y si quedó en el plato (y en su puesto, con orden).
class _Revision extends StatelessWidget {
  const _Revision({required this.metricas, required this.indice});

  final MetricasDesayuno metricas;
  final int indice;

  @override
  Widget build(BuildContext context) {
    final a = metricas.lista[indice];
    final puesto = metricas.plato.indexOf(a);
    final recordado = puesto != -1;
    final enSuPuesto = metricas.enSuPuesto(indice);

    final (icono, color, nota) = !recordado
        ? (Icons.cancel_rounded, AppColors.rojo, 'Faltó')
        : metricas.conOrden && !enSuPuesto
            ? (Icons.swap_horiz_rounded, AppColors.naranja, 'Puesto ${puesto + 1}')
            : (Icons.check_circle_rounded, AppColors.verde, 'En el plato');

    return Semantics(
      label: '${metricas.conOrden ? '${indice + 1}. ' : ''}${a.nombre}: $nota',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            if (metricas.conOrden) ...[
              SizedBox(width: 26, child: Text('${indice + 1}.', style: AppTheme.titulo(19, color: AppColors.textoSuave))),
              const SizedBox(width: 4),
            ],
            EmojiAlimento(a, tamano: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                a.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.titulo(21, color: AppColors.texto),
              ),
            ),
            Icon(icono, color: color, size: 24),
            const SizedBox(width: 6),
            Text(nota, style: AppTheme.cuerpo(17, color: color, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Sobrante extends StatelessWidget {
  const _Sobrante({required this.alimento});

  final Alimento alimento;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${alimento.nombre}: no estaba en la lista',
        excludeSemantics: true,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borde, width: 2),
          ),
          child: Row(
            children: [
              EmojiAlimento(alimento, tamano: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(alimento.nombre, style: AppTheme.titulo(21, color: AppColors.texto))),
              const Icon(Icons.remove_circle_outline_rounded, color: AppColors.rojo, size: 24),
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
            Text(valor, style: AppTheme.titulo(22, color: AppColors.texto)),
          ],
        ),
      );
}
