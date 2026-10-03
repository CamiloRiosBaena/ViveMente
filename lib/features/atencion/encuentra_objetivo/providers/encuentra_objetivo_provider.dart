import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/encuentra_objetivo_game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/generador_cuadricula.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/metricas_busqueda.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/nivel_busqueda.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

enum FaseBusqueda { instrucciones, practica, finPractica, prueba, resultado }

/// Refuerzo breve tras cada toque.
enum RetroBusqueda { ninguna, correcto, incorrecto }

class EncuentraObjetivoState {
  const EncuentraObjetivoState({
    required this.nivel,
    required this.objetivo,
    required this.casillas,
    required this.ejemplos,
    required this.metricas,
    NivelBusqueda? rejilla,
    this.fase = FaseBusqueda.instrucciones,
    this.encontradas = const {},
    this.transcurrido = Duration.zero,
    this.pausado = false,
    this.retro = RetroBusqueda.ninguna,
    this.retroId = 0,
    this.casillaError,
    this.resultado,
  }) : rejilla = rejilla ?? nivel;

  final NivelBusqueda nivel;

  /// Medidas de la cuadrícula en pantalla: la corta en la práctica, la del
  /// nivel en la ronda medida.
  final NivelBusqueda rejilla;

  /// Lo que hay que encontrar en este intento.
  final Objetivo objetivo;
  final List<Estimulo> casillas;

  /// Dos distractores para el ejemplo «estos no» de las instrucciones.
  final List<Estimulo> ejemplos;

  final FaseBusqueda fase;

  /// Índices de las casillas objetivo ya encontradas.
  final Set<int> encontradas;

  final Duration transcurrido;
  final bool pausado;
  final RetroBusqueda retro;

  /// Sube con cada toque, para que dos refuerzos iguales se animen los dos.
  final int retroId;

  /// Casilla del último toque equivocado, marcada mientras dura el refuerzo.
  final int? casillaError;
  final MetricasBusqueda metricas;

  /// Listo al terminar la ronda.
  final ResultadoJuego? resultado;

  /// En una ronda con cuadrícula: la práctica o la medida.
  bool get jugando => fase == FaseBusqueda.practica || fase == FaseBusqueda.prueba;
  bool get enPractica => fase == FaseBusqueda.practica;

  /// Tiempo máximo de la ronda en curso.
  Duration get limite => enPractica ? NivelBusqueda.duracionPractica : NivelBusqueda.duracion;

  Duration get restante {
    final r = limite - transcurrido;
    return r.isNegative ? Duration.zero : r;
  }

  /// «TIEMPO: 01:43». Redondea hacia arriba para no mostrar 00:00 con tiempo.
  String get textoTiempo => formatoReloj(Duration(seconds: (restante.inMilliseconds / 1000).ceil()));

  /// Fracción de tiempo que queda.
  double get tiempoRestante => restante.inMilliseconds / limite.inMilliseconds;

  bool esObjetivo(int i) => casillas[i] == objetivo.estimulo;

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion => 'Encuentre ${objetivo.todos}. '
      'Toque solo esas; las demás no cuentan. '
      'Tiene 2 minutos. Nivel ${nivel.dificultad.nivel}. '
      'Antes hay una práctica corta. Cuando esté listo, toque Hacer la práctica.';

