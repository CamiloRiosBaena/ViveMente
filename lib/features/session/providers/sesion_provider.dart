import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/models/persona.dart';
import 'package:vivamente/core/services/registro_repository.dart';

/// Actividades hechas por dominio. Sin avance guardado todavía: todo en cero.
/// Saldrá del [Ciclo] del adulto cuando se persista.
final progresoProvider = Provider<Map<Dominio, int>>((_) => {for (final d in Dominio.values) d: 0});

class SesionState {
  const SesionState({this.evaluador, this.cedulaAdulto = '', this.adulto});

  final Evaluador? evaluador;

  /// Cédula escrita en el paso 2; sirve al paso 3 cuando el adulto aún no existe.
  final String cedulaAdulto;
  final Adulto? adulto;

  bool get hayEvaluador => evaluador != null;
  bool get lista => evaluador != null && adulto != null;
}

/// Sesión de la valoración: primero quién la aplica, luego a quién.
class SesionNotifier extends Notifier<SesionState> {
  @override
  SesionState build() => const SesionState();

  RegistroRepository get _registro => ref.read(registroProvider);

  /// Verifica la cédula del evaluador. Si existe, queda en sesión y devuelve `true`;
  /// si no, devuelve `false` y la vista pide el nombre para [registrarEvaluador].
  Future<bool> iniciarConCedula(String cedula) async {
    final e = await _registro.buscarEvaluador(cedula);
    if (e == null) return false;
    state = SesionState(evaluador: e);
    return true;
  }

  Future<void> registrarEvaluador(String cedula, String nombreCompleto) async {
    final e = await _registro.registrarEvaluador(cedula, nombreCompleto);
    state = SesionState(evaluador: e);
  }

  /// Busca al adulto por cédula. Si ya está registrado queda en sesión y devuelve
  /// `true`; si no, devuelve `false` y se sigue al paso de datos.
  Future<bool> elegirAdulto(String cedula) async {
    final a = await _registro.buscarAdulto(cedula);
    state = SesionState(evaluador: state.evaluador, cedulaAdulto: cedula, adulto: a);
    return a != null;
  }

  Future<void> guardarAdulto({
    required String nombres,
    required String apellidos,
    required String sexo,
    required int edad,
  }) async {
    final ahora = DateTime.now();
    final a = await _registro.guardarAdulto(Adulto(
      id: state.cedulaAdulto,
      sexo: sexo,
      edad: edad,
      fechaRegistro: ahora,
      // El evaluador recoge la autorización antes de registrar; cuando exista la
      // pantalla de consentimiento la fecha saldrá de allí.
      fechaAutorizacionDatos: ahora,
      datos: DatosPersonales(
        tipoDoc: TipoDocumento.cc,
        numero: state.cedulaAdulto,
        nombres: nombres,
        apellidos: apellidos,
      ),
    ));
    state = SesionState(evaluador: state.evaluador, cedulaAdulto: state.cedulaAdulto, adulto: a);
  }

  void cerrar() => state = const SesionState();
}

final sesionProvider = NotifierProvider<SesionNotifier, SesionState>(SesionNotifier.new);
