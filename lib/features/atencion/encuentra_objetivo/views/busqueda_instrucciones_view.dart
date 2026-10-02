import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/encuentra_objetivo_game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/providers/encuentra_objetivo_provider.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/widgets/ficha_estimulo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/juegos/widgets/selector_dificultad.dart';

/// Objetivo del intento, ejemplo y nivel antes de pulsar INICIAR.
class BusquedaInstruccionesView extends ConsumerWidget {
  const BusquedaInstruccionesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(encuentraObjetivoProvider);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final notifier = ref.read(encuentraObjetivoProvider.notifier);

    ref.listen(lecturaProvider, (_, estado) {
      if (estado != EstadoLectura.noDisponible) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
            'Este equipo no tiene la lectura en voz alta disponible. '
            'Revise que haya un motor de voz instalado en los ajustes del equipo.',
          ),
        ));
    });

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: EncuentraObjetivoGame.idJuego, onAtras: onBack),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Consigna(objetivo: s.objetivo),
            const SizedBox(height: 22),
            const EtiquetaCampo('Así se ve'),
            const SizedBox(height: 8),
            _Ejemplo(objetivo: s.objetivo.estimulo, otros: s.ejemplos),
            const SizedBox(height: 22),
            const SelectorDificultad(juegoId: EncuentraObjetivoGame.idJuego),
            const SizedBox(height: 14),
            Text(
              'Nivel ${s.nivel.dificultad.nivel} · 2 minutos · '
              'cuadrícula de ${s.nivel.columnas} × ${s.nivel.filas}.',
              style: AppTheme.cuerpo(18, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: Column(
        children: [
          BotonGrande(texto: 'Iniciar', onPressed: notifier.iniciar),
          const SizedBox(height: 12),
          BotonSecundario(
            texto: leyendo ? 'Detener la lectura' : 'Escuchar la instrucción',
            icono: leyendo ? Icons.stop_rounded : Icons.volume_up_rounded,
            onPressed: notifier.escucharInstruccion,
          ),
        ],
      ),
    );
  }
}

class _Consigna extends StatelessWidget {
  const _Consigna({required this.objetivo});

  final Objetivo objetivo;

  @override
  Widget build(BuildContext context) => Glass(
        radio: 20,
        padding: const EdgeInsets.all(20),
        opacidad: 0.6,
        tinte: AppColors.naranjaSuave,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${objetivo.encabezado}:'.toUpperCase(),
                    style: AppTheme.mono(14, color: AppColors.naranjaTexto, letterSpacing: 1, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Toque ${objetivo.todos} que encuentre.',
                    style: AppTheme.titulo(24, color: AppColors.naranjaTexto, height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  Text('Las demás casillas no cuentan.', style: AppTheme.cuerpo(18, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 14),
            FichaEstimulo(objetivo.estimulo, tamano: 84, borde: AppColors.naranja),
          ],
        ),
      );
}

class _Ejemplo extends StatelessWidget {
  const _Ejemplo({required this.objetivo, required this.otros});

  final Estimulo objetivo;
  final List<Estimulo> otros;

  @override
  Widget build(BuildContext context) => Glass(
        radio: 18,
        padding: const EdgeInsets.all(16),
        opacidad: 0.6,
        tinte: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _Muestra(estimulo: objetivo, si: true),
            for (final o in otros) _Muestra(estimulo: o, si: false),
          ],
        ),
      );
}

class _Muestra extends StatelessWidget {
  const _Muestra({required this.estimulo, required this.si});

  final Estimulo estimulo;
  final bool si;

  @override
  Widget build(BuildContext context) {
    final color = si ? AppColors.verde : AppColors.rojo;
    return Column(
      children: [
        FichaEstimulo(estimulo, tamano: 60, borde: color.withValues(alpha: 0.6)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(si ? Icons.check_circle_rounded : Icons.cancel_rounded, color: color, size: 20),
            const SizedBox(width: 4),
            Text(si ? 'este sí' : 'este no', style: AppTheme.titulo(16, color: color)),
          ],
        ),
      ],
    );
  }
}
