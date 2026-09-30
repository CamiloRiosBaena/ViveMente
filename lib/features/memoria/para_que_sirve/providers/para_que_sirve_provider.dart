import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/banco_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/generador_preguntas.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/metricas_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/nivel_objetos.dart';
import 'package:vivamente/features/memoria/para_que_sirve/models/pregunta.dart';
import 'package:vivamente/features/memoria/para_que_sirve/para_que_sirve_game.dart';

/// La práctica y la ronda medida pasan por [pregunta]; la práctica termina en
/// [finPractica] y la ronda medida en [resultado].
enum FaseObjetos { instrucciones, pregunta, finPractica, resultado }

class ParaQueSirveState {
  const ParaQueSirveState({
    required this.nivel,
    required this.metricas,
    this.preguntas = const [],
    this.indice = 0,
    this.practica = false,
    this.fase = FaseObjetos.instrucciones,
    this.elegida,
    this.pausado = false,
    this.resultado,
  });

  final NivelObjetos nivel;
  final List<Pregunta> preguntas;

  /// Pregunta a la vista.
  final int indice;

  /// Si la ronda es la práctica: más corta y sin registrar el resultado.
  final bool practica;

  final FaseObjetos fase;

  /// Opción que eligió en la pregunta actual; mientras sea `null` todavía no
  /// responde. Al responder se muestra la explicación.
  final int? elegida;

  final bool pausado;
  final MetricasObjetos metricas;

  /// Listo al terminar la ronda medida.
  final ResultadoJuego? resultado;

  Pregunta get pregunta => preguntas[indice];

  bool get respondida => elegida != null;

  bool get acerto => elegida == pregunta.correcta;

  bool get esUltima => indice == preguntas.length - 1;

  /// Consigna completa, la misma que se lee en voz alta.
  String get instruccion => 'Verá un objeto con su nombre y una pregunta: ${nivel.queSeBusca}. '
      'Toque la respuesta que le parezca correcta entre las ${NivelObjetos.opciones} opciones. '
      'Después verá una explicación; cuando la lea, toque Siguiente. '
      'Son ${NivelObjetos.preguntas} preguntas y no hay límite de tiempo. '
      'Nivel ${nivel.dificultad.nivel}. Antes hay una práctica con ${NivelObjetos.preguntasPractica} preguntas. '
      'Cuando esté listo, toque Hacer la práctica.';

  ParaQueSirveState copyWith({
    int? indice,
    FaseObjetos? fase,
    int? Function()? elegida,
    bool? pausado,
    MetricasObjetos? metricas,
    ResultadoJuego? Function()? resultado,
  }) =>
      ParaQueSirveState(
        nivel: nivel,
        preguntas: preguntas,
        practica: practica,
        indice: indice ?? this.indice,
        fase: fase ?? this.fase,
        elegida: elegida != null ? elegida() : this.elegida,
        pausado: pausado ?? this.pausado,
        metricas: metricas ?? this.metricas,
        resultado: resultado != null ? resultado() : this.resultado,
      );
}

/// Motor de «¿Para qué sirve?». La vista solo pinta este estado y llama a
/// sus métodos.
class ParaQueSirveNotifier extends Notifier<ParaQueSirveState> {
  static const _id = ParaQueSirveGame.idJuego;

  late Reloj _reloj;

  @override
  ParaQueSirveState build() {
    _reloj = ref.watch(relojProvider);
    final voz = ref.read(vozProvider);
    ref.onDispose(voz.callar);

    // Se escucha en vez de observar: al registrar un nivel se elige solo el
    // siguiente, y eso no debe borrar la pantalla de resultados.
    ref.listen(dificultadJuegoProvider(_id), (_, d) {
      if (state.fase == FaseObjetos.instrucciones) state = _instrucciones(d);
    });
    return _instrucciones(ref.read(dificultadJuegoProvider(_id)));
  }

  GeneradorPreguntas get _generador => ref.read(generadorPreguntasProvider);

  static ParaQueSirveState _instrucciones(Dificultad d) =>
      ParaQueSirveState(nivel: NivelObjetos.de(d), metricas: const MetricasObjetos(total: 0));

  void escucharInstruccion() => ref.read(lecturaProvider.notifier).alternar(state.instruccion);

  /// Lee el objeto, la pregunta y las opciones; o la explicación, si ya
  /// respondió.
  void escucharPregunta() {
    final p = state.pregunta;
    ref.read(lecturaProvider.notifier).alternar(state.respondida ? p.explicacion : p.lectura);
  }

