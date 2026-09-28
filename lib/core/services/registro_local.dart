import 'package:vivamente/core/models/persona.dart';
import 'package:vivamente/core/services/registro_repository.dart';

/// Registro en memoria con datos de muestra, mientras no hay Firestore.
class RegistroLocal implements RegistroRepository {
  // La cédula es el id: así la búsqueda es directa.
  final _evaluadores = <String, Evaluador>{
    '52100200': const Evaluador(id: '52100200', nombreCompleto: 'Laura Mejía'),
  };

  final _adultos = <String, Adulto>{
    '41238950': Adulto(
      id: '41238950',
      sexo: 'Femenino',
      edad: 74,
      fechaRegistro: DateTime(2026, 9, 1),
      fechaAutorizacionDatos: DateTime(2026, 9, 1),
      datos: const DatosPersonales(
        tipoDoc: TipoDocumento.cc,
        numero: '41238950',
        nombres: 'Rosa Elena',
        apellidos: 'Gómez Prada',
      ),
    ),
  };

  @override
  Future<Evaluador?> buscarEvaluador(String cedula) async => _evaluadores[cedula];

  @override
  Future<Evaluador> registrarEvaluador(String cedula, String nombreCompleto) async =>
      _evaluadores[cedula] = Evaluador(id: cedula, nombreCompleto: nombreCompleto);

  @override
  Future<Adulto?> buscarAdulto(String cedula) async => _adultos[cedula];

  @override
  Future<Adulto> guardarAdulto(Adulto adulto) async => _adultos[adulto.id] = adulto;
}
