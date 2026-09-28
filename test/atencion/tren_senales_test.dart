import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/atencion/tren_senales/models/generador_trenes.dart';
import 'package:vivamente/features/atencion/tren_senales/models/metricas_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/nivel_tren.dart';
import 'package:vivamente/features/atencion/tren_senales/models/tren.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';

import '../helpers/falsos.dart';

void main() {
  group('GeneradorTrenes', () {
    for (final d in Dificultad.values) {
      test('nivel ${d.nivel}: un tren a la vez, todos caben y ningún distractor es del color objetivo', () {
        final nivel = NivelTren.de(d);
        for (final objetivo in PaletaTren.objetivos) {
          final trenes = GeneradorTrenes(random: Random(1)).prueba(nivel, objetivo);

          expect(GeneradorTrenes.fin(nivel, trenes) <= nivel.duracion, isTrue);
          for (var i = 1; i < trenes.length; i++) {
            expect(trenes[i].salida - trenes[i - 1].salida >= nivel.cruce, isTrue);
          }
          expect(trenes.where((t) => t.esObjetivo).length, (trenes.length * nivel.proporcionObjetivo).round());
          for (final t in trenes) {
            expect(t.esObjetivo, t.locomotora == objetivo);
          }
        }
      });
    }

    test('el nivel 3 usa colores parecidos al objetivo y el 1 contrastantes', () {
      const o = ColorTren.azul;
      expect(NivelTren.de(Dificultad.dificil).distractoresPara(o), PaletaTren.parecidos(o));
      expect(NivelTren.de(Dificultad.facil).distractoresPara(o), hasLength(3));
      expect(NivelTren.de(Dificultad.medio).distractoresPara(o), hasLength(5));
    });

    test('el color objetivo cambia de un intento al siguiente en el mismo nivel', () {
      final g = GeneradorTrenes(random: Random(4));
      var anterior = g.elegirObjetivo(Dificultad.facil);
      final vistos = {anterior};
      for (var i = 0; i < 30; i++) {
        final nuevo = g.elegirObjetivo(Dificultad.facil);
        expect(nuevo, isNot(anterior));
        expect(PaletaTren.objetivos, contains(nuevo));
        vistos.add(nuevo);
        anterior = nuevo;
      }
      expect(vistos.length, greaterThan(2));
    });

    test('la práctica trae cuatro trenes, dos objetivo', () {
      final t = GeneradorTrenes(random: Random(3)).practica(NivelTren.de(Dificultad.medio), ColorTren.verde);
      expect(t, hasLength(NivelTren.trenesPractica));
      expect(t.where((x) => x.esObjetivo), hasLength(2));
    });
  });

  test('NivelTren describe su duración', () {
    expect(NivelTren.de(Dificultad.facil).etiquetaDuracion, '30 segundos');
    expect(NivelTren.de(Dificultad.medio).etiquetaDuracion, '1 minuto y medio');
    expect(NivelTren.de(Dificultad.dificil).etiquetaDuracion, '3 minutos');
  });

  test('MetricasTren arma el resultado', () {
    final m = const MetricasTren()
        .conAcierto(const Duration(milliseconds: 600))
        .conObjetivoCerrado(respondido: true)
        .conAcierto(const Duration(milliseconds: 1000))
        .conObjetivoCerrado(respondido: true)
        .conObjetivoCerrado(respondido: false)
        .conComision();

    final r = m.aResultado(duracion: const Duration(seconds: 30), dificultad: Dificultad.facil);
    expect(r.aciertos, 2);
    expect(r.omisiones, 1);
    expect(r.errores, 1);
    expect(r.latenciaPromedio, 800);
    expect(r.puntajeBruto, 1);
    expect(r.puntajeMaximo, 3);
    expect(r.dificultad, Dificultad.facil);
  });

  group('TrenSenalesNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late ProviderContainer c;
    late ProviderSubscription<TrenSenalesState> sub;

    // Secuencia fija: objetivo, distractor, objetivo.
    List<Tren> secuencia(NivelTren n, ColorTren objetivo) => [
          for (final (i, esObjetivo) in [true, false, true].indexed)
            Tren(
              id: i,
              locomotora: esObjetivo ? objetivo : n.distractoresPara(objetivo).first,
              vagones: const [ColorTren.relleno],
              salida: NivelTren.arranque + n.paso * i,
              esObjetivo: esObjetivo,
            ),
        ];

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        generadorTrenesProvider.overrideWithValue(_GeneradorFijo(secuencia)),
      ]);
      sub = c.listen(trenSenalesProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    TrenSenalesNotifier juego() => c.read(trenSenalesProvider.notifier);
    TrenSenalesState estado() => c.read(trenSenalesProvider);

    void avanzar(int ms) {
      reloj.avanzar(Duration(milliseconds: ms));
      juego().actualizar();
    }

    test('toma el nivel elegido y sortea un color objetivo válido', () {
      c.read(dificultadJuegoProvider(TrenSenalesGame.idJuego).notifier).elegir(Dificultad.dificil);
      expect(estado().nivel.dificultad, Dificultad.dificil);
      expect(estado().nivel.duracion, const Duration(minutes: 3));
      expect(PaletaTren.objetivos, contains(estado().objetivo));
      expect(PaletaTren.parecidos(estado().objetivo), contains(estado().ejemploDistractor));
    });

    test('lee la instrucción con el color del intento', () async {
      juego().escucharInstruccion();
      await Future<void>.delayed(Duration.zero);
      expect(voz.dichos.single, contains('tren ${estado().objetivo.etiqueta}'));
      expect(c.read(lecturaProvider), EstadoLectura.leyendo);
    });

    test('registra métricas y da refuerzo en cada caso también en la ronda medida', () {
      final n = estado().nivel;
      juego().empezarPrueba();

      // Objetivo en la vía; señal 400 ms después: refuerzo positivo.
      avanzar(NivelTren.arranque.inMilliseconds);
      avanzar(400);
      juego().senal();
      expect(estado().retro, RetroTren.bien);
      final idAcierto = estado().retroId;
      juego().senal(); // repetir por el mismo tren no cuenta
      expect(estado().metricas.aciertos, 1);
      expect(estado().metricas.comisiones, 0);
      expect(estado().metricas.latencias.single, const Duration(milliseconds: 400));

      // Distractor y señal: falsa alarma con refuerzo negativo.
      avanzar(n.paso.inMilliseconds);
      expect(estado().enVia?.esObjetivo, isFalse);
      juego().senal();
      expect(estado().metricas.comisiones, 1);
      expect(estado().retro, RetroTren.noEra);
      expect(estado().retroId, greaterThan(idAcierto));

      // El segundo objetivo se deja pasar: omisión con aviso.
      avanzar(n.paso.inMilliseconds);
      expect(estado().enVia?.esObjetivo, isTrue);
      avanzar(n.cruce.inMilliseconds);
      expect(estado().metricas.omisiones, 1);
      expect(estado().retro, RetroTren.sePaso);
      expect(estado().senales, 3);

      avanzar(n.duracion.inMilliseconds);
      expect(estado().fase, FaseTren.resultado);
      final r = estado().resultado!;
      expect(r.aciertos, 1);
      expect(r.omisiones, 1);
      expect(r.errores, 1);
      expect(r.latenciaPromedio, 400);
      expect(r.puntajeMaximo, 2);
    });

    test('en pausa el tiempo no corre y las señales no cuentan', () {
      juego().empezarPrueba();
      avanzar(2000);
      juego().pausar();
      expect(estado().pausado, isTrue);
      avanzar(10000);
      juego().senal();
      expect(estado().transcurrido, const Duration(milliseconds: 2000));
      expect(estado().metricas.comisiones, 0);
      juego().reanudar();
      avanzar(1000);
      expect(estado().transcurrido, const Duration(milliseconds: 3000));
    });

    test('la práctica da pistas y termina en su propia pantalla', () {
      juego().empezarPractica();
      avanzar(NivelTren.arranque.inMilliseconds);
      expect(estado().mostrarAhora, isTrue);
      juego().senal();
      expect(estado().retro, RetroTren.bien);
      expect(estado().mostrarAhora, isFalse);

      avanzar(60000);
      expect(estado().fase, FaseTren.finPractica);
      expect(estado().resultado, isNull);
      expect(estado().senales, 0);
    });
  });
}

class _GeneradorFijo extends GeneradorTrenes {
  _GeneradorFijo(this._armar);

  final List<Tren> Function(NivelTren, ColorTren) _armar;

  @override
  List<Tren> prueba(NivelTren nivel, ColorTren objetivo) => _armar(nivel, objetivo);

  @override
  List<Tren> practica(NivelTren nivel, ColorTren objetivo) => _armar(nivel.practica, objetivo);
}
