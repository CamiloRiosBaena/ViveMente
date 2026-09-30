import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/evaluador_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/metricas_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/nivel_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

/// La presentación muestra la categoría en grande unos segundos antes de que
/// empiece a correr el tiempo. La práctica pasa por las mismas fases y
/// termina en [finPractica].
enum FaseCategoria { instrucciones, presentacion, jugando, finPractica, resultado }

class PalabrasCategoriaState {
  const PalabrasCategoriaState({
    required this.nivel,
    required this.categoria,
    required this.metricas,
    this.practica = false,
    this.fase = FaseCategoria.instrucciones,
    this.escuchando = false,
    this.parcial = '',
    this.transcurrido = Duration.zero,
    this.pausado = false,
    this.retro,
    this.palabraRetro = '',
    this.categoriaRetro,
    this.retroId = 0,
    this.avisoDictado = 0,
    this.resultado,
  });

  final NivelCategoria nivel;

  /// Categoría de este intento.
  final Categoria categoria;

  /// Si la ronda es la práctica: más corta, con colores y sin registrar.
  final bool practica;

  final FaseCategoria fase;

  /// Si el micrófono está encendido. Queda así, aunque haya silencios, hasta
  /// que el adulto lo apague o acabe la ronda.
  final bool escuchando;

  /// Lo que el dictado va oyendo y aún no se ha registrado.
  final String parcial;

  final Duration transcurrido;
  final bool pausado;

  /// Veredicto de la última palabra, mientras dura el refuerzo.
  final Veredicto? retro;
  final String palabraRetro;

  /// Con [Veredicto.otraCategoria], la categoría a la que pertenece.
  final Categoria? categoriaRetro;

  /// Sube con cada palabra, para que dos refuerzos iguales se animen los dos.
  final int retroId;

  /// Sube cada vez que el micrófono no pudo abrirse, para avisar una vez.
  final int avisoDictado;

  final MetricasCategoria metricas;

  /// Listo al terminar la ronda medida.
  final ResultadoJuego? resultado;

  bool get jugando => fase == FaseCategoria.jugando;

  Duration get duracion => practica ? NivelCategoria.duracionPractica : NivelCategoria.duracion;

  /// Segundos que faltan para que empiece la ronda, durante la presentación.
  int get cuentaAtras {
    final r = PalabrasCategoriaNotifier.presentacion - transcurrido;
    return r.isNegative ? 0 : (r.inMilliseconds / 1000).ceil();
  }

  Duration get restante {
    final r = duracion - transcurrido;
    return r.isNegative ? Duration.zero : r;
  }

  /// Redondea hacia arriba para no mostrar 00:00 con tiempo.
  String get textoTiempo => formatoReloj(Duration(seconds: (restante.inMilliseconds / 1000).ceil()));

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion => 'Cuando empiece verá una categoría, por ejemplo frutas o animales. '
      'Diga o escriba todas las palabras de esa categoría que se le ocurran, lo más rápido que pueda. '
      'Por ejemplo, con colores: rojo, azul, verde. No vale repetir una palabra. '
      'Puede escribirlas y enviarlas, o encender el micrófono y decirlas en voz alta: '
      'lo que diga se guarda solo, y el micrófono sigue escuchando hasta que lo apague. '
      'Tiene 60 segundos. Nivel ${nivel.dificultad.nivel}. '
      'Antes hay una práctica corta con colores. Cuando esté listo, toque Hacer la práctica.';

