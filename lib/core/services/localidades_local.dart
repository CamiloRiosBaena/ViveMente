import 'package:vivamente/core/models/localidad.dart';
import 'package:vivamente/core/services/localidades_repository.dart';
import 'package:vivamente/core/services/ubicacion.dart';

/// Localidades de muestra mientras no hay Firestore.
class LocalidadesLocal implements LocalidadesRepository {
  LocalidadesLocal(this._lector);

  final LectorUbicacion _lector;

  /// Mientras no haya localidades reales, un punto fuera de todas se acepta
  /// como provisional para no frenar las pruebas. Con el back en `false`.
  static const aceptarFueraDeZona = true;

  static const provisional = Localidad(
    id: 'provisional',
    nombre: 'Ubicación registrada',
    zona: 'Localidad por asignar',
  );

  final _localidades = const [
    Localidad(
      id: 'unad-jag',
      nombre: 'UNAD · Sede José Acevedo y Gómez',
      zona: 'Bogotá · La Candelaria',
      latitud: 4.6017,
      longitud: -74.0697,
    ),
  ];

  @override
  Future<Localidad?> localidadEn(double latitud, double longitud) async {
    for (final l in _localidades) {
      if (l.latitud == null || l.longitud == null) continue;
      if (_lector.distancia(latitud, longitud, l.latitud!, l.longitud!) <= l.radioMetros) return l;
    }
    return aceptarFueraDeZona ? provisional : null;
  }
}
