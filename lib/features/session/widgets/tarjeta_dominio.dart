import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/features/session/widgets/barra_progreso.dart';

class TarjetaDominio extends StatelessWidget {
  const TarjetaDominio({
    super.key,
    required this.dominio,
    required this.hechas,
    required this.onTap,
  });

  final Dominio dominio;
  final int hechas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = dominio.cantidadActividades;
    final detalle =
        '$n actividades · $hechas ${hechas == 1 ? 'hecha' : 'hechas'}';
    final oscuro = Color.lerp(dominio.color, Colors.black, 0.18)!;

    return Semantics(
      button: true,
      label: '${dominio.etiqueta}, $detalle',
      excludeSemantics: true,
      child: Glass(
        radio: 22,
        padding: EdgeInsets.zero,
        opacidad: 0.62,
        tinte: Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: dominio.color.withValues(alpha: 0.10),
            highlightColor: dominio.color.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [dominio.color, oscuro],
                        ),
                      ),
                      child: Icon(dominio.icono, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dominio.etiqueta,
                          style: AppTheme.titulo(22, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(detalle, style: AppTheme.cuerpo(17)),
                        const SizedBox(height: 12),
                        BarraProgreso(
                          valor: n == 0 ? 0 : hechas / n,
                          color: AppColors.naranja,
                          fondo: AppColors.borde,
                          alto: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textoSuave,
                    size: 28,
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
