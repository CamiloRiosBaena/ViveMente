/// Lugar donde se aplica la prueba. Lo deja habilitado el administrador general.
class Localidad {
  const Localidad({
    required this.id,
    required this.nombre,
    required this.zona,
    this.latitud,
    this.longitud,
    this.radioMetros = 300,
  });

  final String id;
  final String nombre;
  final String zona;

  /// Centro del área habilitada. Sin coordenadas la localidad no se puede
  /// verificar por GPS.
  final double? latitud;
  final double? longitud;

  /// Distancia máxima al centro para considerar que se está en la localidad.
  final double radioMetros;
}

/// Punto tomado por GPS al iniciar la valoración y la localidad que le
/// corresponde. Queda en la sesión para registrarlo con los resultados.
class Ubicacion {
  const Ubicacion({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.fecha,
    required this.localidad,
  });

  final double latitud;
  final double longitud;
  final double precisionMetros;
  final DateTime fecha;
  final Localidad localidad;
}
