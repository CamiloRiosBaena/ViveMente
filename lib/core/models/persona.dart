import 'package:cloud_firestore/cloud_firestore.dart';

//Tipo de documento, posibles para expandir el aplicativo 
enum TipoDocumento { cc, ce, ppt, ti }

class DatosPersonales {
  const DatosPersonales({
    required this.tipoDoc,
    required this.numero,
    required this.nombreCompleto,
  });

  final TipoDocumento tipoDoc;
  final String numero; 
  final String nombreCompleto;

  Map<String, dynamic> toMap() =>
      {'tipoDoc': tipoDoc.name, 'numero': numero, 'nombreCompleto': nombreCompleto};
}

class Adulto {
  const Adulto ({
    required this.id,
    required this.sexo,
    required this.edad,
    required this.fechaRegistro,
    required this.fechaAutorizacionDatos,
    this.nombreCompleto, 
  });

  final String id;
  final String sexo;
  final int edad;
  final DateTime fechaRegistro;
  final DateTime fechaAutorizacionDatos;
  final String? nombreCompleto;

  factory Adulto.fromMap(String id, Map<String, dynamic> d, {String? nombreCompleto}) => Adulto(
        id: id,
        sexo: d['sexo'] as String,
        edad: d['edad'] as int,
        fechaRegistro: (d['fechaRegistro'] as Timestamp).toDate(),
        fechaAutorizacionDatos: (d['fechaAutorizacionDatos'] as Timestamp).toDate(),
        nombreCompleto: nombreCompleto,
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