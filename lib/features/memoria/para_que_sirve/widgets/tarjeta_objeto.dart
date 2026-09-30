import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/banco_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/pregunta.dart';

/// Emoji a [tamano], sin que lo agrande la escala de texto del equipo.
class EmojiObjeto extends StatelessWidget {
  const EmojiObjeto(this.emoji, {super.key, required this.tamano});

  final String emoji;
  final double tamano;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: tamano * 1.15,
        child: Center(
          child: Text(
            emoji,
            textScaler: TextScaler.noScaling,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: tamano, height: 1),
          ),
        ),
      );
}

/// «🔑 LLAVE»: el objeto de la pregunta, grande y claro.
class TarjetaObjeto extends StatelessWidget {
  const TarjetaObjeto({super.key, required this.objeto, this.compacta = false});

  final Objeto objeto;

  /// Más pequeña, para el ejemplo de las instrucciones.
  final bool compacta;

  @override
  Widget build(BuildContext context) => Semantics(
        label: objeto.nombre,
        excludeSemantics: true,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: compacta ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borde, width: 2),
          ),
          child: Row(
            children: [
              Container(
                decoration: const BoxDecoration(color: AppColors.naranjaSuave, shape: BoxShape.circle),
                padding: EdgeInsets.all(compacta ? 8 : 12),
                child: EmojiObjeto(objeto.emoji, tamano: compacta ? 40 : 62),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  objeto.nombre.toUpperCase(),
                  style: AppTheme.titulo(compacta ? 24 : 32, color: AppColors.naranjaTexto, height: 1.1),
                ),
              ),
            ],
          ),
        ),
      );
}

enum EstadoOpcion { normal, correcta, incorrecta, apagada }

/// Una de las respuestas: grande, con su número y, según el nivel, el emoji
/// del objeto o el ícono del lugar. Tras responder se pinta de verde la
/// correcta y de rojo la elegida si no lo era.
class BotonOpcion extends StatelessWidget {
  const BotonOpcion({
    super.key,
    required this.numero,
    required this.opcion,
    required this.estado,
    required this.onTap,
  });

  final int numero;
  final Opcion opcion;
  final EstadoOpcion estado;
  final VoidCallback? onTap;

  static const _rojoSuave = Color(0xFFFDE4E1);

  @override
  Widget build(BuildContext context) {
    final (fondo, borde, texto) = switch (estado) {
      EstadoOpcion.normal => (Colors.white, AppColors.borde, AppColors.texto),
      EstadoOpcion.correcta => (AppColors.verdeSuave, AppColors.verde, AppColors.verdeTexto),
      EstadoOpcion.incorrecta => (_rojoSuave, AppColors.rojo, AppColors.rojo),
      EstadoOpcion.apagada => (Colors.white, AppColors.borde, AppColors.textoTenue),
    };
    final marca = switch (estado) {
      EstadoOpcion.correcta => Icons.check_circle_rounded,
      EstadoOpcion.incorrecta => Icons.cancel_rounded,
      EstadoOpcion.normal || EstadoOpcion.apagada => null,
    };
    final radio = BorderRadius.circular(18);
    final emoji = opcion.emoji;
    final icono = opcion.icono;

    return Semantics(
      button: true,
      label: 'Opción $numero: ${opcion.texto}'
          '${estado == EstadoOpcion.correcta ? ', correcta' : estado == EstadoOpcion.incorrecta ? ', incorrecta' : ''}',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: const BoxConstraints(minHeight: 76),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: radio,
          border: Border.all(color: borde, width: estado == EstadoOpcion.normal ? 2 : 3),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radio,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppColors.crema, shape: BoxShape.circle),
                    child: Text('$numero', style: AppTheme.titulo(18, color: AppColors.textoSuave)),
                  ),
                  const SizedBox(width: 12),
                  if (emoji != null) ...[
                    EmojiObjeto(emoji, tamano: 36),
                    const SizedBox(width: 10),
                  ] else if (icono != null) ...[
                    Icon(icono, size: 36, color: estado == EstadoOpcion.apagada ? AppColors.textoTenue : AppColors.naranja),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: Text(opcion.texto, style: AppTheme.titulo(21, color: texto, height: 1.2))),
                  if (marca != null) ...[
                    const SizedBox(width: 8),
                    Icon(marca, color: borde, size: 30),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
