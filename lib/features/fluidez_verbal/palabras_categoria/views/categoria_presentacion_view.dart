import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/widgets/ficha_categoria.dart';

/// La categoría de la ronda en grande durante unos segundos, antes de que
/// empiece a correr el tiempo. Luego queda en la cabecera.
class CategoriaPresentacionView extends ConsumerWidget {
  const CategoriaPresentacionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasCategoriaProvider);

    return Scaffold(
      backgroundColor: Dominio.fluidezVerbal.color,
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: 'Su categoría es ${s.categoria.nombre}. Empieza en ${s.cuentaAtras}.',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.practica) ...[
                    Text('PRÁCTICA', style: AppTheme.mono(16, color: AppColors.azulClaro, letterSpacing: 2)),
                    const SizedBox(height: 8),
                  ],
                  Text('Su categoría es', style: AppTheme.titulo(30, color: Colors.white)),
                  const SizedBox(height: 24),
                  // Aparece con un pequeño rebote.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.6, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutBack,
                    builder: (_, escala, hijo) => Transform.scale(scale: escala, child: hijo),
                    child: FichaCategoria(s.categoria, tamanoEmoji: 88, clara: true),
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
      ),
    );
  }
}
