import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/providers/encuentra_objetivo_provider.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/widgets/ficha_estimulo.dart';
import 'package:vivamente/features/juegos/widgets/refuerzo.dart';

/// Ronda de búsqueda: objetivo arriba, cronómetro y aciertos, y la cuadrícula.
/// Sirve para la práctica y para la ronda medida.
class BusquedaJuegoView extends ConsumerWidget {
  const BusquedaJuegoView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(encuentraObjetivoProvider);
    final notifier = ref.read(encuentraObjetivoProvider.notifier);
    final m = Bp.margenFlujo(context);

    ref.listen(
      encuentraObjetivoProvider.select((s) => s.retroId),
      (_, _) => vibrarRefuerzo(positivo: ref.read(encuentraObjetivoProvider).retro == RetroBusqueda.correcto),
    );

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(objetivo: s.objetivo, practica: s.enPractica, onPausa: notifier.pausar),
              Padding(
                padding: EdgeInsets.fromLTRB(m, 14, m, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Tiempo',
                        valor: s.textoTiempo,
                        icono: Icons.timer_outlined,
                        alerta: s.restante < const Duration(seconds: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Acertados',
                        // En la práctica se sabe cuántos hay: ayuda a ver que se terminó.
                        valor: s.enPractica
                            ? '${s.metricas.aciertos} de ${s.metricas.disponibles}'
                            : '${s.metricas.aciertos}',
                        icono: Icons.check_circle_outline_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              GloboRefuerzo(mensaje: _mensaje(s), alto: 58, tamano: 19),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(m, 0, m, 16),
                  child: SafeArea(
                    top: false,
                    child: _Cuadricula(estado: s, onTocar: notifier.tocar),
                  ),
                ),
              ),
            ],
          ),
          Positioned.fill(
            child: DestelloRefuerzo(color: _colorRetro(s.retro), id: s.retroId, intensidad: 0.7),
          ),
          if (s.pausado)
            Positioned.fill(child: _Pausa(onSeguir: notifier.reanudar, onSalir: onSalir)),
        ],
      ),
    );
  }

  static MensajeRefuerzo? _mensaje(EncuentraObjetivoState s) => switch (s.retro) {
        RetroBusqueda.correcto => MensajeRefuerzo(
            texto: elogioRefuerzo(s.retroId), icono: Icons.check_circle_rounded, color: AppColors.verde, id: s.retroId),
        RetroBusqueda.incorrecto => MensajeRefuerzo(
            texto: 'Ese no es', icono: Icons.cancel_rounded, color: AppColors.rojo, id: s.retroId),
        RetroBusqueda.ninguna => null,
      };

  // Los toques son seguidos, así que el destello es algo más suave que en el tren.
  static Color? _colorRetro(RetroBusqueda r) => switch (r) {
        RetroBusqueda.correcto => AppColors.verde,
        RetroBusqueda.incorrecto => AppColors.rojo,
        RetroBusqueda.ninguna => null,
      };
}