  /// Botón «Hacer la práctica», también desde el fin de la práctica para
  /// repetirla.
  void empezarPractica() {
    if (state.fase != FaseObjetos.instrucciones && state.fase != FaseObjetos.finPractica) return;
    _empezar(practica: true, cantidad: NivelObjetos.preguntasPractica);
  }

  /// Botón «Empezar» tras la práctica: la ronda medida, sin los objetos que
  /// salieron en la práctica.
  void empezarPrueba() {
    if (state.fase != FaseObjetos.finPractica) return;
    _empezar(
      practica: false,
      cantidad: NivelObjetos.preguntas,
      excluir: state.preguntas.map((p) => p.objeto).toSet(),
    );
  }

  void _empezar({required bool practica, required int cantidad, Set<Objeto> excluir = const {}}) {
    ref.read(lecturaProvider.notifier).detener();
    final nivel = state.nivel;
    final preguntas = _generador.ronda(nivel, cantidad, excluir: excluir);
    state = ParaQueSirveState(
      nivel: nivel,
      preguntas: preguntas,
      practica: practica,
      fase: FaseObjetos.pregunta,
      metricas: MetricasObjetos(total: preguntas.length),
    );
    _reloj
      ..reiniciar()
      ..iniciar();
  }

  /// El adulto eligió la opción [i]: se anota y se muestra la explicación.
  void responder(int i) {
    if (state.fase != FaseObjetos.pregunta || state.pausado || state.respondida) return;
    if (i < 0 || i >= state.pregunta.opciones.length) return;
    _reloj.detener();
    ref.read(lecturaProvider.notifier).detener();
    state = state.copyWith(
      elegida: () => i,
      metricas: state.metricas.anotar(Respuesta(state.pregunta, i, _reloj.transcurrido)),
    );
  }

  /// Botón «Siguiente» tras la explicación. En la última pregunta cierra la
  /// ronda.
  void siguiente() {
    if (state.fase != FaseObjetos.pregunta || !state.respondida) return;
    ref.read(lecturaProvider.notifier).detener();
    if (state.esUltima) return _terminar();
    state = state.copyWith(indice: state.indice + 1, elegida: () => null);
    _reloj
      ..reiniciar()
      ..iniciar();
  }

  void _terminar() {
    if (state.practica) {
      state = state.copyWith(fase: FaseObjetos.finPractica);
      return;
    }
    final resultado = state.metricas.aResultado(state.nivel.dificultad);
    state = state.copyWith(fase: FaseObjetos.resultado, resultado: () => resultado);
    // Se guarda al terminar, sin esperar a que salga de la pantalla: así
    // «Repetir» no lo pierde.
    ref.read(resultadosProvider.notifier).registrar(_id, state.nivel.dificultad, resultado);
  }

  /// Vuelve a las instrucciones desde el fin de la práctica.
  void verInstrucciones() {
    ref.read(lecturaProvider.notifier).detener();
    _reloj.reiniciar();
    state = _instrucciones(state.nivel.dificultad);
  }

  /// En pausa el tiempo de respuesta no corre.
  void pausar() {
    if (state.fase != FaseObjetos.pregunta || state.pausado) return;
    _reloj.detener();
    ref.read(lecturaProvider.notifier).detener();
    state = state.copyWith(pausado: true);
  }

  void reanudar() {
    if (state.fase != FaseObjetos.pregunta || !state.pausado) return;
    state = state.copyWith(pausado: false);
    if (!state.respondida) _reloj.iniciar();
  }

  /// Otra ronda del mismo nivel, desde las instrucciones.
  void repetir() {
    final dificultad = state.nivel.dificultad;
    ref.read(lecturaProvider.notifier).detener();
    _reloj.reiniciar();
    // Primero se elige el nivel (el listener lo ignora fuera de las
    // instrucciones) y luego se vuelve a las instrucciones.
    ref.read(dificultadJuegoProvider(_id).notifier).elegir(dificultad);
    state = _instrucciones(dificultad);
  }
}

/// Uno solo en toda la app: recuerda los objetos de la última ronda de cada
/// nivel.
final generadorPreguntasProvider = Provider<GeneradorPreguntas>((_) => GeneradorPreguntas());

final paraQueSirveProvider =
    NotifierProvider.autoDispose<ParaQueSirveNotifier, ParaQueSirveState>(ParaQueSirveNotifier.new);