  PalabrasCategoriaState copyWith({
    FaseCategoria? fase,
    bool? escuchando,
    String? parcial,
    Duration? transcurrido,
    bool? pausado,
    Veredicto? Function()? retro,
    String? palabraRetro,
    Categoria? Function()? categoriaRetro,
    int? retroId,
    int? avisoDictado,
    MetricasCategoria? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      PalabrasCategoriaState(
        nivel: nivel,
        categoria: categoria,
        practica: practica,
        fase: fase ?? this.fase,
        escuchando: escuchando ?? this.escuchando,
        parcial: parcial ?? this.parcial,
        transcurrido: transcurrido ?? this.transcurrido,
        pausado: pausado ?? this.pausado,
        retro: retro != null ? retro() : this.retro,
        palabraRetro: palabraRetro ?? this.palabraRetro,
        categoriaRetro: categoriaRetro != null ? categoriaRetro() : this.categoriaRetro,
        retroId: retroId ?? this.retroId,
        avisoDictado: avisoDictado ?? this.avisoDictado,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «Palabras por categoría». La vista solo pinta este estado y
/// llama a sus métodos.
class PalabrasCategoriaNotifier extends Notifier<PalabrasCategoriaState> {
  static const _intervalo = Duration(milliseconds: 100);

  /// El refuerzo dura lo suficiente para leer por qué no contó una palabra.
  static const _duracionRetro = Duration(milliseconds: 1600);

  /// Cuánto se muestra la categoría en grande antes de empezar.
  static const presentacion = Duration(seconds: 3);

  /// Pausa antes de reabrir el micrófono cuando el reconocedor se cierra solo.
  static const _esperaReapertura = Duration(milliseconds: 300);

  /// Si lo que va oyendo el dictado no cambia en este tiempo, las palabras se
  /// dan por dichas y se guardan sin tocar nada.
  static const _esperaPalabra = Duration(milliseconds: 900);

  static const _id = PalabrasCategoriaGame.idJuego;

  late Reloj _reloj;
  late Dictado _dictado;
  Timer? _timer;
  Timer? _reapertura;
  Duration _retroHasta = Duration.zero;

  /// Sube al cerrar una ronda, para ignorar lo que el dictado entregue tarde.
  int _ronda = 0;

  /// Respuestas de la escucha actual (el reconocedor las va acumulando) y
  /// cuántas de ellas ya se guardaron.
  List<String> _oidas = const [];
  int _guardadas = 0;

  /// Cuándo cambió por última vez lo oído; `null` si no hay nada pendiente.
  Duration? _cambioOido;

  @override
  PalabrasCategoriaState build() {
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
      if (state.fase == FaseCategoria.instrucciones) state = _instrucciones(d);
    });
    return _instrucciones(ref.read(dificultadJuegoProvider(_id)));
  }

  /// En las instrucciones aún no se sortea la categoría: se muestra al empezar.
  static PalabrasCategoriaState _instrucciones(Dificultad d) {
    final nivel = NivelCategoria.de(d);
    return PalabrasCategoriaState(
      nivel: nivel,
      categoria: nivel.categorias.first,
      metricas: MetricasCategoria(meta: nivel.categorias.first.meta),
    );
  }

  bool get _activo => state.jugando && !state.pausado;

  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  /// Botón «Hacer la práctica», también desde el fin de la práctica para
  /// repetirla: 20 segundos con colores.
  void empezarPractica() {
    if (state.fase != FaseCategoria.instrucciones && state.fase != FaseCategoria.finPractica) return;
    _presentar(NivelCategoria.categoriaPractica, practica: true);
  }

  /// Botón «Empezar» tras la práctica: la ronda medida con la categoría
  /// sorteada del nivel.
  void empezarPrueba() {
    if (state.fase != FaseCategoria.finPractica) return;
    _presentar(ref.read(sorteoCategoriaProvider).elegir(state.nivel), practica: false);
  }

  /// La categoría se muestra en grande y se dice en voz alta; pasada la
  /// [presentacion] empieza a correr el tiempo.
  void _presentar(Categoria categoria, {required bool practica}) {
    _detenerTimer();
    _cerrarMicrofono();
    _reloj
      ..reiniciar()
      ..iniciar();
    state = PalabrasCategoriaState(
      nivel: state.nivel,
      categoria: categoria,
      practica: practica,
      fase: FaseCategoria.presentacion,
      metricas: MetricasCategoria(meta: categoria.meta),
    );
    ref.read(lecturaProvider.notifier).leer('Su categoría es: ${categoria.nombre.toLowerCase()}.');
    _iniciarTimer();
  }

  /// Cierra la presentación y arranca la ronda desde cero.
  void _empezarRonda() {
    ref.read(lecturaProvider.notifier).detener();
    _reloj
      ..reiniciar()
      ..iniciar();
    state = state.copyWith(fase: FaseCategoria.jugando, transcurrido: Duration.zero);
  }

  /// Vuelve a las instrucciones desde el fin de la práctica.
  void verInstrucciones() {
    _detenerTimer();
    _reloj.reiniciar();
    _cerrarMicrofono();
    ref.read(lecturaProvider.notifier).detener();
    state = _instrucciones(state.nivel.dificultad);
  }

  /// Texto escrito: se evalúa al enviarlo. Puede traer varias palabras; las
  /// de relleno («el», «y») se ignoran. Devuelve `false` si no se tomó
  /// (ronda en pausa o texto vacío), para que la vista no borre el campo.
  bool anadir(String texto) {
    if (!_activo || texto.trim().isEmpty) return false;
    _registrar(EvaluadorCategoria.separar(texto, state.categoria), dictada: false);
    return true;
  }

  /// Enciende o apaga el micrófono. Encendido, se reabre solo cada vez que el
  /// reconocedor se cierra por un silencio.
  Future<void> alternarMicrofono() async {
    if (!_activo) return;
    if (state.escuchando) {
      state = state.copyWith(escuchando: false);
      _reapertura?.cancel();
      return _dictado.detener();
    }
    state = state.copyWith(escuchando: true, parcial: '');
    await _abrirMicrofono();
  }

  Future<void> _abrirMicrofono() async {
    final ronda = _ronda;
    // Si el reconocedor se cerró sin entregar el final, lo oído no se pierde.
    _guardarOidas();
    _olvidarOidas();
    final empezo = await _dictado.escuchar(alOir: (texto, esFinal) => _oir(ronda, texto, esFinal));
    if (!ref.mounted || ronda != _ronda) return;
    if (!empezo && state.escuchando) {
      state = state.copyWith(escuchando: false, avisoDictado: state.avisoDictado + 1);
    }
  }

  /// El reconocedor se cerró (silencio, límite del equipo o error). Si el
  /// micrófono sigue encendido y la ronda corre, se vuelve a abrir.
  void _alCerrarseMicrofono() {
    if (!ref.mounted || !state.escuchando || !_activo) return;
    _reapertura?.cancel();
    _reapertura = Timer(_esperaReapertura, () {
      if (ref.mounted && state.escuchando && _activo) _abrirMicrofono();
    });
  }

  /// Apaga el micrófono y descarta lo que llegue tarde de esta ronda.
  void _cerrarMicrofono() {
    _ronda++;
    _olvidarOidas();
    _reapertura?.cancel();
    _dictado.detener();
  }

  /// Lo que el reconocedor va oyendo. Las respuestas se guardan solas: al
  /// llegar el resultado final, o cuando lo oído deja de cambiar un momento
  /// (ver [actualizar]). Lo dicho justo antes de pausar aún cuenta.
  void _oir(int ronda, String texto, bool esFinal) {
    if (!ref.mounted || ronda != _ronda || !state.jugando) return;
    final respuestas = EvaluadorCategoria.separar(texto, state.categoria);
    // Si el reconocedor corrige y acorta lo que llevaba, no se guarda dos veces.
    if (respuestas.length < _guardadas) _guardadas = respuestas.length;
    _oidas = respuestas;

    if (esFinal) {
      _guardarOidas();
      _olvidarOidas();
    } else {
      _cambioOido = _reloj.transcurrido;
    }
    // Lo reconocido se muestra como está en el diccionario, con sus tildes.
    final pendientes = _oidas.skip(_guardadas).map((r) => EvaluadorCategoria.buscar(r, state.categoria) ?? r);
    state = state.copyWith(parcial: pendientes.join(', '));
  }

  /// Guarda lo oído que aún no se había guardado.
  void _guardarOidas() {
    if (_oidas.length > _guardadas) _registrar(_oidas.sublist(_guardadas), dictada: true);
    _guardadas = _oidas.length;
    _cambioOido = null;
  }

  void _olvidarOidas() {
    _oidas = const [];
    _guardadas = 0;
    _cambioOido = null;
  }

  void _registrar(List<String> respuestas, {required bool dictada}) {
    if (respuestas.isEmpty) return;
    final t = _reloj.transcurrido;
    var m = state.metricas;
    Evaluacion? mostrar;

    for (final r in respuestas) {
      final e = EvaluadorCategoria.evaluar(r, state.categoria, m.palabras.map((d) => d.texto));
      m = m.anotar(e, t, dictada: dictada);
      // Si en un dictado hubo alguna válida, el refuerzo celebra esa.
      if (mostrar == null || mostrar.veredicto != Veredicto.valida) mostrar = e;
    }

    _retroHasta = t + _duracionRetro;
    state = state.copyWith(
      metricas: m,
      retro: () => mostrar!.veredicto,
      palabraRetro: mostrar!.palabra,
      categoriaRetro: () => mostrar!.categoria,
      retroId: state.retroId + 1,
    );
  }

  /// Quita la palabra [i] de la lista, si se registró por error.
  void quitar(int i) {
    if (!state.jugando || i < 0 || i >= state.metricas.validas) return;
    state = state.copyWith(metricas: state.metricas.quitar(i));
  }

  /// Botón «Terminar»: cierra la ronda antes de que acabe el tiempo.
  void terminar() {
    if (!state.jugando) return;
    _terminar(_reloj.transcurrido);
  }

  /// En pausa el micrófono se cierra, pero sigue encendido: al reanudar se
  /// vuelve a abrir.
  void pausar() {
    if (!state.jugando || state.pausado) return;
    _detenerTimer();
    _reloj.detener();
    _guardarOidas();
    state = state.copyWith(pausado: true, transcurrido: _reloj.transcurrido, parcial: '');
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

  /// Otra ronda del mismo nivel, desde las instrucciones.
  void repetir() {
    final dificultad = state.nivel.dificultad;
    _detenerTimer();
    _reloj.reiniciar();
    _cerrarMicrofono();
    ref.read(lecturaProvider.notifier).detener();
    // Primero se elige el nivel (el listener lo ignora fuera de las
    // instrucciones) y luego se vuelve a las instrucciones.
    ref.read(dificultadJuegoProvider(_id).notifier).elegir(dificultad);
    state = _instrucciones(dificultad);
  }

  /// Avanza el cronómetro, apaga el refuerzo y cierra la ronda al acabar el
  /// tiempo. Lo llama el timer.
  @visibleForTesting
  void actualizar() {
    if (state.fase == FaseCategoria.presentacion) return _actualizarPresentacion();
    if (!_activo) return;
    final t = _reloj.transcurrido;
    if (t >= state.duracion) return _terminar(state.duracion);

    final cambio = _cambioOido;
    if (cambio != null && t - cambio >= _esperaPalabra) {
      _guardarOidas();
      state = state.copyWith(parcial: '');
    }

    var s = state;
    if (s.retro != null && t >= _retroHasta) s = s.copyWith(retro: () => null);
    final textoAntes = state.textoTiempo;
    final cambioRetro = !identical(s, state);
    s = s.copyWith(transcurrido: t);
    // Solo se avisa a la vista cuando cambia el segundo o el refuerzo.
    if (cambioRetro || s.textoTiempo != textoAntes) state = s;
  }

  void _actualizarPresentacion() {
    final t = _reloj.transcurrido;
    if (t >= presentacion) return _empezarRonda();
    final s = state.copyWith(transcurrido: t);
    if (s.cuentaAtras != state.cuentaAtras) state = s;
  }

  /// Lo que el dictado alcanzó a oír cuenta; lo escrito sin enviar, no. La
  /// práctica no se registra; la ronda medida se guarda al terminar, sin
  /// esperar a que salga de la pantalla: así «Repetir» no la pierde.
  void _terminar(Duration t) {
    _detenerTimer();
    _reloj.detener();
    _guardarOidas();
    _cerrarMicrofono();

    final metricas = state.metricas.conTiempo(t);
    final base = state.copyWith(
      transcurrido: t,
      metricas: metricas,
      parcial: '',
      escuchando: false,
      retro: () => null,
    );
    if (state.practica) {
      state = base.copyWith(fase: FaseCategoria.finPractica);
      return;
    }
    final resultado = metricas.aResultado(state.nivel.dificultad);
    state = base.copyWith(fase: FaseCategoria.resultado, resultado: () => resultado);
    ref.read(resultadosProvider.notifier).registrar(_id, state.nivel.dificultad, resultado);
  }

  void _iniciarTimer() => _timer = Timer.periodic(_intervalo, (_) => actualizar());

  void _detenerTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Uno solo en toda la app: recuerda la última categoría de cada nivel.
final sorteoCategoriaProvider = Provider<SorteoCategoria>((_) => SorteoCategoria());

final palabrasCategoriaProvider =
    NotifierProvider.autoDispose<PalabrasCategoriaNotifier, PalabrasCategoriaState>(PalabrasCategoriaNotifier.new);
