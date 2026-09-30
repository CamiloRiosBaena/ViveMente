import 'package:flutter/widgets.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/banco_objetos.dart';

/// Una de las tres respuestas. Lleva texto y, según el nivel, un emoji
/// (parejas) o un ícono (lugares).
class Opcion {
  const Opcion(this.texto, {this.emoji, this.icono});

  final String texto;
  final String? emoji;
  final IconData? icono;

  @override
  bool operator ==(Object other) => other is Opcion && other.texto == texto;

  @override
  int get hashCode => texto.hashCode;
}

/// Un objeto con su pregunta, las opciones mezcladas y la explicación que se
/// muestra tras responder.
class Pregunta {
  const Pregunta({
    required this.objeto,
    required this.enunciado,
    required this.opciones,
    required this.correcta,
    required this.explicacion,
  });

  final Objeto objeto;

  /// «¿Para qué sirve?», «¿Dónde va?», «¿Con cuál se relaciona?».
  final String enunciado;
  final List<Opcion> opciones;

  /// Índice de la opción correcta.
  final int correcta;
  final String explicacion;

  Opcion get respuesta => opciones[correcta];

  /// Lo que se lee en voz alta: el objeto, la pregunta y las opciones.
  String get lectura => '${objeto.nombre}. $enunciado '
      '${[for (var i = 0; i < opciones.length; i++) 'Opción ${i + 1}: ${opciones[i].texto}.'].join(' ')}';
}
