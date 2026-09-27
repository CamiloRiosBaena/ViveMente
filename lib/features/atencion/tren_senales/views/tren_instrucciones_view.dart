import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/atencion/tren_senales/models/nivel_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/tren_colores.dart';
import 'package:vivamente/features/atencion/tren_senales/widgets/tren_dibujo.dart';
import 'package:vivamente/features/juegos/widgets/selector_dificultad.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// Consigna, ejemplo del tren objetivo y elección del nivel antes de la
/// práctica. El color objetivo cambia en cada intento.
class TrenInstruccionesView extends ConsumerWidget {
  const TrenInstruccionesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(trenSenalesProvider);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final notifier = ref.read(trenSenalesProvider.notifier);

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
      cabecera: CabeceraJuego(juegoId: TrenSenalesGame.idJuego, onAtras: onBack),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Consigna(objetivo: s.objetivo),
            const SizedBox(height: 22),
            const EtiquetaCampo('Así se ve'),
            const SizedBox(height: 8),
            _Ejemplo(objetivo: s.objetivo, distractor: s.ejemploDistractor),
            const SizedBox(height: 22),
            const SelectorDificultad(juegoId: TrenSenalesGame.idJuego),
            const SizedBox(height: 14),
            Text(
              'Nivel ${s.nivel.dificultad.nivel} · ${s.nivel.etiquetaDuracion} · '
              '${NivelTren.trenesPractica} ejemplos de práctica antes de empezar.',
              style: AppTheme.cuerpo(18, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: Column(
        children: [
          BotonGrande(texto: 'Hacer la práctica', onPressed: notifier.empezarPractica),
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

  final ColorTren objetivo;

  @override
  Widget build(BuildContext context) {
    // Sobre el fondo claro, los colores muy claros se leen con su tono oscuro.
    final tinta = objetivo.cuerpo.computeLuminance() > 0.45 ? objetivo.sombra : objetivo.cuerpo;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.naranjaSuave,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borde, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Cuando pase el tren '),
                TextSpan(text: objetivo.etiqueta, style: TextStyle(color: tinta)),
                const TextSpan(text: ', toque el botón grande.'),
              ],
            ),
            style: AppTheme.titulo(25, color: AppColors.naranjaTexto, height: 1.25),
          ),
          const SizedBox(height: 10),
          Text(
            'Van a pasar trenes de varios colores. Solo el ${objetivo.etiqueta} cuenta.',
            style: AppTheme.cuerpo(18, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Ejemplo extends StatelessWidget {
  const _Ejemplo({required this.objetivo, required this.distractor});

  final ColorTren objetivo;
  final ColorTren distractor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Column(
          children: [
            _Muestra(
              locomotora: objetivo,
              vagones: [objetivo, ColorTren.relleno],
              etiqueta: 'este sí',
              icono: Icons.check_circle_rounded,
              color: AppColors.verde,
            ),
            const Divider(height: 26, color: AppColors.borde),
            _Muestra(
              locomotora: distractor,
              vagones: [distractor, ColorTren.relleno],
              etiqueta: 'este no',
              icono: Icons.cancel_rounded,
              color: AppColors.rojo,
            ),
          ],
        ),
      );
}

class _Muestra extends StatelessWidget {
  const _Muestra({
    required this.locomotora,
    required this.vagones,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  final ColorTren locomotora;
  final List<ColorTren> vagones;
  final String etiqueta;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TrenDibujo(locomotora: locomotora, vagones: vagones, conEtiqueta: true),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icono, color: color, size: 26),
          const SizedBox(width: 4),
          Text(etiqueta, style: AppTheme.titulo(18, color: color)),
        ],
      );
}
