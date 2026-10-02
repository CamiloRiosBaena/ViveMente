import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/fluidez_verbal/comun/transcripcion.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/evaluador_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/metricas_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/nivel_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/sorteo_letra.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/palabras_letra_game.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

/// La presentación muestra la letra en grande unos segundos antes de que
/// empiece a correr el tiempo. Al acabar la ronda, en la [revision] se
/// confirman las palabras antes de ver el resultado.
enum FasePalabras { instrucciones, presentacion, jugando, revision, resultado }

class PalabrasLetraState {
  const PalabrasLetraState({
    required this.nivel,
    required this.letra,
    required this.metricas,
    this.fase = FasePalabras.instrucciones,
    this.escuchando = false,
    this.conectado = false,
    this.transcurrido = Duration.zero,
    this.pausado = false,
    this.avisoDictado = 0,
    this.oidas = const [],
    this.respuestas = const [],
    this.veredictos = const [],
    this.ajustes = const [],
    this.resultado,
  });

  final NivelPalabras nivel;

  /// Letra con la que deben empezar las palabras de este intento.
  final String letra;
  final FasePalabras fase;

  /// Si el micrófono está encendido. Queda así, aunque haya silencios, hasta
  /// que el adulto lo apague o acabe la ronda.
  final bool escuchando;

  /// Si el reconocedor está oyendo de verdad. Con el micrófono encendido
  /// puede no estarlo un momento, mientras se vuelve a abrir tras un silencio.
  final bool conectado;

  final Duration transcurrido;
  final bool pausado;

  /// Sube cada vez que el micrófono no pudo abrirse, para avisar una vez.
  final int avisoDictado;

  /// Durante la ronda, lo que se lleva dicho o escrito, sin evaluar.
  final List<String> oidas;

  /// Desde la revisión: las respuestas de la ronda, su veredicto y lo que
  /// decidió quien revisó, en el mismo orden.
  final List<RespuestaOida> respuestas;
  final List<Veredicto> veredictos;
  final List<Ajuste> ajustes;

  /// Cifras de la ronda, desde la revisión.
  final MetricasPalabras metricas;

  /// Listo al confirmar la revisión.
  final ResultadoJuego? resultado;

  bool get jugando => fase == FasePalabras.jugando;

  /// Segundos que faltan para que empiece la ronda, durante la presentación.
  int get cuentaAtras {
    final r = PalabrasLetraNotifier.presentacion - transcurrido;
    return r.isNegative ? 0 : (r.inMilliseconds / 1000).ceil();
  }

  Duration get restante {
    final r = nivel.duracion - transcurrido;
    return r.isNegative ? Duration.zero : r;
  }

  /// Redondea hacia arriba para no mostrar 00:00 con tiempo.
  String get textoTiempo => formatoReloj(Duration(seconds: (restante.inMilliseconds / 1000).ceil()));

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion => 'Cuando empiece verá una letra. '
      'Diga o escriba todas las palabras que se le ocurran que empiecen con esa letra. '
      'Por ejemplo, con la letra ${NivelPalabras.letraEjemplo}: '
      '${NivelPalabras.palabrasEjemplo.take(3).join(', ').toLowerCase()}. '
      'No valen nombres de personas ni de lugares, ni repetir una palabra en plural. '
      'Puede escribirlas y enviarlas, o encender el micrófono y decirlas en voz alta: '
      'lo que diga se va anotando, y el micrófono sigue escuchando hasta que lo apague. '
      'Al terminar podrá revisar las palabras. '
      'Tiene ${nivel.textoDuracion}. Nivel ${nivel.dificultad.nivel}. '
      'Cuando esté listo, toque Empezar.';

