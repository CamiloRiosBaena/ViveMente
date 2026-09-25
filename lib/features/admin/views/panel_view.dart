import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/cabecera_flujo.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/auth/providers/auth_provider.dart';

/// Destino provisional tras el ingreso del profesional, hasta tener el panel real.
class PanelView extends ConsumerWidget {
  const PanelView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(authProvider);
    final general = estado is AuthAutenticado && estado.rol == 'adminGeneral';

    return PantallaFlujo(
      fondo: const Color(0xFFF7FAFC),
      cabecera: CabeceraFlujo(
        color: general ? AppColors.azulNoche : AppColors.azulProfundo,
        eyebrow: general ? 'Admin general' : 'Admin regional',
        titulo: 'Resumen',
        accion: TextButton(
          onPressed: () {
            ref.invalidate(authProvider);
            context.go('/');
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(72, 48),
            textStyle: AppTheme.cuerpo(18, weight: FontWeight.w700),
          ),
          child: const Text('Salir'),
        ),
      ),
      cuerpo: Center(
        child: Text(
          'El panel de resultados llega en la siguiente versión.',
          textAlign: TextAlign.center,
          style: AppTheme.cuerpo(20, height: 1.45),
        ),
      ),
    );
  }
}
