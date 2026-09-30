import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/features/juegos/widgets/refuerzo.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ficha_alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ronda_desayuno.dart';

/// El plato arriba, con un puesto por alimento de la lista, y la bandeja
/// revuelta abajo. Los alimentos pasan al plato con un toque o arrastrándolos.
///
/// En la ronda medida no se dice si cada alimento estaba en la lista: eso
/// sería soplar la respuesta; la revisión llega en el resultado. En la
/// práctica sí, con el refuerzo de los demás juegos.
class DesayunoBandejaView extends ConsumerWidget {
  const DesayunoBandejaView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(preparaDesayunoProvider);
    final notifier = ref.read(preparaDesayunoProvider.notifier);
    final m = Bp.margenFlujo(context);

    void elegir(int i) {
      HapticFeedback.selectionClick();
      notifier.elegir(i);
    }

    ref.listen(preparaDesayunoProvider.select((s) => s.retroId), (_, _) {
      final r = ref.read(preparaDesayunoProvider).retro;
      if (r == RetroDesayuno.bien || r == RetroDesayuno.noEstaba || r == RetroDesayuno.otroPuesto) {
        vibrarRefuerzo(positivo: r == RetroDesayuno.bien);
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabeceraRonda(
                titulo: s.practica ? 'Práctica' : 'Prepare el desayuno',
                subtitulo: s.practica ? 'Ponga en el plato lo de la lista' : null,
                onPausa: notifier.pausar,
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(m, 16, m, 0),
                child: _Plato(
                  estado: s,
                  onSoltar: (i, puesto) {
                    HapticFeedback.selectionClick();
                    puesto == null ? notifier.elegir(i) : notifier.poner(i, puesto);
                  },
                  onQuitar: notifier.quitar,
                ),
              ),
              GloboRefuerzo(mensaje: _mensaje(s), alto: 58, tamano: 18),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(m, 0, m, 0),
                  child: _Bandeja(estado: s, onElegir: elegir),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(m, 14, m, 20),
                  child: BotonGrande(texto: 'Listo', onPressed: notifier.terminar),
                ),
              ),
            ],
          ),
          Positioned.fill(child: DestelloRefuerzo(color: _colorRetro(s.retro), id: s.retroId, intensidad: 0.7)),
          if (s.pausado) Positioned.fill(child: PausaDesayuno(onSeguir: notifier.reanudar, onSalir: onSalir)),
        ],
      ),
    );
  }

  static MensajeRefuerzo? _mensaje(PreparaDesayunoState s) => switch (s.retro) {
        RetroDesayuno.bien => MensajeRefuerzo(
            texto: elogioRefuerzo(s.retroId), icono: Icons.check_circle_rounded, color: AppColors.verde, id: s.retroId),
        RetroDesayuno.noEstaba => MensajeRefuerzo(
            texto: 'Ese no estaba en la lista', icono: Icons.cancel_rounded, color: AppColors.rojo, id: s.retroId),
        RetroDesayuno.otroPuesto => MensajeRefuerzo(
            texto: 'Ese va en el puesto ${s.puestoCorrecto}',
            icono: Icons.swap_horiz_rounded,
            color: AppColors.naranja,
            id: s.retroId),
        RetroDesayuno.platoLleno => MensajeRefuerzo(
            texto: 'El plato está lleno', icono: Icons.info_rounded, color: AppColors.azul, id: s.retroId),
        RetroDesayuno.ninguna => null,
      };

  // Solo en la práctica: el aviso de plato lleno no lleva destello.
  static Color? _colorRetro(RetroDesayuno r) => switch (r) {
        RetroDesayuno.bien => AppColors.verde,
        RetroDesayuno.noEstaba => AppColors.rojo,
        RetroDesayuno.otroPuesto => AppColors.naranja,
        RetroDesayuno.platoLleno || RetroDesayuno.ninguna => null,
      };
}

/// Plato con un puesto por alimento de la lista. Se puede soltar un alimento
/// en un puesto o en cualquier parte del plato (va al primer puesto libre).
class _Plato extends StatelessWidget {
  const _Plato({required this.estado, required this.onSoltar, required this.onQuitar});

  final PreparaDesayunoState estado;

  /// Alimento [i] de la bandeja soltado en un puesto, o `null` si fue en el plato.
  final void Function(int i, int? puesto) onSoltar;
  final ValueChanged<int> onQuitar;

  static const _separacion = 8.0;

