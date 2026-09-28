import 'package:flutter/widgets.dart';

enum Dominio {
  atencion('Atención', 2, 'Concentrarse y reaccionar a tiempo.'),
  memoria('Memoria', 3, 'Recordar caras, palabras y lugares.'),
  funcionesEjecutiva('Funciones ejecutivas', 15, 'Planear, organizar y resolver.'),
  fluidezVerbal('Fluidez verbal', 3, 'Encontrar y decir palabras.');

  const Dominio(this.etiqueta, this.cantidadActividades, this.descripcion);
  final String etiqueta;

  /// Frase corta bajo el título del dominio.
  final String descripcion;

  /// Actividades que componen el dominio en la prueba completa.
  final int cantidadActividades;
}

enum Dificultad {
  facil('Fácil'),
  medio('Medio'),
  dificil('Difícil');

  const Dificultad(this.etiqueta);
  final String etiqueta;

  /// «Nivel 1», «Nivel 2», «Nivel 3».
  int get nivel => index + 1;
}

class ResultadoJuego {
  const ResultadoJuego({
    required this.puntajeBruto,
    required this.puntajeMaximo,
    required this.duracion,
    this.aciertos = 0,
    this.errores = 0,
    this.omisiones = 0,
    this.latenciaPromedio = 0,
    this.dificultad,
  }) : assert(puntajeMaximo > 0, 'El puntaje máximo debe ser mayor a 0');

  final int puntajeBruto;
  final int puntajeMaximo;
  final Duration duracion;
  final int aciertos;

  /// Respuestas dadas cuando no correspondía (falsas alarmas).
  final int errores;

  /// Estímulos que pedían respuesta y quedaron sin ella.
  final int omisiones;

  /// En milisegundos, solo sobre los aciertos.
  final double latenciaPromedio;

  /// Nivel en que se jugó.
  final Dificultad? dificultad;

  double get puntajeNormalizado => (puntajeBruto / puntajeMaximo * 100).clamp(0, 100).toDouble();
}

typedef FinalizarJuego = void Function(ResultadoJuego resultado);

abstract class Game {
  const Game();

  String get id;             
  String get titulo;
  String get descripcion;     
  String get instrucciones;   
  Dominio get dominio;
  Dificultad get dificultad;
  IconData get icono;
  Duration get duracionEstimada;

  Widget build({
    required FinalizarJuego finalizarJuego,
    required VoidCallback onBack,
  });
}