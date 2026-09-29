import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/boton_senal.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/tren_colores.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/via_tren.dart';
import 'package:vivamente/features/juegos/widgets/refuerzo.dart';

/// Los trenes cruzan y el adulto toca ¡SEÑAL! cuando pasa el color objetivo.
/// Sirve para la práctica y para la ronda medida.
class TrenJuegoView extends ConsumerWidget {
  const TrenJuegoView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trenSenalesProvider);
    final notifier = ref.read(trenSenalesProvider.notifier);
    final m = Bp.margenFlujo(context);

    ref.listen(
      trenSenalesProvider.select((s) => s.retroId),
      (_, _) => vibrarRefuerzo(positivo: ref.read(trenSenalesProvider).retro.positiva),
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(estado: s, onPausa: notifier.pausar),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.papel, AppColors.naranjaSuave],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      _Aviso(estado: s),
                      const Spacer(),
                      ViaTren(
                        tren: s.enVia,
                        cruce: s.ritmo.cruce,
                        transcurrido: s.transcurrido,
                        pausado: s.pausado,
                        conEtiqueta: s.enPractica,
                      ),
                      const Spacer(flex: 2),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(m, 0, m, 20),
                          child: Column(
                            children: [
                              BotonSenal(onSenal: notifier.senal),
                              const SizedBox(height: 10),
                              Text(
                                'Toque en cualquier parte del botón',
                                style: AppTheme.cuerpo(17, color: AppColors.textoSuave),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(child: DestelloRefuerzo(color: _colorRetro(s.retro), id: s.retroId)),
          if (s.pausado)
            Positioned.fill(child: _Pausa(onSeguir: notifier.reanudar, onSalir: onSalir)),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.estado, required this.onPausa});

  final TrenSenalesState estado;
  final VoidCallback onPausa;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);
    final practica = estado.enPractica;
    final blanco = Colors.white.withValues(alpha: 0.85);

    return Container(
      color: Dominio.atencion.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 14, m, 16),
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
                child: practica
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Práctica', style: AppTheme.titulo(22, color: Colors.white)),
                          Text(
                            'Toque solo con el tren ${estado.objetivo.etiqueta}',
                            style: AppTheme.cuerpo(17, color: blanco),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BarraTiempo(avance: estado.avance),
                          const SizedBox(height: 6),
                          Text(
                            'Quedan ${estado.segundosRestantes} segundos',
                            style: AppTheme.cuerpo(17, color: blanco),
                          ),
                        ],
                      ),
              ),
              if (!practica) ...[
                const SizedBox(width: 16),
                Semantics(
                  label: '${estado.senales} señales',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text('${estado.senales}', style: AppTheme.titulo(26, color: Colors.white, height: 1.1)),
                      Text('señales', style: AppTheme.cuerpo(15, color: blanco)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// El provider avisa una vez por segundo; la barra se desliza entre avisos.
class _BarraTiempo extends StatelessWidget {
  const _BarraTiempo({required this.avance});

  final double avance;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: avance),
          duration: const Duration(seconds: 1),
          builder: (_, valor, _) => LinearProgressIndicator(
            value: 1 - valor,
            minHeight: 10,
            color: AppColors.ambar,
            backgroundColor: Colors.white24,
          ),
        ),
      );
}

Color? _colorRetro(RetroTren r) => switch (r) {
      RetroTren.bien => AppColors.verde,
      RetroTren.noEra => AppColors.rojo,
      RetroTren.sePaso => AppColors.naranja,
      RetroTren.ninguna => null,
    };

/// Globo sobre la vía: el refuerzo de cada acierto o error y, en la práctica,
/// la pista «¡Ahora!».
class _Aviso extends StatelessWidget {
  const _Aviso({required this.estado});

  final TrenSenalesState estado;

  MensajeRefuerzo? get _mensaje {
    final color = estado.objetivo.etiqueta;
    final id = estado.retroId;
    return switch (estado.retro) {
      RetroTren.bien => MensajeRefuerzo(
          texto: elogioRefuerzo(id), icono: Icons.check_circle_rounded, color: AppColors.verde, id: id),
      RetroTren.noEra =>
        MensajeRefuerzo(texto: 'Ese no era el $color', icono: Icons.cancel_rounded, color: AppColors.rojo, id: id),
      RetroTren.sePaso => MensajeRefuerzo(
          texto: 'Se escapó el tren $color', icono: Icons.schedule_rounded, color: AppColors.naranja, id: id),
      RetroTren.ninguna => estado.mostrarAhora
          ? MensajeRefuerzo(
              texto: '¡Ahora!', icono: Icons.touch_app_rounded, color: estado.objetivo.cuerpo, id: id)
          : null,
    };
  }

  @override
  Widget build(BuildContext context) => GloboRefuerzo(mensaje: _mensaje);
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
                  Text('Los trenes esperan. Siga cuando esté listo.', style: AppTheme.cuerpo(19, height: 1.4)),
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
