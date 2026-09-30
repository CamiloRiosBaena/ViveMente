import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/features/juegos/widgets/refuerzo.dart';
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';
import 'package:vivamente/features/memoria/para_que_sirve/widgets/tarjeta_objeto.dart';

/// Una pregunta: el objeto, qué se pregunta y tres opciones. Al responder se
/// marca la correcta, se muestra la explicación y aparece «Siguiente».
class ObjetosPreguntaView extends ConsumerStatefulWidget {
  const ObjetosPreguntaView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  ConsumerState<ObjetosPreguntaView> createState() => _ObjetosPreguntaViewState();
}

class _ObjetosPreguntaViewState extends ConsumerState<ObjetosPreguntaView> {
  final _scroll = ScrollController();
  final _explicacion = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(paraQueSirveProvider);
    final notifier = ref.read(paraQueSirveProvider.notifier);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final m = Bp.margenFlujo(context);
    final p = s.pregunta;

    ref.listen(paraQueSirveProvider.select((s) => (s.indice, s.elegida)), (antes, ahora) {
      if (ahora.$1 != antes?.$1) {
        // Pregunta nueva: se vuelve arriba.
        if (_scroll.hasClients) _scroll.jumpTo(0);
        return;
      }
      if (ahora.$2 == null) return;
      vibrarRefuerzo(positivo: ref.read(paraQueSirveProvider).acerto);
      // Que la explicación quede a la vista aunque la pantalla sea baja.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = _explicacion.currentContext;
        if (c != null && c.mounted) {
          Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 350), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
        }
      });
    });

    EstadoOpcion estado(int i) {
      if (!s.respondida) return EstadoOpcion.normal;
      if (i == p.correcta) return EstadoOpcion.correcta;
      if (i == s.elegida) return EstadoOpcion.incorrecta;
      return EstadoOpcion.apagada;
    }

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(estado: s, onPausa: notifier.pausar),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(m, 18, m, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TarjetaObjeto(objeto: p.objeto),
                      const SizedBox(height: 16),
                      Semantics(header: true, child: Text(p.enunciado, style: AppTheme.titulo(25, height: 1.2))),
                      const SizedBox(height: 12),
                      for (var i = 0; i < p.opciones.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        BotonOpcion(
                          numero: i + 1,
                          opcion: p.opciones[i],
                          estado: estado(i),
                          onTap: s.respondida ? null : () => notifier.responder(i),
                        ),
                      ],
                      if (s.respondida) ...[
                        const SizedBox(height: 16),
                        _Explicacion(key: _explicacion, estado: s),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(m, 10, m, 20),
                  child: s.respondida
                      ? BotonGrande(
                          texto: !s.esUltima
                              ? 'Siguiente'
                              : s.practica
                                  ? 'Terminar la práctica'
                                  : 'Ver el resultado',
                          onPressed: notifier.siguiente,
                        )
                      : BotonSecundario(
                          texto: leyendo ? 'Detener la lectura' : 'Escuchar la pregunta',
                          icono: leyendo ? Icons.stop_rounded : Icons.volume_up_rounded,
                          onPressed: notifier.escucharPregunta,
                        ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: DestelloRefuerzo(
              color: !s.respondida
                  ? null
                  : s.acerto
                      ? AppColors.verde
                      : AppColors.rojo,
              id: s.indice,
            ),
          ),
          if (s.pausado) Positioned.fill(child: _Pausa(onSeguir: notifier.reanudar, onSalir: widget.onSalir)),
        ],
      ),
    );
  }
}

/// Pausa, en qué pregunta va y una barra con el avance.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.estado, required this.onPausa});

  final ParaQueSirveState estado;
  final VoidCallback onPausa;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);
    final total = estado.preguntas.length;
    final numero = estado.indice + 1;
    final hechas = estado.indice + (estado.respondida ? 1 : 0);

    return Container(
      color: Dominio.memoria.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 12, m, 14),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Pausar',
                excludeSemantics: true,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onPausa,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.pause_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estado.practica ? 'PRÁCTICA · $numero DE $total' : 'PREGUNTA $numero DE $total',
                      style: AppTheme.titulo(20, color: Colors.white, height: 1.15),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : hechas / total,
                        minHeight: 10,
                        color: AppColors.ambar,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «¡Muy bien!» o «La respuesta es…», con la explicación del concepto.
class _Explicacion extends ConsumerWidget {
  const _Explicacion({super.key, required this.estado});

  final ParaQueSirveState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = estado.pregunta;
    final bien = estado.acerto;
    final color = bien ? AppColors.verde : AppColors.rojo;
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;

    return Semantics(
      liveRegion: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          decoration: BoxDecoration(
            color: bien ? AppColors.verdeSuave : const Color(0xFFFDE4E1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(bien ? Icons.check_circle_rounded : Icons.info_rounded, color: color, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      bien ? elogioRefuerzo(estado.indice) : 'La respuesta es: ${p.respuesta.texto}',
                      style: AppTheme.titulo(22, color: bien ? AppColors.verdeTexto : AppColors.rojo, height: 1.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(p.explicacion, style: AppTheme.cuerpo(20, color: AppColors.texto, height: 1.4)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: ref.read(paraQueSirveProvider.notifier).escucharPregunta,
                  icon: Icon(leyendo ? Icons.stop_rounded : Icons.volume_up_rounded),
                  label: Text(leyendo ? 'Detener' : 'Escuchar la explicación'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.naranjaTexto,
                    minimumSize: const Size(48, 48),
                    textStyle: AppTheme.titulo(17),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pausa extends StatelessWidget {
  const _Pausa({required this.onSeguir, required this.onSalir});

  final VoidCallback onSeguir;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.papel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text('En pausa', style: AppTheme.titulo(30))),
                  const SizedBox(height: 8),
                  Text('Siga cuando esté listo.', style: AppTheme.cuerpo(19, height: 1.4)),
                  const SizedBox(height: 22),
                  BotonGrande(texto: 'Seguir', onPressed: onSeguir),
                  const SizedBox(height: 12),
                  BotonSecundario(texto: 'Salir de la actividad', onPressed: onSalir),
                ],
              ),
            ),
          ),
        ),
      );
}
