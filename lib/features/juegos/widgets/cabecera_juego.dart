import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/widgets/cabecera_flujo.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';

/// Cabecera de las pantallas de un minijuego fuera de la ronda:
/// «ATENCIÓN SOSTENIDA · 1 DE 23 / Tren de las señales».
class CabeceraJuego extends ConsumerWidget {
  const CabeceraJuego({super.key, required this.juegoId, this.onAtras});

  final String juegoId;
  final VoidCallback? onAtras;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juego = ref.watch(juegoProvider(juegoId))!;
    final posicion = ref.watch(posicionJuegoProvider(juegoId));

    return CabeceraFlujo(
      color: juego.dominio.color,
      eyebrow: '${juego.descripcion} · ${posicion.numero} de ${posicion.total}',
      titulo: juego.titulo,
      onAtras: onAtras,
    );
  }
}
