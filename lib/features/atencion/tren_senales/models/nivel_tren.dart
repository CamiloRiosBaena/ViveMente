import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';

enum TipoDistractor { contrastantes, parecidos }

/// Parámetros de una ronda según la dificultad. El color objetivo se sortea en
/// cada intento; aquí solo se dice cómo elegir los distractores frente a él.
///
/// - Nivel 1: 30 s, tres distractores muy distintos al objetivo.
/// - Nivel 2: 1 min 30 s, cinco distractores y menos trenes objetivo.
/// - Nivel 3: 3 min, el objetivo pasa poco, los distractores se le parecen y a
///   veces llevan un vagón del color objetivo.
class NivelTren {
  const NivelTren({
    required this.dificultad,
    required this.duracion,
    required this.cruce,
    required this.pausa,
    required this.proporcionObjetivo,
    required this.tipoDistractor,
    required this.cantidadDistractores,
    this.probabilidadVagonEngano = 0,
  });

  final Dificultad dificultad;

  /// Duración de la ronda medida.
  final Duration duracion;

  /// Lo que tarda un tren en atravesar la pantalla. Es también la ventana para
  /// responder a un tren objetivo.
  final Duration cruce;

  /// Vía vacía entre un tren y el siguiente.
  final Duration pausa;

  /// Fracción de trenes que son del color objetivo.
  final double proporcionObjetivo;

  final TipoDistractor tipoDistractor;
  final int cantidadDistractores;

  /// Probabilidad de que un tren distractor lleve un vagón del color objetivo.
  final double probabilidadVagonEngano;

  /// Espera antes del primer tren.
  static const arranque = Duration(seconds: 1);

  /// Trenes de la práctica, siempre la mitad objetivo.
  static const trenesPractica = 4;

  Duration get paso => cruce + pausa;

  /// Colores de locomotora que no cuentan frente a [objetivo].
  List<ColorTren> distractoresPara(ColorTren objetivo) => switch (tipoDistractor) {
        TipoDistractor.contrastantes => PaletaTren.contrastantes(objetivo),
        TipoDistractor.parecidos => PaletaTren.parecidos(objetivo),
      }
          .take(cantidadDistractores)
          .toList();

  /// «30 segundos», «1 minuto y medio», «3 minutos».
  String get etiquetaDuracion {
    final s = duracion.inSeconds;
    if (s < 60) return '$s segundos';
    final min = s ~/ 60;
    final medio = s % 60 == 30;
    final base = min == 1 ? '1 minuto' : '$min minutos';
    return medio ? '$base y medio' : base;
  }

  static const _nivel1 = NivelTren(
    dificultad: Dificultad.facil,
    duracion: Duration(seconds: 30),
    cruce: Duration(milliseconds: 2800),
    pausa: Duration(milliseconds: 700),
    proporcionObjetivo: 0.45,
    tipoDistractor: TipoDistractor.contrastantes,
    cantidadDistractores: 3,
  );

  static const _nivel2 = NivelTren(
    dificultad: Dificultad.medio,
    duracion: Duration(seconds: 90),
    cruce: Duration(milliseconds: 2600),
    pausa: Duration(milliseconds: 600),
    proporcionObjetivo: 0.3,
    tipoDistractor: TipoDistractor.contrastantes,
    cantidadDistractores: 5,
  );

  static const _nivel3 = NivelTren(
    dificultad: Dificultad.dificil,
    duracion: Duration(minutes: 3),
    cruce: Duration(milliseconds: 2400),
    pausa: Duration(milliseconds: 600),
    proporcionObjetivo: 0.2,
    tipoDistractor: TipoDistractor.parecidos,
    cantidadDistractores: 4,
    probabilidadVagonEngano: 0.5,
  );

  static NivelTren de(Dificultad d) => switch (d) {
        Dificultad.facil => _nivel1,
        Dificultad.medio => _nivel2,
        Dificultad.dificil => _nivel3,
      };

  /// La práctica usa los colores del nivel pero con el ritmo pausado del nivel 1.
  NivelTren get practica => NivelTren(
        dificultad: dificultad,
        duracion: duracion,
        cruce: const Duration(milliseconds: 3200),
        pausa: const Duration(milliseconds: 1000),
        proporcionObjetivo: 0.5,
        tipoDistractor: tipoDistractor,
        cantidadDistractores: cantidadDistractores,
        probabilidadVagonEngano: probabilidadVagonEngano,
      );
}
