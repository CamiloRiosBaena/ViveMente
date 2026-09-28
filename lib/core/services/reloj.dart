import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cronómetro de los minijuegos. Va detrás de un contrato para que las pruebas
/// puedan mover el tiempo a mano.
abstract class Reloj {
  Duration get transcurrido;
  bool get corriendo;
  void iniciar();
  void detener();

  /// Vuelve a cero y queda detenido.
  void reiniciar();
}

class RelojCronometro implements Reloj {
  final _cronometro = Stopwatch();

  @override
  Duration get transcurrido => _cronometro.elapsed;

  @override
  bool get corriendo => _cronometro.isRunning;

  @override
  void iniciar() => _cronometro.start();

  @override
  void detener() => _cronometro.stop();

  @override
  void reiniciar() => _cronometro
    ..stop()
    ..reset();
}

/// Un reloj nuevo por cada juego que lo pide.
final relojProvider = Provider.autoDispose<Reloj>((_) => RelojCronometro());
