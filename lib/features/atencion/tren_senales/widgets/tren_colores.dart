import 'package:flutter/material.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';

/// Pintura de cada color del tren: el cuerpo y un tono más oscuro para techos,
/// bordes y ruedas.
extension ColorTrenEstilo on ColorTren {
  Color get cuerpo => switch (this) {
        ColorTren.rojo => const Color(0xFFC62828),
        ColorTren.azul => const Color(0xFF1F5FB0),
        ColorTren.verde => const Color(0xFF2E8B45),
        ColorTren.amarillo => const Color(0xFFF2C12E),
        ColorTren.morado => const Color(0xFF7B3FB0),
        ColorTren.gris => const Color(0xFF7D858C),
        ColorTren.cafe => const Color(0xFF7A4B2A),
        ColorTren.naranja => const Color(0xFFE8702A),
        ColorTren.vino => const Color(0xFF8C2438),
        ColorTren.rosado => const Color(0xFFD95F7A),
        ColorTren.terracota => const Color(0xFFB0492F),
        ColorTren.celeste => const Color(0xFF5AA7DA),
        ColorTren.turquesa => const Color(0xFF1E9C9C),
        ColorTren.marino => const Color(0xFF1B3A6B),
        ColorTren.lila => const Color(0xFF9A7FD1),
        ColorTren.oliva => const Color(0xFF6E7A2E),
        ColorTren.lima => const Color(0xFF8CC63F),
        ColorTren.verdeOscuro => const Color(0xFF1F5E3A),
        ColorTren.mostaza => const Color(0xFFC9A227),
        ColorTren.dorado => const Color(0xFFE0B64A),
        ColorTren.relleno => const Color(0xFFCBBFB3),
      };

  Color get sombra => Color.lerp(cuerpo, Colors.black, 0.32)!;

  /// Texto legible sobre [cuerpo].
  Color get tinta => cuerpo.computeLuminance() > 0.45 ? const Color(0xFF3A2A20) : Colors.white;
}
