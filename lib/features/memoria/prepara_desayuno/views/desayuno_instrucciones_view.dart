import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/core/widgets/pie_con_lectura.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/juegos/widgets/selector_dificultad.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/nivel_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/prepara_desayuno_game.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ficha_alimento.dart';

/// Consigna, pasos y nivel antes de la práctica. La lista de la ronda no se
/// muestra hasta empezar.
class DesayunoInstruccionesView extends ConsumerWidget {
  const DesayunoInstruccionesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(preparaDesayunoProvider);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final notifier = ref.read(preparaDesayunoProvider.notifier);
    final nivel = s.nivel;

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
      cabecera: CabeceraJuego(juegoId: PreparaDesayunoGame.idJuego, onAtras: onBack),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Consigna(conOrden: nivel.conOrden),
            const SizedBox(height: 22),
            const EtiquetaCampo('Así se juega'),
            const SizedBox(height: 10),
            const _Paso(numero: 1, texto: 'Mire la lista del desayuno. Se ocultará en unos segundos.'),
            const _Paso(numero: 2, texto: 'Aparecerá una bandeja con muchos alimentos revueltos.'),
            _Paso(
              numero: 3,
              texto: nivel.conOrden
                  ? 'Toque o arrastre al plato los de la lista, en el mismo orden.'
                  : 'Toque o arrastre al plato los de la lista.',
            ),
            const SizedBox(height: 8),
            const _Ejemplo(),
            const SizedBox(height: 10),
            const _Nota(
              icono: Icons.info_outline_rounded,
              texto: 'Si se equivoca, toque el alimento en el plato para quitarlo. '
                  'Cuando termine, toque Listo.',
            ),
            const SizedBox(height: 22),
            const SelectorDificultad(juegoId: PreparaDesayunoGame.idJuego),
            const SizedBox(height: 14),
            Text(
              'Nivel ${nivel.dificultad.nivel} · ${nivel.textoElementos}'
              '${nivel.conOrden ? ' en orden' : ''} · la lista se ve ${_textoExposicion(nivel)}. '
              'Antes hay una práctica con ${NivelDesayuno.elementosPractica} alimentos.',
              style: AppTheme.cuerpo(18, height: 1.4),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: PieConLectura(
        leyendo: leyendo,
        onEscuchar: notifier.escucharInstruccion,
        principal: BotonGrande(texto: 'Hacer la práctica', onPressed: notifier.empezarPractica),
      ),
    );
  }

  /// «10 segundos», «12 a 15 segundos».
  static String _textoExposicion(NivelDesayuno n) {
    final min = NivelDesayuno.exposicion(n.elementosMin).inSeconds;
    final max = NivelDesayuno.exposicion(n.elementosMax).inSeconds;
    return min == max ? '$min segundos' : '$min a $max segundos';
  }
}

class _Consigna extends StatelessWidget {
  const _Consigna({required this.conOrden});

  final bool conOrden;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.naranjaSuave,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RECUERDE LA LISTA',
                    style: AppTheme.mono(14, color: AppColors.naranjaTexto, letterSpacing: 1, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    conOrden
                        ? 'Ponga en el plato lo del desayuno, en el orden de la lista.'
                        : 'Ponga en el plato lo que necesita para el desayuno.',
                    style: AppTheme.titulo(24, color: AppColors.naranjaTexto, height: 1.25),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Text('🍳', textScaler: TextScaler.noScaling, style: TextStyle(fontSize: 56, height: 1)),
          ],
        ),
      );
}

class _Paso extends StatelessWidget {
  const _Paso({required this.numero, required this.texto});

  final int numero;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.naranja, shape: BoxShape.circle),
              child: Text('$numero', style: AppTheme.titulo(17, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(texto, style: AppTheme.cuerpo(19, color: AppColors.texto, height: 1.35)),
              ),
            ),
          ],
        ),
      );
}

/// Una lista de ejemplo, como la verá al empezar.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POR EJEMPLO', style: AppTheme.mono(13, color: AppColors.textoSuave, letterSpacing: 1)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final a in CatalogoAlimentos.ejemplo) ...[
                  if (a != CatalogoAlimentos.ejemplo.first) const SizedBox(width: 10),
                  Expanded(child: AspectRatio(aspectRatio: 1, child: FichaAlimento(a))),
                ],
              ],
            ),
          ],
        ),
      );
}

class _Nota extends StatelessWidget {
  const _Nota({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icono, size: 24, color: AppColors.naranjaTexto),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(texto, style: AppTheme.cuerpo(18, height: 1.4))),
        ],
      );
}
