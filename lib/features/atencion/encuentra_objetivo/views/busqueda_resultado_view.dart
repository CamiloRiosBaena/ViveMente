import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/encuentra_objetivo_game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/metricas_busqueda.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/providers/encuentra_objetivo_provider.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/widgets/ficha_estimulo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// «¡Actividad finalizada!» con las cifras de la ronda. El resultado ya quedó
/// registrado al terminar.
class BusquedaResultadoView extends ConsumerWidget {
  const BusquedaResultadoView({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(encuentraObjetivoProvider);
    final m = s.metricas;
    final encontroTodos = m.aciertos == m.disponibles;

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: EncuentraObjetivoGame.idJuego),
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
              encontroTodos
                  ? 'Encontró todos los objetivos del nivel ${s.nivel.dificultad.nivel}.'
                  : 'Terminó el tiempo del nivel ${s.nivel.dificultad.nivel}.',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const SizedBox(height: 18),
            _Puntaje(puntaje: m.puntaje, objetivo: s.objetivo.simbolo, estimulo: FichaEstimulo(s.objetivo.estimulo)),
            const SizedBox(height: 12),
            _Cifra(etiqueta: 'Objetivos encontrados', valor: '${m.aciertos}/${m.disponibles}'),
            _Cifra(etiqueta: 'Aciertos', valor: '${m.aciertos}'),
            _Cifra(etiqueta: 'Errores', valor: '${m.errores}'),
            _Cifra(etiqueta: 'Precisión', valor: '${(m.precision * 100).round()} %'),
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
            onPressed: ref.read(encuentraObjetivoProvider.notifier).repetir,
          ),
        ],
      ),
    );
  }
}

class _Puntaje extends StatelessWidget {
  const _Puntaje({required this.puntaje, required this.objetivo, required this.estimulo});

  final int puntaje;
  final String objetivo;
  final Widget estimulo;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Objetivo $objetivo. Puntaje $puntaje de 100',
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
                  estimulo,
                  const SizedBox(height: 4),
                  Text('Objetivo', style: AppTheme.cuerpo(15, color: AppColors.verdeTexto)),
                ],
              ),
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
