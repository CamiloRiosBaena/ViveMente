import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/conexion.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Franja sobre toda la app que avisa cuando no hay internet. Empuja el
/// contenido hacia abajo en vez de taparlo.
class AvisoSinConexion extends ConsumerWidget {
  const AvisoSinConexion({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sinRed = ref.watch(hayConexionProvider).value == false;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: sinRed ? const _Franja() : const SizedBox(width: double.infinity),
        ),
        Expanded(
          // Con la franja visible, la pantalla de abajo ya no toca el borde
          // superior: se le quita ese margen para que no sume doble.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: sinRed,
            child: child,
          ),
        ),
      ],
    );
  }
}

class _Franja extends StatelessWidget {
  const _Franja();

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Material(
          color: AppColors.rojo,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sin conexión a internet. La app la necesita para funcionar.',
                      style: AppTheme.cuerpo(17, color: Colors.white, weight: FontWeight.w600, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
