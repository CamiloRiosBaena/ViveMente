import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/generador_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/metricas_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/nivel_desayuno.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/prepara_desayuno_game.dart';

/// Al memorizar la lista está a la vista unos segundos; en la bandeja ya no.
/// La práctica pasa por las mismas dos fases y termina en [finPractica].
enum FaseDesayuno { instrucciones, memorizar, bandeja, finPractica, resultado }

/// Aviso breve tras poner un alimento. En la ronda medida solo se usa
/// [platoLleno]: decir si cada alimento era de la lista sería soplar la
/// respuesta. En la práctica se dicen todos, para aprender el juego.
enum RetroDesayuno { ninguna, bien, noEstaba, otroPuesto, platoLleno }

class PreparaDesayunoState {
  const PreparaDesayunoState({
    required this.nivel,
    required this.lista,
    required this.bandeja,
    required this.metricas,
    this.practica = false,
    this.fase = FaseDesayuno.instrucciones,
    this.transcurrido = Duration.zero,
    this.pausado = false,
    this.retro = RetroDesayuno.ninguna,
    this.retroId = 0,
    this.puestoCorrecto = 0,
    this.resultado,
  });

  final NivelDesayuno nivel;

  /// Lo que hay que recordar, en el orden en que se muestra.
  final List<Alimento> lista;

  /// Alimentos de la bandeja, de izquierda a derecha y de arriba abajo.
  final List<Alimento> bandeja;

  /// Si la ronda es la práctica: lista corta, con refuerzo en cada alimento y
  /// sin registrar el resultado.
  final bool practica;

  final FaseDesayuno fase;
  final Duration transcurrido;
  final bool pausado;
  final RetroDesayuno retro;

  /// Sube con cada aviso, para que dos seguidos se animen los dos.
  final int retroId;

  /// Con [RetroDesayuno.otroPuesto], el puesto (desde 1) donde iba.
  final int puestoCorrecto;

  /// Lleva el plato; las cifras salen de él al terminar.
  final MetricasDesayuno metricas;

  /// Listo al terminar la ronda medida.
  final ResultadoJuego? resultado;

  List<Alimento?> get plato => metricas.plato;

  bool get enRonda => fase == FaseDesayuno.memorizar || fase == FaseDesayuno.bandeja;

  bool get platoLleno => plato.every((a) => a != null);

  bool get platoVacio => plato.every((a) => a == null);

  bool enPlato(Alimento a) => plato.contains(a);

  Duration get exposicion => NivelDesayuno.exposicion(lista.length);

  /// Segundos que faltan para que se oculte la lista.
  int get cuentaAtras {
    final r = exposicion - transcurrido;
    return r.isNegative ? 0 : (r.inMilliseconds / 1000).ceil();
  }

  /// Fracción del tiempo de memorizar que queda.
  double get exposicionRestante =>
      (1 - transcurrido.inMilliseconds / exposicion.inMilliseconds).clamp(0, 1).toDouble();

  /// Lo que se lee en voz alta al mostrar la lista.
  String get textoLista => 'Para preparar el desayuno necesita${nivel.conOrden ? ', en este orden' : ''}: '
      '${enumerarAlimentos(lista)}.';

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion => 'Al empezar verá la lista de lo que necesita para preparar el desayuno. '
      'Mírela bien: se ocultará en unos segundos. '
      'Luego verá una bandeja con muchos alimentos. '
      'Toque o arrastre al plato solo los que estaban en la lista'
      '${nivel.conOrden ? ', en el mismo orden en que aparecieron' : ''}. '
      'Para quitar uno del plato, tóquelo. Cuando termine, toque Listo. '
      'Nivel ${nivel.dificultad.nivel}. Antes hay una práctica corta con '
      '${NivelDesayuno.elementosPractica} alimentos. Cuando esté listo, toque Hacer la práctica.';

