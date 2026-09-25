import 'package:flutter/widgets.dart';

enum Dominio {
  atencion('Atención', 2),
  memoria('Memoria', 3),
  funcionesEjecutiva('Funciones ejecutivas', 15),
  fluidezVerbal('Fluidez verbal', 3);

  const Dominio(this.etiqueta, this.cantidadActividades);
  final String etiqueta;

  /// Actividades que componen el dominio en la prueba completa.
  final int cantidadActividades;
}

enum Dificultad {
  facil('Fácil'),
  medio('Medio'),
  dificil('Difícil');

  const Dificultad(this.etiqueta);
  final String etiqueta;
}

class ResultadoJuego {
  const ResultadoJuego({
    required this.puntajeBruto,
    required this.puntajeMaximo,
    required this.duracion,
    this.aciertos = 0,
    this.errores = 0,
    this.latenciaPromedio = 0,
  }) : assert(puntajeMaximo > 0, 'El puntaje máximo debe ser mayor a 0');

  final int puntajeBruto;
  final int puntajeMaximo;
  final Duration duracion;
  final int aciertos;
  final int errores;
  final double latenciaPromedio;

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