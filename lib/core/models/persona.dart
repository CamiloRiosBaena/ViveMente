import 'package:cloud_firestore/cloud_firestore.dart';

//Tipo de documento, posibles para expandir el aplicativo 
enum TipoDocumento { cc, ce, ppt, ti }

/// Datos que identifican a una persona. Van aparte del [Adulto] para que el
/// documento con la información clínica no cargue con datos personales.
class DatosPersonales {
  const DatosPersonales({
    required this.tipoDoc,
    required this.numero,
    required this.nombres,
    required this.apellidos,
  });

  final TipoDocumento tipoDoc;
  final String numero; 
  final String nombres;
  final String apellidos;

  String get nombreCompleto => '$nombres $apellidos'.trim();

  /// «Rosa Elena» -> «Rosa».
  String get primerNombre => nombres.trim().split(RegExp(r'\s+')).first;

  /// Primer nombre + primer apellido: «Rosa Elena» «Gómez Prada» -> «RG».
  String get iniciales {
    final n = primerNombre;
    final a = apellidos.trim();
    return ((n.isEmpty ? '' : n[0]) + (a.isEmpty ? '' : a[0])).toUpperCase();
  }

  factory DatosPersonales.fromMap(Map<String, dynamic> d) => DatosPersonales(
        tipoDoc: TipoDocumento.values.byName(d['tipoDoc'] as String),
        numero: d['numero'] as String,
        nombres: d['nombres'] as String,
        apellidos: d['apellidos'] as String,
      );

  Map<String, dynamic> toMap() =>
      {'tipoDoc': tipoDoc.name, 'numero': numero, 'nombres': nombres, 'apellidos': apellidos};
}

class Adulto {
  const Adulto ({
    required this.id,
    required this.sexo,
    required this.edad,
    required this.fechaRegistro,
    required this.fechaAutorizacionDatos,
    this.datos, 
  });

  final String id;
  final String sexo;
  final int edad;
  final DateTime fechaRegistro;
  final DateTime fechaAutorizacionDatos;

  /// Solo en memoria: se resuelve desde la colección de datos personales y por
  /// eso no entra en [toMap].
  final DatosPersonales? datos;

  String get nombreCompleto => datos?.nombreCompleto ?? '';
  String get primerNombre => datos?.primerNombre ?? '';
  String get iniciales => datos?.iniciales ?? '';

  factory Adulto.fromMap(String id, Map<String, dynamic> d, {DatosPersonales? datos}) => Adulto(
        id: id,
        sexo: d['sexo'] as String,
        edad: d['edad'] as int,
        fechaRegistro: (d['fechaRegistro'] as Timestamp).toDate(),
        fechaAutorizacionDatos: (d['fechaAutorizacionDatos'] as Timestamp).toDate(),
        datos: datos,
      );
  
  Map<String, dynamic> toMap() => {
        'sexo': sexo,
        'edad': edad,
        'fechaRegistro': fechaRegistro,
        'fechaAutorizacionDatos': fechaAutorizacionDatos,
      };
} 

class Evaluador {
  const Evaluador({
    required this.id,
    required this.nombreCompleto,
  });

  final String id;
  final String nombreCompleto;
}
