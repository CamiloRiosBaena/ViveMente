import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/localidad.dart';
import 'package:vivamente/core/services/localidades_local.dart';
import 'package:vivamente/core/services/ubicacion.dart';

/// Localidades habilitadas para aplicar la valoración. Las vistas solo conocen
/// este contrato; con Firestore basta otra implementación y cambiar el provider.
abstract class LocalidadesRepository {
  /// Localidad habilitada que cubre ese punto, o `null` si ninguna lo cubre.
  Future<Localidad?> localidadEn(double latitud, double longitud);
}

final localidadesProvider = Provider<LocalidadesRepository>(
  (ref) => LocalidadesLocal(ref.read(lectorUbicacionProvider)),
);
