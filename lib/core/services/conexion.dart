import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de la red del equipo. Va detrás de un contrato para poder probar sin red.
abstract class Conexion {
  /// `true` si el equipo tiene alguna red (wifi, datos, cable…). No garantiza
  /// que haya salida a internet, pero sin red seguro no la hay.
  Future<bool> actual();
  Stream<bool> get cambios;
}

class ConexionRed implements Conexion {
  final _red = Connectivity();

  static bool _hayRed(List<ConnectivityResult> r) => r.any((t) => t != ConnectivityResult.none);

  @override
  Future<bool> actual() async {
    try {
      return _hayRed(await _red.checkConnectivity());
    } catch (_) {
      // Si no se puede consultar, no se molesta con un aviso falso.
      return true;
    }
  }

  @override
  Stream<bool> get cambios => _red.onConnectivityChanged.map(_hayRed).handleError((_) {});
}

final conexionProvider = Provider<Conexion>((_) => ConexionRed());

/// `false` cuando el equipo se queda sin red.
final hayConexionProvider = StreamProvider<bool>((ref) async* {
  final c = ref.watch(conexionProvider);
  yield await c.actual();
  yield* c.cambios.distinct();
});
