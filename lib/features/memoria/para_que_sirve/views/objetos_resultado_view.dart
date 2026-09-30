import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/metricas_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/para_que_sirve_game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';
import 'package:vivamente/features/memoria/para_que_sirve/widgets/tarjeta_objeto.dart';

/// «¡Actividad finalizada!» con el puntaje y cada objeto revisado. El
/// resultado ya quedó registrado al terminar.
class ObjetosResultadoView extends ConsumerWidget {
  const ObjetosResultadoView({super.key, required this.onVolver});

  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(paraQueSirveProvider);
    final m = s.metricas;

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: ParaQueSirveGame.idJuego),
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
              m.errores == 0
                  ? 'Acertó todas las preguntas del nivel ${s.nivel.dificultad.nivel}.'
                  : 'Terminó las preguntas del nivel ${s.nivel.dificultad.nivel}.',
              style: AppTheme.cuerpo(20, height: 1.4),
            ),
            const SizedBox(height: 18),
            _Puntaje(puntaje: m.puntaje),
            const SizedBox(height: 18),
            const EtiquetaCampo('Sus respuestas'),
            const SizedBox(height: 8),
            for (final r in m.respuestas) _Revision(respuesta: r),
            const SizedBox(height: 8),
            _Cifra(etiqueta: 'Aciertos', valor: '${m.aciertos}/${m.total}'),
            _Cifra(etiqueta: 'Errores', valor: '${m.errores}'),
            _Cifra(etiqueta: 'Tiempo pensando', valor: formatoReloj(m.tiempo)),
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
            onPressed: ref.read(paraQueSirveProvider.notifier).repetir,
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
              const Icon(Icons.lightbulb_rounded, size: 52, color: AppColors.ambar),
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

/// Un objeto, lo que respondió y, si falló, la respuesta correcta.
class _Revision extends StatelessWidget {
  const _Revision({required this.respuesta});

  final Respuesta respuesta;

  @override
  Widget build(BuildContext context) {
    final p = respuesta.pregunta;
    final bien = respuesta.correcta;
    final color = bien ? AppColors.verde : AppColors.rojo;

    return Semantics(
      label: '${p.objeto.nombre}: ${bien ? 'correcto' : 'era ${p.respuesta.texto}'}',
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
            EmojiObjeto(p.objeto.emoji, tamano: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.objeto.nombre, style: AppTheme.titulo(20, color: AppColors.texto)),
                  Text(p.respuesta.texto, style: AppTheme.cuerpo(17, color: AppColors.textoSuave, height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(bien ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 28),
          ],
        ),
      ),
    );
  }
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
