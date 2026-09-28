import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/providers/palabras_letra_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/widgets/ficha_letra.dart';

/// La letra de la ronda en grande durante unos segundos, para verla bien
/// antes de que empiece a correr el tiempo. Luego queda en la cabecera.
class PalabrasPresentacionView extends ConsumerWidget {
  const PalabrasPresentacionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasLetraProvider);
    final tamano = MediaQuery.sizeOf(context);
    final lado = math.min(math.min(tamano.width * 0.6, tamano.height * 0.38), 280.0);

    return Scaffold(
      backgroundColor: Dominio.fluidezVerbal.color,
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Su letra es la ${s.letra}. Empieza en ${s.cuentaAtras}.',
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Su letra es', style: AppTheme.titulo(30, color: Colors.white)),
                const SizedBox(height: 24),
                // Aparece con un pequeño rebote.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.6, end: 1),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutBack,
                  builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
                  child: FichaLetra(s.letra, tamano: lado, borde: AppColors.ambar, clara: true),
                ),
                const SizedBox(height: 28),
                Text(
                  'Empieza en ${s.cuentaAtras}…',
                  style: AppTheme.cuerpo(24, color: AppColors.azulClaro, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
