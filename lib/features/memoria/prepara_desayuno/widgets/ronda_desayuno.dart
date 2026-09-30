import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';

/// Cabecera de la lista y de la bandeja: pausa a la izquierda y lo que hay que
/// hacer en grande. En la práctica lleva debajo un recordatorio.
class CabeceraRonda extends StatelessWidget {
  const CabeceraRonda({super.key, required this.titulo, required this.onPausa, this.subtitulo});

  final String titulo;
  final String? subtitulo;
  final VoidCallback onPausa;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Container(
      color: Dominio.memoria.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 12, m, 14),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Pausar',
                excludeSemantics: true,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onPausa,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.pause_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(titulo.toUpperCase(), style: AppTheme.titulo(21, color: Colors.white, height: 1.15)),
                    ),
                    if (subtitulo != null)
                      Text(subtitulo!, style: AppTheme.cuerpo(17, color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PausaDesayuno extends StatelessWidget {
  const PausaDesayuno({super.key, required this.onSeguir, required this.onSalir});

  final VoidCallback onSeguir;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.papel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text('En pausa', style: AppTheme.titulo(30))),
                  const SizedBox(height: 8),
                  Text('El tiempo está detenido. Siga cuando esté listo.', style: AppTheme.cuerpo(19, height: 1.4)),
                  const SizedBox(height: 22),
                  BotonGrande(texto: 'Seguir', onPressed: onSeguir),
                  const SizedBox(height: 12),
                  BotonSecundario(texto: 'Salir de la actividad', onPressed: onSalir),
                ],
              ),
            ),
          ),
        ),
      );
}
