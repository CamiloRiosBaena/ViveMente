import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/features/session/widgets/ajustes_sesion.dart';

enum SeccionInicio { inicio, progreso }

/// Barra inferior de Inicio y Progreso. Marca la sección [actual] y navega
/// a las demás; Progreso se abre encima de Inicio, así que volver es un pop.
class BarraNavegacionInicio extends ConsumerWidget {
  const BarraNavegacionInicio({super.key, required this.actual});

  final SeccionInicio actual;

  /// Alto que ocupa sobre el contenido, para dejarle ese espacio libre abajo.
  static const alto = 136.0;

  void _ir(BuildContext context, SeccionInicio destino) {
    if (destino == actual) return;
    switch (destino) {
      case SeccionInicio.inicio:
        context.canPop() ? context.pop() : context.go('/inicio');
      case SeccionInicio.progreso:
        context.push('/progreso');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Bp.anchoFlujo - 40),
          child: Glass(
            radio: 30,
            padding: const EdgeInsets.symmetric(vertical: 6),
            opacidad: 0.72,
            tinte: Colors.white,
            blur: 22,
            child: Row(
              children: [
                Expanded(
                  child: _ItemBarra(
                    icono: Icons.home_rounded,
                    etiqueta: 'Inicio',
                    activo: actual == SeccionInicio.inicio,
                    onTap: () => _ir(context, SeccionInicio.inicio),
                  ),
                ),
                Expanded(
                  child: _ItemBarra(
                    icono: Icons.insights_outlined,
                    etiqueta: 'Progreso',
                    activo: actual == SeccionInicio.progreso,
                    onTap: () => _ir(context, SeccionInicio.progreso),
                  ),
                ),
                Expanded(
                  child: _ItemBarra(
                    icono: Icons.settings_outlined,
                    etiqueta: 'Ajustes',
                    onTap: () => abrirAjustes(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ItemBarra extends StatelessWidget {
  const _ItemBarra({
    required this.icono,
    required this.etiqueta,
    this.activo = false,
    this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: activo,
    label: etiqueta,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 30,
              decoration: BoxDecoration(
                color: activo ? AppColors.naranja : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icono,
                size: 22,
                color: activo ? Colors.white : AppColors.textoSuave,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              style: AppTheme.cuerpo(
                14,
                color: activo ? AppColors.texto : AppColors.textoSuave,
                weight: activo ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