/// «ENCUENTRA LA LETRA: A», con el objetivo grande y claro.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.objetivo, required this.practica, required this.onPausa});

  final Objetivo objetivo;
  final bool practica;
  final VoidCallback onPausa;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Container(
      color: Dominio.atencion.color,
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
                child: Semantics(
                  header: true,
                  label: '${practica ? 'Práctica. ' : ''}${objetivo.encabezado} ${objetivo.simbolo}',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (practica)
                        Text(
                          'PRÁCTICA',
                          style: AppTheme.mono(13, color: AppColors.ambar, letterSpacing: 1.5, weight: FontWeight.w600),
                        ),
                      Text(
                        '${objetivo.encabezado}:'.toUpperCase(),
                        style: AppTheme.titulo(21, color: Colors.white, height: 1.15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FichaEstimulo(objetivo.estimulo, tamano: 72, borde: AppColors.ambar),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, required this.icono, this.alerta = false});

  final String etiqueta;
  final String valor;
  final IconData icono;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final color = alerta ? AppColors.rojo : AppColors.texto;

    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Glass(
        radio: 16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        opacidad: 0.6,
        tinte: Colors.white,
        child: Row(
          children: [
            Icon(icono, color: alerta ? AppColors.rojo : AppColors.textoSuave, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    etiqueta.toUpperCase(),
                    style: AppTheme.mono(12, color: AppColors.textoSuave, letterSpacing: 1),
                  ),
                  Text(valor, style: AppTheme.titulo(24, color: color, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La cuadrícula ocupa el espacio que queda; las casillas son cuadradas y del
/// mayor tamaño que cabe.
class _Cuadricula extends StatelessWidget {
  const _Cuadricula({required this.estado, required this.onTocar});

  final EncuentraObjetivoState estado;
  final ValueChanged<int> onTocar;

  static const _separacion = 6.0;

  @override
  Widget build(BuildContext context) {
    final cols = estado.rejilla.columnas;
    final filas = estado.rejilla.filas;

    return LayoutBuilder(
      builder: (context, limites) {
        final lado = math.min(
          (limites.maxWidth - _separacion * (cols - 1)) / cols,
          (limites.maxHeight - _separacion * (filas - 1)) / filas,
        );

        return Center(
          child: SizedBox(
            width: lado * cols + _separacion * (cols - 1),
            height: lado * filas + _separacion * (filas - 1),
            child: Column(
              children: [
                for (var f = 0; f < filas; f++) ...[
                  if (f > 0) const SizedBox(height: _separacion),
                  Row(
                    children: [
                      for (var c = 0; c < cols; c++) ...[
                        if (c > 0) const SizedBox(width: _separacion),
                        _Casilla(
                          estimulo: estado.casillas[f * cols + c],
                          lado: lado,
                          encontrada: estado.encontradas.contains(f * cols + c),
                          equivocada: estado.casillaError == f * cols + c,
                          onTocar: () => onTocar(f * cols + c),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.estimulo,
    required this.lado,
    required this.encontrada,
    required this.equivocada,
    required this.onTocar,
  });

  final Estimulo estimulo;
  final double lado;
  final bool encontrada;
  final bool equivocada;
  final VoidCallback onTocar;

  static const _rojoSuave = Color(0xFFFDE4E1);

  @override
  Widget build(BuildContext context) {
    final (fondo, borde) = encontrada
        ? (AppColors.verdeSuave, AppColors.verde)
        : equivocada
            ? (_rojoSuave, AppColors.rojo)
            : (Colors.white, AppColors.borde);

    return Semantics(
      button: true,
      label: encontrada ? '${estimulo.simbolo}, encontrada' : estimulo.simbolo,
      excludeSemantics: true,
      // Al apoyar el dedo, no al soltarlo: la respuesta se siente inmediata.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => onTocar(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: lado,
          height: lado,
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.circular(lado * 0.18),
            border: Border.all(color: borde, width: encontrada || equivocada ? 3 : 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: TextoEstimulo(
                  estimulo,
                  tamano: lado * 0.55,
                  color: encontrada ? AppColors.verdeTexto : AppColors.texto,
                ),
              ),
              if (encontrada)
                Positioned(
                  right: lado * 0.06,
                  top: lado * 0.06,
                  child: Icon(Icons.check_circle_rounded, color: AppColors.verde, size: lado * 0.28),
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Glass(
                radio: 24,
                padding: const EdgeInsets.all(24),
                opacidad: 0.85,
                tinte: AppColors.papel,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(header: true, child: Text('En pausa', style: AppTheme.titulo(30))),
                    const SizedBox(height: 8),
                    Text('El tiempo está detenido. Siga cuando esté listo.', style: AppTheme.cuerpo(19, height: 1.4)),
                    const SizedBox(height: 22),
                    BotonGrande(texto: 'Seguir', onPressed: onSeguir),
                    const SizedBox(height: 12),
                    BotonSecundario(texto: 'Salir de la actividad', onPressed: onSalir),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