  @override
  Widget build(BuildContext context) {
    final plato = estado.plato;
    final conOrden = estado.nivel.conOrden;

    return DragTarget<int>(
      onAcceptWithDetails: (d) => onSoltar(d.data, null),
      builder: (context, candidatos, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: candidatos.isEmpty ? Colors.white : AppColors.naranjaSuave,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: candidatos.isEmpty ? AppColors.borde : AppColors.naranja, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    conOrden ? 'EL PLATO · EN ORDEN' : 'EL PLATO',
                    style: AppTheme.mono(13, color: AppColors.textoSuave, letterSpacing: 1, weight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${plato.whereType<Alimento>().length} de ${plato.length}',
                  style: AppTheme.titulo(17, color: AppColors.textoSuave),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, limites) {
                // Puestos cuadrados, sin pasar de 104 px en pantallas anchas.
                final lado = math.min(
                  (limites.maxWidth - _separacion * (plato.length - 1)) / plato.length,
                  104.0,
                );
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var p = 0; p < plato.length; p++) ...[
                      if (p > 0) const SizedBox(width: _separacion),
                      SizedBox.square(
                        dimension: lado,
                        child: _Puesto(
                          alimento: plato[p],
                          numero: conOrden ? p + 1 : null,
                          onSoltar: (i) => onSoltar(i, p),
                          onQuitar: () => onQuitar(p),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Puesto extends StatelessWidget {
  const _Puesto({required this.alimento, required this.numero, required this.onSoltar, required this.onQuitar});

  final Alimento? alimento;

  /// Número del puesto en el nivel con orden.
  final int? numero;
  final ValueChanged<int> onSoltar;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    final a = alimento;

    return DragTarget<int>(
      onAcceptWithDetails: (d) => onSoltar(d.data),
      builder: (context, candidatos, _) {
        if (a == null) {
          return Semantics(
            label: numero == null ? 'Puesto vacío' : 'Puesto $numero, vacío',
            excludeSemantics: true,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: candidatos.isEmpty ? AppColors.crema : AppColors.naranjaSuave,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: candidatos.isEmpty ? AppColors.bordeTenue : AppColors.naranja,
                  width: 2,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: numero == null
                    ? const Icon(Icons.add_rounded, color: AppColors.bordeTenue, size: 34)
                    : Text('$numero', style: AppTheme.titulo(30, color: AppColors.textoTenue)),
              ),
            ),
          );
        }

        return Semantics(
          button: true,
          label: '${numero == null ? '' : 'Puesto $numero, '}${a.nombre}. Toque para quitarlo',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onQuitar,
            child: FichaAlimento(
              a,
              fondo: AppColors.naranjaSuave,
              borde: candidatos.isEmpty ? AppColors.naranja : AppColors.naranjaTexto,
              anchoBorde: 2.5,
              colorNombre: AppColors.naranjaTexto,
              marca: _Marca(numero: numero),
            ),
          ),
        );
      },
    );
  }
}

/// Esquina de un alimento en el plato: su número de puesto, o una × que
/// recuerda que se puede quitar.
class _Marca extends StatelessWidget {
  const _Marca({required this.numero});

  final int? numero;

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: numero == null ? Colors.white : Dominio.memoria.color,
          shape: BoxShape.circle,
          border: numero == null ? Border.all(color: AppColors.naranja, width: 1.5) : null,
        ),
        child: numero == null
            ? const Icon(Icons.close_rounded, size: 15, color: AppColors.naranjaTexto)
            : Text('$numero', textScaler: TextScaler.noScaling, style: AppTheme.titulo(13, color: Colors.white)),
      );
}

/// La bandeja ocupa el espacio que queda; las fichas son cuadradas y del mayor
/// tamaño que cabe.
class _Bandeja extends StatelessWidget {
  const _Bandeja({required this.estado, required this.onElegir});

  final PreparaDesayunoState estado;
  final ValueChanged<int> onElegir;

  static const _separacion = 8.0;
  static const _relleno = 12.0;

  @override
  Widget build(BuildContext context) {
    final bandeja = estado.bandeja;

    return Container(
      padding: const EdgeInsets.all(_relleno),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borde, width: 2),
      ),
      child: LayoutBuilder(
        builder: (context, limites) {
          // Se prueban 3 y 4 columnas y se queda la que deja las fichas más
          // grandes: en celulares altos, 3; en pantallas anchas o bajas, 4.
          double ladoCon(int cols) {
            final filas = (bandeja.length / cols).ceil();
            return math.min(
              (limites.maxWidth - _separacion * (cols - 1)) / cols,
              (limites.maxHeight - _separacion * (filas - 1)) / filas,
            );
          }

          final cols = ladoCon(3) >= ladoCon(4) ? 3 : 4;
          final filas = (bandeja.length / cols).ceil();
          final lado = ladoCon(cols);

          return Center(
            child: SizedBox(
              width: lado * cols + _separacion * (cols - 1),
              height: lado * filas + _separacion * (filas - 1),
              child: Column(
                children: [
                  for (var f = 0; f < filas; f++) ...[
                    if (f > 0) const SizedBox(height: _separacion),
                    // La última fila, si queda incompleta, va centrada.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var c = 0; c < cols && f * cols + c < bandeja.length; c++) ...[
                          if (c > 0) const SizedBox(width: _separacion),
                          SizedBox.square(
                            dimension: lado,
                            child: _Comida(
                              indice: f * cols + c,
                              alimento: bandeja[f * cols + c],
                              enPlato: estado.enPlato(bandeja[f * cols + c]),
                              lado: lado,
                              onElegir: () => onElegir(f * cols + c),
                            ),
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
      ),
    );
  }
}

/// Un alimento de la bandeja. Ya puesto en el plato queda tenue y quieto.
class _Comida extends StatelessWidget {
  const _Comida({
    required this.indice,
    required this.alimento,
    required this.enPlato,
    required this.lado,
    required this.onElegir,
  });

  final int indice;
  final Alimento alimento;
  final bool enPlato;
  final double lado;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    if (enPlato) {
      return Semantics(
        label: '${alimento.nombre}, ya está en el plato',
        excludeSemantics: true,
        child: Opacity(
          opacity: 0.35,
          child: FichaAlimento(alimento, fondo: AppColors.crema, borde: AppColors.bordeTenue),
        ),
      );
    }

    final ficha = FichaAlimento(alimento);

    return Semantics(
      button: true,
      label: alimento.nombre,
      excludeSemantics: true,
      child: Draggable<int>(
        data: indice,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox.square(
            dimension: lado * 1.1,
            child: FichaAlimento(alimento, borde: AppColors.naranja, anchoBorde: 3),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: ficha),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onElegir,
          child: ficha,
        ),
      ),
    );
  }
}
