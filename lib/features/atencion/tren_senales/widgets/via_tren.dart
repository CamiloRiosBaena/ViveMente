import 'package:flutter/material.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/tren_dibujo.dart';

/// Vía con el tren que está cruzando de derecha a izquierda. El provider dice
/// qué tren está en la vía y desde cuándo; aquí solo se anima su recorrido.
///
/// El tren crece con el ancho disponible: en un celular mide cerca de una
/// pantalla de largo y en tablet o escritorio se acota para no desbordar.
class ViaTren extends StatelessWidget {
  const ViaTren({
    super.key,
    required this.tren,
    required this.cruce,
    required this.transcurrido,
    required this.pausado,
    this.conEtiqueta = false,
  });

  final Tren? tren;
  final Duration cruce;
  final Duration transcurrido;
  final bool pausado;
  final bool conEtiqueta;

  static double escalaPara(double ancho) => (ancho / 230).clamp(1.4, 2.4);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, limites) {
          final escala = escalaPara(limites.maxWidth);
          final alto = TrenDibujo.alto * escala;

          return SizedBox(
            height: alto + 22,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(left: 0, right: 0, top: alto, child: const _Rieles()),
                if (tren != null)
                  _TrenEnMarcha(
                    key: ValueKey(tren!.id),
                    tren: tren!,
                    cruce: cruce,
                    inicio: transcurrido - tren!.salida,
                    pausado: pausado,
                    anchoVia: limites.maxWidth,
                    escala: escala,
                    conEtiqueta: conEtiqueta,
                  ),
              ],
            ),
          );
        },
      );
}

class _TrenEnMarcha extends StatefulWidget {
  const _TrenEnMarcha({
    super.key,
    required this.tren,
    required this.cruce,
    required this.inicio,
    required this.pausado,
    required this.anchoVia,
    required this.escala,
    required this.conEtiqueta,
  });

  final Tren tren;
  final Duration cruce;

  /// Cuánto lleva el tren en la vía al aparecer este widget.
  final Duration inicio;
  final bool pausado;
  final double anchoVia;
  final double escala;
  final bool conEtiqueta;

  @override
  State<_TrenEnMarcha> createState() => _TrenEnMarchaState();
}

class _TrenEnMarchaState extends State<_TrenEnMarcha> with SingleTickerProviderStateMixin {
  late final _avance = AnimationController(
    vsync: this,
    duration: widget.cruce,
    value: (widget.inicio.inMilliseconds / widget.cruce.inMilliseconds).clamp(0.0, 1.0),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.pausado) _avance.forward();
  }

  @override
  void didUpdateWidget(_TrenEnMarcha anterior) {
    super.didUpdateWidget(anterior);
    if (widget.pausado != anterior.pausado) {
      widget.pausado ? _avance.stop() : _avance.forward();
    }
  }

  @override
  void dispose() {
    _avance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anchoTren = TrenDibujo.ancho(widget.tren.vagones.length, widget.escala);
    final recorrido = widget.anchoVia + anchoTren;

    return AnimatedBuilder(
      animation: _avance,
      builder: (context, child) => Positioned(
        top: 0,
        left: widget.anchoVia - _avance.value * recorrido,
        child: child!,
      ),
      child: TrenDibujo(
        locomotora: widget.tren.locomotora,
        vagones: widget.tren.vagones,
        escala: widget.escala,
        conEtiqueta: widget.conEtiqueta,
      ),
    );
  }
}

class _Rieles extends StatelessWidget {
  const _Rieles();

  static const _riel = Color(0xFFD9C8B8);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 16,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 4,
              bottom: 0,
              child: Row(
                children: [
                  for (var i = 0; i < 40; i++)
                    Expanded(
                      child: Center(
                        child: Container(width: 6, color: _riel.withValues(alpha: 0.7)),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(left: 0, right: 0, top: 2, child: Container(height: 4, color: _riel)),
            Positioned(left: 0, right: 0, bottom: 0, child: Container(height: 3, color: _riel)),
          ],
        ),
      );
}
