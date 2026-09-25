import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/persona.dart';
import 'package:vivamente/core/services/registro_local.dart';

/// Acceso a evaluadores y adultos. Las vistas solo conocen este contrato, así
/// que al entrar Firestore basta con otra implementación y cambiar el provider.
abstract class RegistroRepository {
  Future<Evaluador?> buscarEvaluador(String cedula);
  Future<Evaluador> registrarEvaluador(String cedula, String nombreCompleto);
  Future<Adulto?> buscarAdulto(String cedula);
  Future<Adulto> guardarAdulto(Adulto adulto);
}

/// Implementación en uso. Con Firebase: `RegistroFirestore()` aquí, o un
/// `overrideWithValue` en el `ProviderScope` para pruebas.
final registroProvider = Provider<RegistroRepository>((_) => RegistroLocal());
