import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';
import 'package:vivamente/features/juegos/widgets/selector_dificultad.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/banco_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/nivel_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/pregunta.dart';
import 'package:vivamente/features/memoria/para_que_sirve/para_que_sirve_game.dart';
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';
import 'package:vivamente/features/memoria/para_que_sirve/widgets/tarjeta_objeto.dart';

/// Consigna, ejemplo y nivel antes de la práctica.
class ObjetosInstruccionesView extends ConsumerWidget {
  const ObjetosInstruccionesView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(paraQueSirveProvider);
    final leyendo = ref.watch(lecturaProvider) == EstadoLectura.leyendo;
    final notifier = ref.read(paraQueSirveProvider.notifier);
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
      cabecera: CabeceraJuego(juegoId: ParaQueSirveGame.idJuego, onAtras: onBack),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Consigna(nivel: nivel),
            const SizedBox(height: 22),
            const EtiquetaCampo('Así se ve'),
            const SizedBox(height: 8),
            _Ejemplo(nivel: nivel),
            const SizedBox(height: 14),
            const _Nota(
              icono: Icons.lightbulb_outline_rounded,
              texto: 'Después de cada respuesta verá una explicación. '
                  'No hay límite de tiempo: lea con calma y toque Siguiente.',
            ),
            const SizedBox(height: 22),
            const SelectorDificultad(juegoId: ParaQueSirveGame.idJuego),
            const SizedBox(height: 14),
            Text(
              'Nivel ${nivel.dificultad.nivel} · ${_textoNivel(nivel)} · ${NivelObjetos.preguntas} preguntas. '
              'Antes hay una práctica con ${NivelObjetos.preguntasPractica}.',
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

  static String _textoNivel(NivelObjetos n) => switch (n.tipo) {
        TipoPregunta.funcion => 'para qué sirve cada objeto',
        TipoPregunta.lugar => 'dónde va cada objeto',
        TipoPregunta.pareja => 'con qué se relaciona',
      };
}

class _Consigna extends StatelessWidget {
  const _Consigna({required this.nivel});

  final NivelObjetos nivel;

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
              'VERÁ UN OBJETO Y UNA PREGUNTA',
              style: AppTheme.mono(14, color: AppColors.naranjaTexto, letterSpacing: 1, weight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              switch (nivel.tipo) {
                TipoPregunta.funcion => 'Elija para qué sirve el objeto.',
                TipoPregunta.lugar => 'Elija dónde va el objeto: en la cocina, el baño, el armario…',
                TipoPregunta.pareja => 'Elija el objeto con el que se relaciona.',
              },
              style: AppTheme.titulo(24, color: AppColors.naranjaTexto, height: 1.25),
            ),
          ],
        ),
      );
}

/// Un objeto del nivel con su pregunta y la respuesta correcta marcada.
/// Estos ejemplos no salen como pregunta.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo({required this.nivel});

  final NivelObjetos nivel;

  @override
  Widget build(BuildContext context) {
    final (objeto, respuesta) = switch (nivel.tipo) {
      TipoPregunta.funcion => (BancoObjetos.ejemplo.objeto, Opcion(BancoObjetos.ejemplo.funcion)),
      TipoPregunta.lugar => (
          BancoObjetos.ejemploLugar.objeto,
          Opcion(BancoObjetos.ejemploLugar.lugar.etiqueta, icono: BancoObjetos.ejemploLugar.lugar.icono),
        ),
      TipoPregunta.pareja => (
          BancoObjetos.ejemploPareja.objeto,
          Opcion(BancoObjetos.ejemploPareja.pareja.nombre, emoji: BancoObjetos.ejemploPareja.pareja.emoji),
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borde, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TarjetaObjeto(objeto: objeto, compacta: true),
          const SizedBox(height: 10),
          Text(nivel.enunciado, style: AppTheme.titulo(20)),
          const SizedBox(height: 10),
          BotonOpcion(numero: 1, opcion: respuesta, estado: EstadoOpcion.correcta, onTap: null),
        ],
      ),
    );
  }
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
