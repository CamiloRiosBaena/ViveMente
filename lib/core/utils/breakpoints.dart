import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Puntos de quiebre y escalas para que la PWA funcione en celular,
/// tablet y escritorio con la misma vista.
abstract final class Bp {
  static const tablet = 600.0;
  static const escritorio = 1024.0;

  /// Ancho máximo del contenido: en pantallas grandes no estiramos el texto
  /// de lado a lado, lo centramos en una columna legible.
  static const anchoMaxContenido = 620.0;

  /// Ancho de la columna de las pantallas del flujo (imitan el marco de celular
  /// del diseño). El fondo de la cabecera sí llega a los bordes.
  static const anchoFlujo = 560.0;

  static bool esCelular(BuildContext c) => MediaQuery.sizeOf(c).width < tablet;
  static bool esTablet(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    return w >= tablet && w < escritorio;
  }
  static bool esEscritorio(BuildContext c) => MediaQuery.sizeOf(c).width >= escritorio;

  /// Padding horizontal según el tamaño de pantalla.
  static double padH(BuildContext c) => esCelular(c) ? 24 : 32;

  /// Margen lateral que deja el contenido del flujo en una columna centrada
  /// de [anchoFlujo], sin perder el padding normal.
  static double margenFlujo(BuildContext c) =>
      padH(c) + math.max(0, (MediaQuery.sizeOf(c).width - anchoFlujo) / 2);

  /// Multiplicador de tamaños (logo, botones, barras) en pantallas grandes.
  static double escala(BuildContext c) => esCelular(c) ? 1.0 : 1.15;

  /// Alto de la cabecera de marca de la primera pantalla: una franja
  /// proporcional al alto real del dispositivo, acotada para que en pantallas
  /// muy bajas no se coma el contenido ni en muy altas quede desmedida.
  static double altoCabeceraMarca(BuildContext c) {
    final alto = MediaQuery.sizeOf(c).height;
    return math.min(math.max(alto * (esPantallaBaja(c) ? 0.22 : 0.25), 130), 290);
  }

  /// Celulares bajos (por ejemplo 360x640): el contenido se aprieta un poco
  /// para que la pantalla completa se vea sin desplazar.
  static bool esPantallaBaja(BuildContext c) => MediaQuery.sizeOf(c).height < 700;

  /// Factor de los textos y separaciones del cuerpo en pantallas bajas.
  static double escalaAlto(BuildContext c) => esPantallaBaja(c) ? 0.85 : 1.0;
}

/// Centra y limita el ancho de su hijo. Envuelve el contenido de cada vista.
class ContenidoCentrado extends StatelessWidget {
  const ContenidoCentrado({super.key, required this.child, this.anchoMax = Bp.anchoMaxContenido});
  final Widget child;
  final double anchoMax;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: anchoMax),
          child: child,
        ),
      );
}
