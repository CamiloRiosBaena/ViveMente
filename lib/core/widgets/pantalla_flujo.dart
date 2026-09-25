import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/utils/breakpoints.dart';

/// Esqueleto de las pantallas del flujo: cabecera de color, cuerpo y, opcionalmente,
/// un pie fijo con el botón de avance. Cuerpo y pie se centran en [Bp.anchoFlujo].
class PantallaFlujo extends StatelessWidget {
  const PantallaFlujo({
    super.key,
    required this.cabecera,
    required this.cuerpo,
    this.pie,
    this.fondo = AppColors.papel,
    this.paddingSuperior = 22,
  });

  final Widget cabecera;
  final Widget cuerpo;
  final Widget? pie;
  final Color fondo;
  final double paddingSuperior;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Scaffold(
      backgroundColor: fondo,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          cabecera,
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(m, paddingSuperior, m, 0),
              child: cuerpo,
            ),
          ),
          if (pie != null)
            SafeArea(
              top: false,
              child: Padding(padding: EdgeInsets.fromLTRB(m, 16, m, 24), child: pie),
            ),
        ],
      ),
    );
  }
}

/// Cuerpo que se desplaza cuando el contenido no cabe y, cuando sobra alto,
/// reparte el espacio libre entre los bloques de su [Column] (sus `Spacer`).
/// Evita que en pantallas altas todo quede apretado arriba.
class CuerpoElastico extends StatelessWidget {
  const CuerpoElastico({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, limites) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: limites.maxHeight),
            child: IntrinsicHeight(child: child),
          ),
        ),
      );
}

/// Vuelve a la pantalla anterior; si no hay (recarga de la PWA), va a [respaldo].
void volverOIr(BuildContext context, String respaldo) =>
    context.canPop() ? context.pop() : context.go(respaldo);