  PalabrasLetraState copyWith({
    FasePalabras? fase,
    bool? escuchando,
    bool? conectado,
    Duration? transcurrido,
    bool? pausado,
    int? avisoDictado,
    List<String>? oidas,
    List<RespuestaOida>? respuestas,
    List<Veredicto>? veredictos,
    List<Ajuste>? ajustes,
    MetricasPalabras? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      PalabrasLetraState(
        nivel: nivel,
        letra: letra,
        fase: fase ?? this.fase,
        escuchando: escuchando ?? this.escuchando,
        conectado: conectado ?? this.conectado,
        transcurrido: transcurrido ?? this.transcurrido,
        pausado: pausado ?? this.pausado,
        avisoDictado: avisoDictado ?? this.avisoDictado,
        oidas: oidas ?? this.oidas,
        respuestas: respuestas ?? this.respuestas,
        veredictos: veredictos ?? this.veredictos,
        ajustes: ajustes ?? this.ajustes,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «Palabras con una letra». La vista solo pinta este estado y llama
/// a sus métodos.
///
/// Durante la ronda solo se anota lo que se dice o escribe; se evalúa todo
/// junto al terminar. Así cuenta la versión final del reconocedor de voz,
/// que corrige lo que va oyendo, y nada interrumpe al adulto mientras habla.
class PalabrasLetraNotifier extends Notifier<PalabrasLetraState> {
  static const _intervalo = Duration(milliseconds: 100);

  /// Cuánto se muestra la letra en grande antes de empezar.
  static const presentacion = Duration(seconds: 3);

  /// Pausa antes de reabrir el micrófono cuando el reconocedor se cierra solo.
  static const _esperaReapertura = Duration(milliseconds: 300);

  /// Al terminar, cuánto se espera a que el reconocedor entregue lo último
  /// que oyó.
  static const _esperaFinal = Duration(milliseconds: 1500);

  static const _id = PalabrasLetraGame.idJuego;

  late Reloj _reloj;
  late Dictado _dictado;
  Timer? _timer;
  Timer? _reapertura;
  final _transcripcion = Transcripcion();

  /// Sube al cerrar una ronda, para ignorar lo que el dictado entregue tarde.
  int _ronda = 0;

  /// Segmento de la escucha abierta, y los que ya recibieron su resultado
  /// final.
  int? _escucha;
  final _finales = <int>{};
  Completer<void>? _esperandoFinal;

  /// Mientras se espera lo último del dictado al terminar.
  bool _terminando = false;

  @override
  PalabrasLetraState build() {
    _reloj = ref.watch(relojProvider);
    _dictado = ref.read(dictadoProvider);
    final voz = ref.read(vozProvider);
    _dictado.alTerminar = _alCerrarseMicrofono;
    ref.onDispose(() {
      _detenerTimer();
      voz.callar();
      _dictado.alTerminar = null;
      _cerrarMicrofono();
    });

    // Se escucha en vez de observar: al registrar un nivel se elige solo el
    // siguiente, y eso no debe borrar la pantalla de resultados.
    ref.listen(dificultadJuegoProvider(_id), (_, d) {
      if (state.fase == FasePalabras.instrucciones) state = _nuevoIntento(d);
    });
    return _nuevoIntento(ref.read(dificultadJuegoProvider(_id)));
  }

  PalabrasLetraState _nuevoIntento(Dificultad dificultad) {
    final nivel = NivelPalabras.de(dificultad);
    return PalabrasLetraState(
      nivel: nivel,
      letra: ref.read(sorteoLetraProvider).elegir(nivel),
      metricas: MetricasPalabras(meta: nivel.meta),
    );
  }

  bool get _activo => state.jugando && !state.pausado && !_terminando;

  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  /// Botón «Empezar»: la letra se muestra en grande y se dice en voz alta;
  /// pasada la [presentacion] empieza a correr el tiempo de la ronda.
  void iniciar() {
    if (state.fase != FasePalabras.instrucciones) return;
    _reloj
      ..reiniciar()
      ..iniciar();
    state = state.copyWith(fase: FasePalabras.presentacion, transcurrido: Duration.zero);
    ref.read(lecturaProvider.notifier).leer('Su letra es la ${state.letra}.');
    _iniciarTimer();
  }

  /// Cierra la presentación y arranca la ronda desde cero.
  void _empezarRonda() {
    ref.read(lecturaProvider.notifier).detener();
    _transcripcion.limpiar();
    _finales.clear();
    _escucha = null;
    _reloj
      ..reiniciar()
      ..iniciar();
    state = state.copyWith(fase: FasePalabras.jugando, transcurrido: Duration.zero, oidas: const []);
  }

  /// Palabra escrita: se anota al enviarla. Devuelve `false` si no se tomó
  /// (ronda en pausa o texto vacío), para que la vista no borre el campo.
  bool anadir(String texto) {
    if (!_activo || texto.trim().isEmpty) return false;
    _transcripcion.poner(_transcripcion.abrir(dictado: false), texto, _reloj.transcurrido, esFinal: true);
    state = state.copyWith(oidas: _oidas());
    return true;
  }

  List<String> _oidas() => [for (final r in _transcripcion.respuestas(EvaluadorPalabras.cortar)) r.texto];

  /// Enciende o apaga el micrófono. Encendido, se reabre solo cada vez que el
  /// reconocedor se cierra por un silencio.
  Future<void> alternarMicrofono() async {
    if (!_activo) return;
    if (state.escuchando) {
      state = state.copyWith(escuchando: false, conectado: false);
      _reapertura?.cancel();
      return _dictado.detener();
    }
    state = state.copyWith(escuchando: true);
    await _abrirMicrofono();
  }

  /// Cada escucha va a su propio segmento: lo que llegue tarde de una
  /// anterior no se mezcla ni se cuenta dos veces.
  Future<void> _abrirMicrofono() async {
    final ronda = _ronda;
    final segmento = _escucha = _transcripcion.abrir(dictado: true);
    final empezo = await _dictado.escuchar(alOir: (texto, esFinal) => _oir(ronda, segmento, texto, esFinal));
    if (!ref.mounted) return;
    if (ronda != _ronda || !state.escuchando || !_activo) {
      // La ronda acabó, o se apagó o pausó mientras se abría.
      if (empezo && ronda != _ronda) _dictado.detener();
      return;
    }
    state = empezo
        ? state.copyWith(conectado: _escucha == segmento)
        : state.copyWith(escuchando: false, avisoDictado: state.avisoDictado + 1);
  }

  /// El reconocedor se cerró (silencio, límite del equipo o error). Si el
  /// micrófono sigue encendido y la ronda corre, se vuelve a abrir.
  void _alCerrarseMicrofono() {
    if (!ref.mounted) return;
    if (state.conectado) state = state.copyWith(conectado: false);
    if (!state.escuchando || !_activo) return;
    _reapertura?.cancel();
    _reapertura = Timer(_esperaReapertura, () {
      if (ref.mounted && state.escuchando && _activo) _abrirMicrofono();
    });
  }

  /// Apaga el micrófono y descarta lo que llegue tarde de esta ronda.
  void _cerrarMicrofono() {
    _ronda++;
    _escucha = null;
    _reapertura?.cancel();
    _dictado.detener();
  }

  /// Lo que el reconocedor lleva oído en una escucha reemplaza lo anterior
  /// de esa escucha. También cuenta lo que llega en pausa: se dijo antes.
  void _oir(int ronda, int segmento, String texto, bool esFinal) {
    if (!ref.mounted || ronda != _ronda) return;
    _transcripcion.poner(segmento, texto, _reloj.transcurrido, esFinal: esFinal);
    if (esFinal) {
      _finales.add(segmento);
      if (segmento == _escucha && !(_esperandoFinal?.isCompleted ?? true)) _esperandoFinal!.complete();
    }
    state = state.copyWith(oidas: _oidas());
  }

  /// Botón «Terminar»: cierra la ronda antes de que acabe el tiempo.
  Future<void> terminar() async {
    if (!state.jugando || _terminando) return;
    await _terminar(_reloj.transcurrido);
  }

  /// En pausa el micrófono se cierra, pero sigue encendido: al reanudar se
  /// vuelve a abrir.
  void pausar() {
    if (!state.jugando || state.pausado || _terminando) return;
    _detenerTimer();
    _reloj.detener();
    state = state.copyWith(pausado: true, conectado: false, transcurrido: _reloj.transcurrido);
    _reapertura?.cancel();
    if (state.escuchando) _dictado.detener();
  }

  void reanudar() {
    if (!state.jugando || !state.pausado) return;
    state = state.copyWith(pausado: false);
    _reloj.iniciar();
    _iniciarTimer();
    if (state.escuchando) _abrirMicrofono();
  }

  /// Quien revisa cambia lo que se hace con la respuesta [i]; los
  /// veredictos y las cifras se recalculan.
  void ajustar(int i, Ajuste ajuste) {
    if (state.fase != FasePalabras.revision || i < 0 || i >= state.ajustes.length) return;
    state = _evaluado(state.copyWith(ajustes: [...state.ajustes]..[i] = ajuste));
  }

  /// Botón de la revisión: guarda el resultado del nivel sin esperar a que
  /// salga de la pantalla; así «Repetir» no lo pierde.
  void confirmar() {
    if (state.fase != FasePalabras.revision) return;
    final resultado = state.metricas.aResultado(state.nivel.dificultad);
    state = state.copyWith(fase: FasePalabras.resultado, resultado: () => resultado);
    ref.read(resultadosProvider.notifier).registrar(_id, state.nivel.dificultad, resultado);
  }

  /// Otra ronda del mismo nivel, con otra letra.
  void repetir() {
    final dificultad = state.nivel.dificultad;
    _detenerTimer();
    _reloj.reiniciar();
    _cerrarMicrofono();
    // Primero se elige el nivel (el listener lo ignora fuera de las
    // instrucciones) y luego se arma el intento nuevo.
    ref.read(dificultadJuegoProvider(_id).notifier).elegir(dificultad);
    state = _nuevoIntento(dificultad);
  }

  /// Avanza el cronómetro y cierra la ronda al acabar el tiempo. Lo llama el
  /// timer.
  @visibleForTesting
  void actualizar() {
    if (state.fase == FasePalabras.presentacion) return _actualizarPresentacion();
    if (!_activo) return;
    final t = _reloj.transcurrido;
    if (t >= state.nivel.duracion) {
      unawaited(_terminar(state.nivel.duracion));
      return;
    }
    final s = state.copyWith(transcurrido: t);
    // Solo se avisa a la vista cuando cambia el segundo.
    if (s.textoTiempo != state.textoTiempo) state = s;
  }

  void _actualizarPresentacion() {
    final t = _reloj.transcurrido;
    if (t >= presentacion) return _empezarRonda();
    final s = state.copyWith(transcurrido: t);
    if (s.cuentaAtras != state.cuentaAtras) state = s;
  }

  /// Apaga el micrófono y espera, un momento como mucho, lo último que oyó:
  /// lo dicho justo antes de terminar cuenta; lo escrito sin enviar, no.
  /// Luego evalúa todo y pasa a la revisión (o al resultado, si no se dijo
  /// nada).
  Future<void> _terminar(Duration t) async {
    _terminando = true;
    _detenerTimer();
    _reloj.detener();
    _reapertura?.cancel();
    final escucha = _escucha;
    final esperar = state.conectado && escucha != null && !_finales.contains(escucha);
    state = state.copyWith(transcurrido: t, escuchando: false, conectado: false);
    if (esperar) {
      final fin = _esperandoFinal = Completer<void>();
      await _dictado.detener();
      await fin.future.timeout(_esperaFinal, onTimeout: () {});
      if (!ref.mounted) return;
    }
    _cerrarMicrofono();
    _terminando = false;

    final respuestas = _transcripcion.respuestas(EvaluadorPalabras.cortar);
    state = _evaluado(state.copyWith(
      fase: FasePalabras.revision,
      oidas: const [],
      respuestas: respuestas,
      ajustes: List.filled(respuestas.length, Ajuste.ninguno),
    ));
    if (respuestas.isEmpty) confirmar();
  }

  PalabrasLetraState _evaluado(PalabrasLetraState s) {
    final veredictos = EvaluadorPalabras.evaluarTodas([for (final r in s.respuestas) r.texto], s.letra, s.ajustes);
    return s.copyWith(
      veredictos: veredictos,
      metricas: MetricasPalabras.contar(
        meta: s.nivel.meta,
        respuestas: s.respuestas,
        veredictos: veredictos,
        ajustes: s.ajustes,
        tiempo: s.transcurrido,
      ),
    );
  }

  void _iniciarTimer() => _timer = Timer.periodic(_intervalo, (_) => actualizar());

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Uno solo en toda la app: recuerda la última letra de cada nivel.
final sorteoLetraProvider = Provider<SorteoLetra>((_) => SorteoLetra());

final palabrasLetraProvider =
    NotifierProvider.autoDispose<PalabrasLetraNotifier, PalabrasLetraState>(PalabrasLetraNotifier.new);