  EncuentraObjetivoState copyWith({
    FaseBusqueda? fase,
    Set<int>? encontradas,
    Duration? transcurrido,
    bool? pausado,
    RetroBusqueda? retro,
    int? retroId,
    int? Function()? casillaError,
    MetricasBusqueda? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      EncuentraObjetivoState(
        nivel: nivel,
        objetivo: objetivo,
        casillas: casillas,
        ejemplos: ejemplos,
        rejilla: rejilla,
        fase: fase ?? this.fase,
        encontradas: encontradas ?? this.encontradas,
        transcurrido: transcurrido ?? this.transcurrido,
        pausado: pausado ?? this.pausado,
        retro: retro ?? this.retro,
        retroId: retroId ?? this.retroId,
        casillaError: casillaError != null ? casillaError() : this.casillaError,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «Encuentra el objetivo». La vista solo pinta este estado y llama a
/// sus métodos.
class EncuentraObjetivoNotifier extends Notifier<EncuentraObjetivoState> {
  static const _intervalo = Duration(milliseconds: 100);

  /// La retroalimentación es rápida para no distraer de la búsqueda.
  static const _duracionRetro = Duration(milliseconds: 700);

  static const _id = EncuentraObjetivoGame.idJuego;

  late Reloj _reloj;
  Timer? _timer;
  Duration _retroHasta = Duration.zero;

  @override
  EncuentraObjetivoState build() {
    _reloj = ref.watch(relojProvider);
    final voz = ref.read(vozProvider);
    ref.onDispose(() {
      _detenerTimer();
      voz.callar();
    });

    // Se escucha en vez de observar: al registrar un nivel se elige solo el
    // siguiente, y eso no debe borrar la pantalla de resultados.
    ref.listen(dificultadJuegoProvider(_id), (_, d) {
      if (state.fase == FaseBusqueda.instrucciones) state = _nuevoIntento(d);
    });
    return _nuevoIntento(ref.read(dificultadJuegoProvider(_id)));
  }

  GeneradorCuadricula get _generador => ref.read(generadorCuadriculaProvider);

  /// Objetivo y cuadrícula nuevos, sin repetir el objetivo anterior del nivel.
  EncuentraObjetivoState _nuevoIntento(Dificultad dificultad) {
    final nivel = NivelBusqueda.de(dificultad);
    final objetivo = _generador.elegirObjetivo(dificultad);
    return _armar(
      FaseBusqueda.instrucciones,
      nivel: nivel,
      objetivo: objetivo,
      rejilla: nivel,
      ejemplos: _generador.ejemplos(nivel, objetivo),
    );
  }

  /// Estado limpio con una cuadrícula nueva de [rejilla] para el mismo objetivo.
  EncuentraObjetivoState _armar(
    FaseBusqueda fase, {
    required NivelBusqueda nivel,
    required Objetivo objetivo,
    required NivelBusqueda rejilla,
    required List<Estimulo> ejemplos,
  }) {
    final casillas = _generador.cuadricula(rejilla, objetivo);
    return EncuentraObjetivoState(
      nivel: nivel,
      objetivo: objetivo,
      casillas: casillas,
      ejemplos: ejemplos,
      rejilla: rejilla,
      fase: fase,
      metricas: MetricasBusqueda(disponibles: casillas.where((c) => c == objetivo.estimulo).length),
    );
  }

  /// La misma consigna con otra cuadrícula: la corta para practicar o la del nivel.
  EncuentraObjetivoState _otraRonda(FaseBusqueda fase) => _armar(
        fase,
        nivel: state.nivel,
        objetivo: state.objetivo,
        rejilla: fase == FaseBusqueda.practica ? state.nivel.practica : state.nivel,
        ejemplos: state.ejemplos,
      );

  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  /// Ronda corta que no se registra. Se hace desde las instrucciones o, para
  /// repetirla, desde el fin de la práctica.
  void empezarPractica() {
    if (state.fase != FaseBusqueda.instrucciones && state.fase != FaseBusqueda.finPractica) return;
    _arrancar(FaseBusqueda.practica);
  }

  /// Ronda medida de 2 minutos. Solo después de la práctica.
  void empezarPrueba() {
    if (state.fase != FaseBusqueda.finPractica) return;
    _arrancar(FaseBusqueda.prueba);
  }

  /// Del fin de la práctica a las instrucciones, con el mismo objetivo.
  void verInstrucciones() {
    _detenerTimer();
    _reloj.reiniciar();
    state = _otraRonda(FaseBusqueda.instrucciones);
  }

  void _arrancar(FaseBusqueda fase) {
    ref.read(lecturaProvider.notifier).detener();
    _detenerTimer();
    _reloj
      ..reiniciar()
      ..iniciar();
    state = _otraRonda(fase);
    _iniciarTimer();
  }

  /// Otra ronda del mismo nivel, con objetivo y cuadrícula nuevos.
  void repetir() {
    final dificultad = state.nivel.dificultad;
    _detenerTimer();
    _reloj.reiniciar();
    // Primero se elige el nivel (el listener lo ignora fuera de las
    // instrucciones) y luego se arma el intento nuevo.
    ref.read(dificultadJuegoProvider(_id).notifier).elegir(dificultad);
    state = _nuevoIntento(dificultad);
  }

  /// El adulto tocó la casilla [i].
  void tocar(int i) {
    if (!state.jugando || state.pausado || i < 0 || i >= state.casillas.length) return;
    // Un objetivo ya encontrado no vuelve a contar.
    if (state.encontradas.contains(i)) return;

    final t = _reloj.transcurrido;
    _retroHasta = t + _duracionRetro;
    final m = state.metricas;

    if (state.esObjetivo(i)) {
      final encontradas = {...state.encontradas, i};
      state = state.copyWith(
        encontradas: encontradas,
        metricas: m.copyWith(aciertos: m.aciertos + 1),
        retro: RetroBusqueda.correcto,
        retroId: state.retroId + 1,
        casillaError: () => null,
      );
      if (encontradas.length == m.disponibles) _terminar(t);
    } else {
      state = state.copyWith(
        metricas: m.copyWith(errores: m.errores + 1),
        retro: RetroBusqueda.incorrecto,
        retroId: state.retroId + 1,
        casillaError: () => i,
      );
    }
  }

  void pausar() {
    if (!state.jugando || state.pausado) return;
    _detenerTimer();
    _reloj.detener();
    state = state.copyWith(pausado: true, transcurrido: _reloj.transcurrido);
  }

  void reanudar() {
    if (!state.jugando || !state.pausado) return;
    state = state.copyWith(pausado: false);
    _reloj.iniciar();
    _iniciarTimer();
  }

  /// Avanza el cronómetro, apaga el refuerzo y cierra la ronda al acabar el
  /// tiempo. Lo llama el timer.
  @visibleForTesting
  void actualizar() {
    if (!state.jugando || state.pausado) return;
    final t = _reloj.transcurrido;
    if (t >= state.limite) return _terminar(state.limite);

    var s = state;
    if (s.retro != RetroBusqueda.ninguna && t >= _retroHasta) {
      s = s.copyWith(retro: RetroBusqueda.ninguna, casillaError: () => null);
    }
    final textoAntes = state.textoTiempo;
    final cambioRetro = !identical(s, state);
    s = s.copyWith(transcurrido: t);
    // Solo se avisa a la vista cuando cambia el segundo o el refuerzo.
    if (cambioRetro || s.textoTiempo != textoAntes) state = s;
  }

  /// Guarda el resultado del nivel al terminar, sin esperar a que salga de la
  /// pantalla: así «Repetir» no lo pierde. La práctica no se guarda.
  void _terminar(Duration t) {
    _detenerTimer();
    _reloj.detener();
    final metricas = state.metricas.copyWith(tiempo: t);
    if (state.enPractica) {
      state = state.copyWith(
        fase: FaseBusqueda.finPractica,
        transcurrido: t,
        metricas: metricas,
        retro: RetroBusqueda.ninguna,
        casillaError: () => null,
      );
      return;
    }
    final resultado = metricas.aResultado(state.nivel.dificultad);
    state = state.copyWith(
      fase: FaseBusqueda.resultado,
      transcurrido: t,
      metricas: metricas,
      retro: RetroBusqueda.ninguna,
      casillaError: () => null,
      resultado: () => resultado,
    );
    ref.read(resultadosProvider.notifier).registrar(_id, state.nivel.dificultad, resultado);
  }

  void _iniciarTimer() => _timer = Timer.periodic(_intervalo, (_) => actualizar());

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Uno solo en toda la app: recuerda el último objetivo de cada nivel.
final generadorCuadriculaProvider = Provider<GeneradorCuadricula>((_) => GeneradorCuadricula());

final encuentraObjetivoProvider =
    NotifierProvider.autoDispose<EncuentraObjetivoNotifier, EncuentraObjetivoState>(EncuentraObjetivoNotifier.new);