  PreparaDesayunoState copyWith({
    FaseDesayuno? fase,
    Duration? transcurrido,
    bool? pausado,
    RetroDesayuno? retro,
    int? retroId,
    int? puestoCorrecto,
    MetricasDesayuno? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      PreparaDesayunoState(
        nivel: nivel,
        lista: lista,
        bandeja: bandeja,
        practica: practica,
        fase: fase ?? this.fase,
        transcurrido: transcurrido ?? this.transcurrido,
        pausado: pausado ?? this.pausado,
        retro: retro ?? this.retro,
        retroId: retroId ?? this.retroId,
        puestoCorrecto: puestoCorrecto ?? this.puestoCorrecto,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «Prepara el desayuno». La vista solo pinta este estado y llama a
/// sus métodos.
class PreparaDesayunoNotifier extends Notifier<PreparaDesayunoState> {
  static const _intervalo = Duration(milliseconds: 100);

  /// Lo que dura a la vista cada aviso.
  static const _duracionRetro = Duration(milliseconds: 1800);

  static const _id = PreparaDesayunoGame.idJuego;

  late Reloj _reloj;
  Timer? _timer;
  Duration _retroHasta = Duration.zero;

  @override
  PreparaDesayunoState build() {
    _reloj = ref.watch(relojProvider);
    final voz = ref.read(vozProvider);
    ref.onDispose(() {
      _detenerTimer();
      voz.callar();
    });

    // Se escucha en vez de observar: al registrar un nivel se elige solo el
    // siguiente, y eso no debe borrar la pantalla de resultados.
    ref.listen(dificultadJuegoProvider(_id), (_, d) {
      if (state.fase == FaseDesayuno.instrucciones) state = _nuevoIntento(d);
    });
    return _nuevoIntento(ref.read(dificultadJuegoProvider(_id)));
  }

  GeneradorDesayuno get _generador => ref.read(generadorDesayunoProvider);

  /// Lista y bandeja nuevas de la ronda medida, sin repetir la lista anterior
  /// del nivel.
  PreparaDesayunoState _nuevoIntento(Dificultad dificultad) {
    final nivel = NivelDesayuno.de(dificultad);
    final lista = _generador.lista(nivel);
    return _estado(nivel, lista, _generador.bandeja(nivel, lista), practica: false);
  }

  /// Lista corta de práctica, con el orden del nivel.
  PreparaDesayunoState _intentoPractica(NivelDesayuno nivel) {
    final lista = _generador.listaPractica();
    return _estado(nivel, lista, _generador.bandejaPractica(lista), practica: true);
  }

  static PreparaDesayunoState _estado(
    NivelDesayuno nivel,
    List<Alimento> lista,
    List<Alimento> bandeja, {
    required bool practica,
  }) =>
      PreparaDesayunoState(
        nivel: nivel,
        lista: lista,
        bandeja: bandeja,
        practica: practica,
        metricas: MetricasDesayuno(
          lista: lista,
          plato: List.filled(lista.length, null),
          conOrden: nivel.conOrden,
        ),
      );

  bool get _enBandeja => state.fase == FaseDesayuno.bandeja && !state.pausado;

  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  /// Botón «Hacer la práctica», también desde el fin de la práctica para
  /// repetirla.
  void empezarPractica() {
    if (state.fase != FaseDesayuno.instrucciones && state.fase != FaseDesayuno.finPractica) return;
    _mostrarLista(_intentoPractica(state.nivel));
  }

  /// Botón «Empezar» tras la práctica: la ronda medida, con una lista nueva.
  void empezarPrueba() {
    if (state.fase != FaseDesayuno.finPractica) return;
    _mostrarLista(_nuevoIntento(state.nivel.dificultad));
  }

  /// Muestra la lista de [intento] y la lee en voz alta; pasada la
  /// exposición se oculta y aparece la bandeja.
  void _mostrarLista(PreparaDesayunoState intento) {
    _detenerTimer();
    _reloj
      ..reiniciar()
      ..iniciar();
    state = intento.copyWith(fase: FaseDesayuno.memorizar);
    ref.read(lecturaProvider.notifier).leer(state.textoLista);
    _iniciarTimer();
  }

  /// Oculta la lista y arranca el tiempo de la bandeja desde cero.
  void _mostrarBandeja() {
    ref.read(lecturaProvider.notifier).detener();
    _reloj
      ..reiniciar()
      ..iniciar();
    state = state.copyWith(fase: FaseDesayuno.bandeja, transcurrido: Duration.zero);
  }

  /// Vuelve a las instrucciones desde el fin de la práctica.
  void verInstrucciones() {
    _detenerTimer();
    _reloj.reiniciar();
    ref.read(lecturaProvider.notifier).detener();
    state = _nuevoIntento(state.nivel.dificultad);
  }

  /// El adulto tocó el alimento [i] de la bandeja: va al primer puesto libre.
  void elegir(int i) {
    if (!_enBandeja || i < 0 || i >= state.bandeja.length) return;
    final libre = state.plato.indexOf(null);
    if (libre == -1) return _avisar(RetroDesayuno.platoLleno);
    poner(i, libre);
  }

  /// El adulto arrastró el alimento [i] de la bandeja al [puesto] del plato.
  /// Si el puesto estaba ocupado, lo que había vuelve a la bandeja.
  void poner(int i, int puesto) {
    if (!_enBandeja || i < 0 || i >= state.bandeja.length) return;
    if (puesto < 0 || puesto >= state.plato.length) return;
    final alimento = state.bandeja[i];
    // Un alimento que ya está en el plato no se pone dos veces.
    if (state.enPlato(alimento)) return;

    final plato = [...state.plato]..[puesto] = alimento;
    state = state.copyWith(metricas: state.metricas.copyWith(plato: plato), retro: RetroDesayuno.ninguna);
    if (!state.practica) return;

    final enLista = state.lista.indexOf(alimento);
    if (enLista == -1) return _avisar(RetroDesayuno.noEstaba);
    if (state.nivel.conOrden && enLista != puesto) return _avisar(RetroDesayuno.otroPuesto, puesto: enLista + 1);
    _avisar(RetroDesayuno.bien);
  }

  /// Devuelve a la bandeja lo que haya en el [puesto] del plato.
  void quitar(int puesto) {
    if (!_enBandeja || puesto < 0 || puesto >= state.plato.length) return;
    if (state.plato[puesto] == null) return;
    final plato = [...state.plato]..[puesto] = null;
    state = state.copyWith(metricas: state.metricas.copyWith(plato: plato), retro: RetroDesayuno.ninguna);
  }

  void _avisar(RetroDesayuno retro, {int puesto = 0}) {
    _retroHasta = _reloj.transcurrido + _duracionRetro;
    state = state.copyWith(retro: retro, retroId: state.retroId + 1, puestoCorrecto: puesto);
  }

  /// Botón «Listo»: se revisa el plato y se cierra la ronda. La práctica no
  /// se registra.
  void terminar() {
    if (!_enBandeja) return;
    _detenerTimer();
    _reloj.detener();
    final t = _reloj.transcurrido;
    final metricas = state.metricas.copyWith(tiempo: t);

    if (state.practica) {
      state = state.copyWith(
        fase: FaseDesayuno.finPractica,
        transcurrido: t,
        metricas: metricas,
        retro: RetroDesayuno.ninguna,
      );
      return;
    }

    final resultado = metricas.aResultado(state.nivel.dificultad);
    state = state.copyWith(
      fase: FaseDesayuno.resultado,
      transcurrido: t,
      metricas: metricas,
      retro: RetroDesayuno.ninguna,
      resultado: () => resultado,
    );
    // Se guarda al terminar, sin esperar a que salga de la pantalla: así
    // «Repetir» no lo pierde.
    ref.read(resultadosProvider.notifier).registrar(_id, state.nivel.dificultad, resultado);
  }

  /// En pausa se detiene el tiempo. Mientras se memoriza, la lista se oculta
  /// y deja de leerse, para que la pausa no alargue la exposición.
  void pausar() {
    if (!state.enRonda || state.pausado) return;
    _detenerTimer();
    _reloj.detener();
    if (state.fase == FaseDesayuno.memorizar) ref.read(lecturaProvider.notifier).detener();
    state = state.copyWith(pausado: true, transcurrido: _reloj.transcurrido);
  }

  void reanudar() {
    if (!state.enRonda || !state.pausado) return;
    state = state.copyWith(pausado: false);
    _reloj.iniciar();
    _iniciarTimer();
  }

  /// Otra ronda del mismo nivel, con otra lista, desde las instrucciones.
  void repetir() {
    final dificultad = state.nivel.dificultad;
    _detenerTimer();
    _reloj.reiniciar();
    ref.read(lecturaProvider.notifier).detener();
    // Primero se elige el nivel (el listener lo ignora fuera de las
    // instrucciones) y luego se arma el intento nuevo.
    ref.read(dificultadJuegoProvider(_id).notifier).elegir(dificultad);
    state = _nuevoIntento(dificultad);
  }

  /// Avanza la cuenta atrás de la lista y apaga el aviso. Lo llama el timer.
  @visibleForTesting
  void actualizar() {
    if (!state.enRonda || state.pausado) return;
    final t = _reloj.transcurrido;

    if (state.fase == FaseDesayuno.memorizar) {
      if (t >= state.exposicion) return _mostrarBandeja();
      // La barra de la cuenta atrás avanza suave: se avisa en cada paso.
      state = state.copyWith(transcurrido: t);
      return;
    }

    if (state.retro != RetroDesayuno.ninguna && t >= _retroHasta) {
      state = state.copyWith(retro: RetroDesayuno.ninguna, transcurrido: t);
    }
  }

  void _iniciarTimer() => _timer = Timer.periodic(_intervalo, (_) => actualizar());

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Uno solo en toda la app: recuerda la última lista de cada nivel.
final generadorDesayunoProvider = Provider<GeneradorDesayuno>((_) => GeneradorDesayuno());

final preparaDesayunoProvider =
    NotifierProvider.autoDispose<PreparaDesayunoNotifier, PreparaDesayunoState>(PreparaDesayunoNotifier.new);
