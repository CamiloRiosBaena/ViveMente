import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/utils/breakpoints.dart';

/// Cabecera café de las pantallas de marca (bienvenida e inicio). El fondo llega
/// a los bordes con las esquinas inferiores redondeadas; el contenido se alinea
/// con la columna del flujo.
///
/// Con [altoMinimo] la franja reserva ese alto y el contenido se acomoda abajo:
/// así la marca se ve grande de entrada sin empujar el resto de la pantalla.
class CabeceraMarca extends StatelessWidget {
  const CabeceraMarca({
    super.key,
    required this.child,
    this.altoMinimo,
    this.arriba = 18,
    this.abajo = 24,
  });

  final Widget child;
  final double? altoMinimo;
  final double arriba;
  final double abajo;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cafe,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: altoMinimo ?? 0),
          child: Padding(
            padding: EdgeInsets.fromLTRB(m, arriba, m, abajo),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo de ViveMente sobre una ficha blanca.
class LogoFicha extends StatelessWidget {
  const LogoFicha({super.key, this.tamano = 56});

  final double tamano;

  @override
  Widget build(BuildContext context) => Container(
        width: tamano,
        height: tamano,
        padding: EdgeInsets.all(tamano * 0.1),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(tamano * 0.25),
        ),
        child: Image.asset('assets/logo.png', semanticLabel: 'Logo de ViveMente'),
      );
}
