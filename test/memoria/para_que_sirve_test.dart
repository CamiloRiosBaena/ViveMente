import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:vivamente/features/memoria/para_que_sirve/providers/para_que_sirve_provider.dart';

import '../helpers/falsos.dart';

const _id = ParaQueSirveGame.idJuego;

void main() {
  group('GeneradorPreguntas', () {
    for (final d in Dificultad.values) {
      test('nivel ${d.nivel}: preguntas con 3 opciones distintas y la correcta entre ellas', () {
        final nivel = NivelObjetos.de(d);
        final g = GeneradorPreguntas(random: Random(1));
        for (var i = 0; i < 20; i++) {
          final ronda = g.ronda(nivel, NivelObjetos.preguntas);
          expect(ronda, hasLength(NivelObjetos.preguntas));
          expect(ronda.map((p) => p.objeto).toSet(), hasLength(NivelObjetos.preguntas), reason: 'sin repetir objetos');
          for (final p in ronda) {
            expect(p.opciones, hasLength(NivelObjetos.opciones));
            expect(p.opciones.toSet(), hasLength(NivelObjetos.opciones));
            expect(p.enunciado, nivel.enunciado);
            expect(p.explicacion, isNotEmpty);
          }
        }
      });
    }

    test('nivel 1: la correcta es la función del objeto y los distractores no se le parecen', () {
      final g = GeneradorPreguntas(random: Random(2));
      for (var i = 0; i < 30; i++) {
        for (final p in g.ronda(NivelObjetos.de(Dificultad.facil), NivelObjetos.preguntas)) {
          final f = BancoObjetos.funciones.firstWhere((f) => f.objeto == p.objeto);
          expect(p.respuesta.texto, f.funcion);
          for (final o in p.opciones.where((o) => o != p.respuesta)) {
            final origen = BancoObjetos.funciones.firstWhere((x) => x.funcion == o.texto);
            expect(f.compatibleCon(origen), isTrue, reason: '${p.objeto} con «${o.texto}»');
          }
        }
      }
    });

    test('nivel 2: la correcta es el lugar del objeto, con su ícono', () {
      final g = GeneradorPreguntas(random: Random(3));
      for (final p in g.ronda(NivelObjetos.de(Dificultad.medio), NivelObjetos.preguntas)) {
        final l = BancoObjetos.lugares.firstWhere((l) => l.objeto == p.objeto);
        expect(p.respuesta.texto, l.lugar.etiqueta);
        expect(p.opciones.every((o) => o.icono != null), isTrue);
      }
    });

    test('nivel 3: la correcta es la pareja y los distractores son de otro grupo', () {
      final g = GeneradorPreguntas(random: Random(4));
      for (var i = 0; i < 30; i++) {
        for (final p in g.ronda(NivelObjetos.de(Dificultad.dificil), NivelObjetos.preguntas)) {
          final par = BancoObjetos.parejas.firstWhere((x) => x.objeto == p.objeto);
          expect(p.respuesta.texto, par.pareja.nombre);
          expect(p.opciones.every((o) => o.emoji != null), isTrue);
          for (final o in p.opciones.where((o) => o != p.respuesta)) {
            final origen = BancoObjetos.parejas.firstWhere((x) => x.pareja.nombre == o.texto);
            expect(par.compatibleCon(origen), isTrue, reason: '${p.objeto} con ${o.texto}');
          }
        }
      }
    });

    test('el ejemplo de las instrucciones no sale como pregunta en su nivel', () {
      final g = GeneradorPreguntas(random: Random(5));
      final ejemplos = {
        Dificultad.facil: BancoObjetos.ejemplo.objeto,
        Dificultad.medio: BancoObjetos.ejemploLugar.objeto,
        Dificultad.dificil: BancoObjetos.ejemploPareja.objeto,
      };
      for (var i = 0; i < 30; i++) {
        for (final d in Dificultad.values) {
          final objetos = g.ronda(NivelObjetos.de(d), NivelObjetos.preguntas).map((p) => p.objeto);
          expect(objetos, isNot(contains(ejemplos[d])), reason: 'nivel ${d.nivel}');
        }
      }
    });

    test('no repite los objetos de la ronda anterior del nivel ni los excluidos', () {
      final g = GeneradorPreguntas(random: Random(6));
      final nivel = NivelObjetos.de(Dificultad.facil);
      final practica = g.ronda(nivel, NivelObjetos.preguntasPractica).map((p) => p.objeto).toSet();
      final primera = g.ronda(nivel, NivelObjetos.preguntas, excluir: practica).map((p) => p.objeto).toSet();
      expect(primera.intersection(practica), isEmpty);
      final segunda = g.ronda(nivel, NivelObjetos.preguntas).map((p) => p.objeto).toSet();
      expect(segunda.intersection(primera), isEmpty);
    });
  });

  test('MetricasObjetos cuenta aciertos, errores, omisiones y tiempo', () {
    final p = Pregunta(
      objeto: BancoObjetos.ejemplo.objeto,
      enunciado: '¿?',
      opciones: const [Opcion('a'), Opcion('b'), Opcion('c')],
      correcta: 1,
      explicacion: 'x',
    );
    final m = const MetricasObjetos(total: 4)
        .anotar(Respuesta(p, 1, const Duration(seconds: 4)))
        .anotar(Respuesta(p, 0, const Duration(seconds: 6)))
        .anotar(Respuesta(p, 1, const Duration(seconds: 2)));
    expect(m.aciertos, 2);
    expect(m.errores, 1);
    expect(m.omisiones, 1);
    expect(m.puntaje, 50);
    expect(m.tiempo, const Duration(seconds: 12));

    final r = m.aResultado(Dificultad.dificil);
    expect(r.latenciaPromedio, 4000);
    expect(r.puntajeBruto, 50);
    expect(r.dificultad, Dificultad.dificil);
  });

  group('ParaQueSirveNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late ProviderContainer c;
    late ProviderSubscription<ParaQueSirveState> sub;

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        generadorPreguntasProvider.overrideWithValue(GeneradorPreguntas(random: Random(7))),
      ]);
      sub = c.listen(paraQueSirveProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    ParaQueSirveNotifier juego() => c.read(paraQueSirveProvider.notifier);
    ParaQueSirveState estado() => c.read(paraQueSirveProvider);
    int incorrecta() => (estado().pregunta.correcta + 1) % NivelObjetos.opciones;

    /// Responde bien todas las preguntas que quedan, cada una en [ms].
    void responderTodas({int ms = 1000}) {
      while (estado().fase == FaseObjetos.pregunta) {
        reloj.avanzar(Duration(milliseconds: ms));
        juego().responder(estado().pregunta.correcta);
        juego().siguiente();
      }
    }

    test('la práctica son 2 preguntas y no se registra', () {
      juego().empezarPractica();
      expect(estado().practica, isTrue);
      expect(estado().preguntas, hasLength(NivelObjetos.preguntasPractica));
      responderTodas();
      expect(estado().fase, FaseObjetos.finPractica);
      expect(estado().metricas.aciertos, NivelObjetos.preguntasPractica);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
    });

    test('no se puede empezar la ronda medida sin hacer la práctica', () {
      juego().empezarPrueba();
      expect(estado().fase, FaseObjetos.instrucciones);
    });

    test('responder muestra la explicación una sola vez; siguiente avanza', () {
      juego().empezarPractica();
      reloj.avanzar(const Duration(seconds: 3));
      final i = incorrecta();
      juego().responder(i);
      expect(estado().respondida, isTrue);
      expect(estado().acerto, isFalse);
      expect(estado().metricas.respuestas.single.latencia, const Duration(seconds: 3));

      // Una vez respondida no se puede cambiar.
      juego().responder(estado().pregunta.correcta);
      expect(estado().elegida, i);
      expect(estado().metricas.respuestas, hasLength(1));

      // El tiempo leyendo la explicación no cuenta.
      reloj.avanzar(const Duration(seconds: 20));
      juego().siguiente();
      expect(estado().indice, 1);
      expect(estado().respondida, isFalse);
      reloj.avanzar(const Duration(seconds: 2));
      juego().responder(estado().pregunta.correcta);
      expect(estado().metricas.respuestas.last.latencia, const Duration(seconds: 2));
    });

    test('siguiente no avanza sin responder', () {
      juego().empezarPractica();
      juego().siguiente();
      expect(estado().indice, 0);
    });

    test('la ronda medida trae otros objetos, registra solo ese nivel y conserva el resultado', () {
      juego().empezarPractica();
      final practica = estado().preguntas.map((p) => p.objeto).toSet();
      responderTodas();
      juego().empezarPrueba();

      expect(estado().practica, isFalse);
      expect(estado().preguntas, hasLength(NivelObjetos.preguntas));
      expect(estado().preguntas.map((p) => p.objeto).toSet().intersection(practica), isEmpty);

      reloj.avanzar(const Duration(seconds: 5));
      juego().responder(incorrecta());
      juego().siguiente();
      responderTodas(ms: 3000);

      expect(estado().fase, FaseObjetos.resultado);
      expect(estado().resultado!.aciertos, NivelObjetos.preguntas - 1);
      expect(estado().resultado!.errores, 1);
      expect(estado().resultado!.puntajeBruto, 83);
      expect(estado().metricas.tiempo, const Duration(seconds: 20));

      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FaseObjetos.resultado);
    });

    test('en pausa el tiempo de respuesta no corre ni se puede responder', () {
      juego().empezarPractica();
      reloj.avanzar(const Duration(seconds: 2));
      juego().pausar();
      reloj.avanzar(const Duration(seconds: 30));
      juego().responder(estado().pregunta.correcta);
      expect(estado().respondida, isFalse);

      juego().reanudar();
      reloj.avanzar(const Duration(seconds: 1));
      juego().responder(estado().pregunta.correcta);
      expect(estado().metricas.respuestas.single.latencia, const Duration(seconds: 3));
    });

    test('desde el fin de la práctica se puede repetirla o volver a las instrucciones', () {
      juego().empezarPractica();
      responderTodas();
      juego().empezarPractica();
      expect(estado().fase, FaseObjetos.pregunta);
      expect(estado().practica, isTrue);
      responderTodas();
      juego().verInstrucciones();
      expect(estado().fase, FaseObjetos.instrucciones);
    });

    test('repetir vuelve a las instrucciones del mismo nivel', () {
      juego().empezarPractica();
      responderTodas();
      juego().empezarPrueba();
      responderTodas();
      juego().repetir();
      expect(estado().fase, FaseObjetos.instrucciones);
      expect(estado().nivel.dificultad, Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
    });

    test('cambiar el nivel en las instrucciones cambia el tipo de pregunta', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      expect(estado().nivel.tipo, TipoPregunta.pareja);
      juego().empezarPractica();
      expect(estado().pregunta.enunciado, NivelObjetos.de(Dificultad.dificil).enunciado);
    });

    test('lee la pregunta con sus opciones y, tras responder, la explicación', () async {
      juego().empezarPractica();
      juego().escucharPregunta();
      await Future<void>.delayed(Duration.zero);
      final p = estado().pregunta;
      expect(voz.dichos.last, allOf(contains(p.objeto.nombre), contains(p.opciones.last.texto)));

      juego().responder(p.correcta);
      await Future<void>.delayed(Duration.zero);
      juego().escucharPregunta();
      await Future<void>.delayed(Duration.zero);
      expect(voz.dichos.last, p.explicacion);
    });
  });

  test('el juego queda en el catálogo, en memoria después de «Prepara el desayuno»', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final juego = c.read(juegoProvider(_id))!;
    expect(juego.dominio, Dominio.memoria);
    expect(c.read(juegosDeDominioProvider(Dominio.memoria)).map((j) => j.id), contains(_id));
  });
}
