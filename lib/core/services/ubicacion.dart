import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Coordenadas leídas del GPS.
typedef Punto = ({double latitud, double longitud, double precisionMetros});

/// Por qué no se pudo leer la ubicación; la vista elige el mensaje.
enum FalloUbicacion { servicioApagado, permisoNegado, permisoBloqueado, sinSenal }

class UbicacionException implements Exception {
  const UbicacionException(this.fallo);
  final FalloUbicacion fallo;
}

/// Lectura del GPS del equipo. Va detrás de un contrato para poder probar sin GPS.
abstract class LectorUbicacion {
  /// Pide permiso si hace falta y devuelve la posición actual. Lanza
  /// [UbicacionException] si el GPS está apagado, no hay permiso o no responde.
  Future<Punto> leer();

  /// Abre los ajustes del equipo (permisos o GPS). `false` si no se puede,
  /// por ejemplo en la PWA.
  Future<bool> abrirAjustes(FalloUbicacion fallo);

  /// Metros entre dos puntos.
  double distancia(double lat1, double lng1, double lat2, double lng2);
}

class LectorGps implements LectorUbicacion {
  static const _espera = Duration(seconds: 20);

  @override
  Future<Punto> leer() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const UbicacionException(FalloUbicacion.servicioApagado);
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied) {
      throw const UbicacionException(FalloUbicacion.permisoNegado);
    }
    if (permiso == LocationPermission.deniedForever) {
      throw const UbicacionException(FalloUbicacion.permisoBloqueado);
    }

    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: _espera),
      );
      return (latitud: p.latitude, longitud: p.longitude, precisionMetros: p.accuracy);
    } catch (_) {
      // Sin señal a tiempo, o el navegador negó el permiso en la misma llamada.
      throw const UbicacionException(FalloUbicacion.sinSenal);
    }
  }

  @override
  Future<bool> abrirAjustes(FalloUbicacion fallo) async {
    try {
      return fallo == FalloUbicacion.servicioApagado
          ? await Geolocator.openLocationSettings()
          : await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  @override
  double distancia(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}

final lectorUbicacionProvider = Provider<LectorUbicacion>((_) => LectorGps());
