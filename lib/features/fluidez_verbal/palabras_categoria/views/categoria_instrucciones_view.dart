import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/widgets/ficha_categoria.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/juegos/widgets/selector_dificultad.dart';

/// Consigna, ejemplo y nivel antes de la práctica. La categoría de la ronda
/// no se muestra hasta empezar.
class CategoriaInstruccionesView extends ConsumerWidget {
  const CategoriaInstruccionesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(palabrasCategoriaProvider);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final notifier = ref.read(palabrasCategoriaProvider.notifier);
    final categorias = s.nivel.categorias.map((c) => c.nombre.toLowerCase()).join(' o ');

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
      cabecera: CabeceraJuego(juegoId: PalabrasCategoriaGame.idJuego, onAtras: onBack),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Consigna(),
            const SizedBox(height: 22),
            const EtiquetaCampo('Por ejemplo'),
            const SizedBox(height: 8),
            const _Ejemplo(),
            const SizedBox(height: 16),
            const _Nota(
              icono: Icons.mic_none_rounded,
              texto: 'Puede escribirlas y enviarlas, o encender el micrófono y decirlas: '
                  'lo que diga se guarda solo, sin tocar nada más.',
            ),
            const SizedBox(height: 10),
            const _Nota(
              icono: Icons.info_outline_rounded,
              texto: 'Cada palabra se revisa sola: no valen las repetidas ni las de otra categoría.',
            ),
            const SizedBox(height: 22),
            const SelectorDificultad(juegoId: PalabrasCategoriaGame.idJuego),
            const SizedBox(height: 14),
            Text(
              'Nivel ${s.nivel.dificultad.nivel} · $categorias · 60 segundos. '
              'Antes hay una práctica de 20 segundos con colores.',
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
  const _Consigna();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.naranjaSuave,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AL EMPEZAR VERÁ UNA CATEGORÍA',
              style: AppTheme.mono(14, color: AppColors.naranjaTexto, letterSpacing: 1, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Diga o escriba todas las palabras de esa categoría que pueda en 60 segundos.',
              style: AppTheme.titulo(24, color: AppColors.naranjaTexto, height: 1.25),
            ),
          ],
        ),
      );
}

/// Colores, la categoría de la práctica, con algunas palabras que valdrían.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            const EmojiCategoria(Categoria.colores, tamano: 44),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colores', style: AppTheme.mono(14, color: AppColors.textoSuave, letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text('Rojo, azul, verde, amarillo…', style: AppTheme.titulo(20, color: AppColors.texto, height: 1.3)),
                ],
              ),
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
