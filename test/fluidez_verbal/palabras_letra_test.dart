import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/evaluador_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/metricas_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/nivel_palabras.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/models/sorteo_letra.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/palabras_letra_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_letra/providers/palabras_letra_provider.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

import '../helpers/falsos.dart';

const _id = PalabrasLetraGame.idJuego;

void main() {
  group('EvaluadorPalabras', () {
    Veredicto evaluar(String p, [List<String> aceptadas = const []]) => EvaluadorPalabras.evaluar(p, 'M', aceptadas);

    test('acepta palabras que empiezan con la letra, con o sin tilde', () {
      expect(evaluar('mesa'), Veredicto.valida);
      expect(evaluar('Mamá'), Veredicto.valida);
      expect(EvaluadorPalabras.evaluar('árbol', 'A', const []), Veredicto.valida);
    });

    test('rechaza otra letra; la Ñ no es la N', () {
      expect(evaluar('casa'), Veredicto.otraLetra);
      expect(EvaluadorPalabras.evaluar('ñandú', 'N', const []), Veredicto.otraLetra);
      expect(EvaluadorPalabras.evaluar('nube', 'N', const []), Veredicto.valida);
    });

    test('repetir, cambiar la tilde o decir el plural cuenta como repetida', () {
      expect(evaluar('mesa', ['mesa']), Veredicto.repetida);
      expect(evaluar('mama', ['mamá']), Veredicto.repetida);
      expect(evaluar('mesas', ['mesa']), Veredicto.repetida);
      expect(evaluar('mes', ['meses']), Veredicto.repetida);
      expect(EvaluadorPalabras.evaluar('luces', 'L', const ['luz']), Veredicto.repetida);
      // Cambiar el género es otra palabra (pera / pero).
      expect(evaluar('mono', ['mona']), Veredicto.valida);
    });

    test('no son palabras: una letra, números, sin vocales o letras triplicadas', () {
      expect(evaluar('m'), Veredicto.noEsPalabra);
      expect(evaluar('m3sa'), Veredicto.noEsPalabra);
      expect(evaluar('mbrr'), Veredicto.noEsPalabra);
      expect(evaluar('maaar'), Veredicto.noEsPalabra);
    });

    test('separa un dictado en palabras sueltas', () {
      expect(EvaluadorPalabras.separar('Mesa, mano y  mapa.'), ['mesa', 'mano', 'y', 'mapa']);
    });
  });

  test('ningún nivel asigna la letra del ejemplo y la letra no se repite seguida', () {
    for (final d in Dificultad.values) {
      expect(NivelPalabras.de(d).letras, isNot(contains(NivelPalabras.letraEjemplo)));
    }
    final sorteo = SorteoLetra(random: Random(3));
    final nivel = NivelPalabras.de(Dificultad.medio);
    var anterior = sorteo.elegir(nivel);
    for (var i = 0; i < 30; i++) {
      final nueva = sorteo.elegir(nivel);
      expect(nueva, isNot(anterior));
      expect(nivel.letras, contains(nueva));
      anterior = nueva;
    }
  });

  test('MetricasPalabras calcula puntaje, ritmo y tramos', () {
    const t = Duration(seconds: 1);
    var m = const MetricasPalabras(meta: 10);
    for (final s in [5, 10, 20, 40]) {
      m = m.anotar(Veredicto.valida, PalabraDicha('m$s', t * s));
    }
    m = m
        .anotar(Veredicto.repetida, const PalabraDicha('x', t))
        .anotar(Veredicto.otraLetra, const PalabraDicha('x', t))
        .conTiempo(const Duration(seconds: 60));

    expect(m.validas, 4);
    expect(m.errores, 2);
    expect(m.puntaje, 40);
    expect(m.ritmoMs, 10000); // 40 s / 4 palabras
    expect(m.porTramo(const Duration(seconds: 60)), [2, 1, 1, 0]);

    final r = m.aResultado(Dificultad.facil);
    expect(r.aciertos, 4);
    expect(r.errores, 2);
    expect(r.puntajeBruto, 4);
    expect(r.puntajeMaximo, 10);
    expect(r.puntajeNormalizado, 40);
    expect(formatoReloj(const Duration(seconds: 90)), '01:30');
  });

  group('PalabrasLetraNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late DictadoFalso dictado;
    late ProviderContainer c;
    late ProviderSubscription<PalabrasLetraState> sub;

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      dictado = DictadoFalso();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        dictadoProvider.overrideWithValue(dictado),
        sorteoLetraProvider.overrideWithValue(SorteoLetra(random: Random(7))),
      ]);
      sub = c.listen(palabrasLetraProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    PalabrasLetraNotifier juego() => c.read(palabrasLetraProvider.notifier);
    PalabrasLetraState estado() => c.read(palabrasLetraProvider);
    String l() => estado().letra.toLowerCase();

    bool escribir(String palabra) => juego().anadir(palabra);

    void avanzar(int ms) {
      reloj.avanzar(Duration(milliseconds: ms));
      juego().actualizar();
    }

    /// Empezar y dejar pasar la letra en grande.
    void empezar() {
      juego().iniciar();
      avanzar(PalabrasLetraNotifier.presentacion.inMilliseconds);
    }

    test('al empezar muestra y dice la letra unos segundos antes de correr el tiempo', () async {
      juego().iniciar();
      await Future<void>.delayed(Duration.zero);
      expect(estado().fase, FasePalabras.presentacion);
      expect(estado().cuentaAtras, 3);
      expect(voz.dichos.last, 'Su letra es la ${estado().letra}.');
      expect(escribir('${l()}ar'), isFalse);

      avanzar(1200);
      expect(estado().cuentaAtras, 2);
      avanzar(1800);
      expect(estado().fase, FasePalabras.jugando);
      // La ronda arranca desde cero, sin descontar la presentación.
      expect(estado().textoTiempo, '01:30');
      avanzar(1000);
      expect(estado().textoTiempo, '01:29');
    });

    test('no se puede escribir antes de empezar', () {
      expect(escribir('${l()}ano'), isFalse);
      expect(estado().metricas.validas, 0);
      expect(estado().textoTiempo, '01:30');
    });

    test('escribir registra la palabra y da el refuerzo', () {
      empezar();
      expect(escribir('   '), isFalse);
      expect(escribir(' ${l()}ar '), isTrue);

      expect(estado().metricas.palabras.single.texto, '${l()}ar');
      expect(estado().retro, Veredicto.valida);

      escribir('${l()}ar');
      expect(estado().metricas.validas, 1);
      expect(estado().metricas.repetidas, 1);
      expect(estado().retro, Veredicto.repetida);

      // El refuerzo se apaga solo.
      avanzar(1700);
      expect(estado().retro, isNull);
    });

    test('una palabra con otra letra no cuenta y se anota como intrusión', () {
      empezar();
      final otra = estado().letra == 'Z' ? 'casa' : 'zapato';
      escribir(otra);
      expect(estado().metricas.validas, 0);
      expect(estado().metricas.otraLetra, 1);
      expect(estado().retro, Veredicto.otraLetra);
      expect(estado().palabraRetro, otra);
    });

    test('el dictado muestra lo que oye y al final registra cada palabra', () async {
      empezar();
      await juego().alternarMicrofono();
      expect(estado().escuchando, isTrue);

      dictado.oir('${l()}ota', esFinal: false);
      expect(estado().parcial, '${l()}ota');
      expect(estado().metricas.validas, 0);

      dictado.oir('${l()}ota y ${l()}uro ${l()}ota');
      expect(estado().parcial, isEmpty);
      expect(estado().metricas.palabras.map((p) => p.texto), ['${l()}ota', '${l()}uro']);
      expect(estado().metricas.palabras.every((p) => p.dictada), isTrue);
      expect(estado().metricas.repetidas, 1);
      // Si en el dictado hubo alguna válida, el refuerzo es positivo.
      expect(estado().retro, Veredicto.valida);

      await juego().alternarMicrofono();
      expect(estado().escuchando, isFalse);
    });

    test('con el micrófono encendido las palabras se guardan solas, sin tocar nada', () async {
      empezar();
      await juego().alternarMicrofono();

      dictado.oir('${l()}ar', esFinal: false);
      avanzar(500);
      expect(estado().metricas.validas, 0);
      expect(estado().parcial, '${l()}ar');

      // Un momento sin cambios y la palabra queda guardada.
      avanzar(500);
      expect(estado().metricas.palabras.map((p) => p.texto), ['${l()}ar']);
      expect(estado().parcial, isEmpty);
      expect(estado().escuchando, isTrue);

      // El reconocedor sigue acumulando: solo se guarda lo nuevo.
      dictado.oir('${l()}ar ${l()}ono', esFinal: false);
      expect(estado().parcial, '${l()}ono');
      avanzar(1000);
      expect(estado().metricas.palabras.map((p) => p.texto), ['${l()}ar', '${l()}ono']);

      // El final repite lo ya guardado: no cuenta como repetición.
      dictado.oir('${l()}ar ${l()}ono');
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.repetidas, 0);
    });

    test('al pausar se guarda lo que el dictado alcanzó a oír', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir('${l()}ar', esFinal: false);
      juego().pausar();
      expect(estado().metricas.validas, 1);
      dictado.oir('${l()}ar');
      expect(estado().metricas.validas, 1);
      expect(estado().metricas.repetidas, 0);
    });

    test('el micrófono se reabre solo tras un silencio hasta que se apague', () async {
      empezar();
      await juego().alternarMicrofono();
      expect(dictado.aperturas, 1);

      dictado.cerrarSolo();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 2);
      expect(dictado.escuchando, isTrue);
      expect(estado().escuchando, isTrue);

      // Lo que llega tras reabrir sigue contando.
      dictado.oir('${l()}ar');
      expect(estado().metricas.validas, 1);

      await juego().alternarMicrofono();
      expect(estado().escuchando, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 2);
      expect(dictado.escuchando, isFalse);
    });

    test('en pausa el micrófono se cierra y al reanudar vuelve a abrirse', () async {
      empezar();
      await juego().alternarMicrofono();
      juego().pausar();
      expect(dictado.escuchando, isFalse);
      expect(estado().escuchando, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 1);

      juego().reanudar();
      await Future<void>.delayed(Duration.zero);
      expect(dictado.aperturas, 2);
      expect(dictado.escuchando, isTrue);
    });

    test('sin micrófono se avisa y se puede seguir escribiendo', () async {
      dictado.disponible = false;
      empezar();
      await juego().alternarMicrofono();
      expect(estado().escuchando, isFalse);
      expect(estado().avisoDictado, 1);
    });

    test('quitar una palabra la saca de la cuenta', () {
      empezar();
      escribir('${l()}ar');
      escribir('${l()}ono');
      juego().quitar(0);
      expect(estado().metricas.palabras.single.texto, '${l()}ono');
    });

    test('termina al acabar el tiempo, cuenta lo que el dictado oía y registra solo ese nivel', () async {
      empezar();
      escribir('${l()}ar');
      await juego().alternarMicrofono();
      dictado.oir('${l()}ono', esFinal: false);
      avanzar(89000);
      expect(estado().jugando, isTrue);
      avanzar(1000);

      expect(estado().fase, FasePalabras.resultado);
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.tiempo, const Duration(seconds: 90));
      expect(dictado.escuchando, isFalse);
      // Lo que llegue del micrófono después ya no cuenta.
      dictado.oir('${l()}esa');
      expect(estado().metricas.validas, 2);

      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FasePalabras.resultado);
      expect(estado().resultado!.aciertos, 2);
      expect(estado().resultado!.puntajeMaximo, NivelPalabras.de(Dificultad.facil).meta);
    });

    test('terminar antes de tiempo guarda el tiempo usado', () {
      empezar();
      avanzar(20000);
      escribir('${l()}ar');
      juego().terminar();
      expect(estado().fase, FasePalabras.resultado);
      expect(estado().metricas.tiempo, const Duration(seconds: 20));
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
    });

    test('en pausa el tiempo no corre ni se puede escribir', () {
      empezar();
      avanzar(5000);
      juego().pausar();
      avanzar(20000);
      escribir('${l()}ar');
      expect(estado().metricas.validas, 0);
      expect(estado().transcurrido, const Duration(seconds: 5));
      juego().reanudar();
      avanzar(1000);
      expect(estado().textoTiempo, '01:24');
    });

    test('repetir arma otro intento del mismo nivel con otra letra', () {
      final antes = estado().letra;
      empezar();
      juego().terminar();
      juego().repetir();

      expect(estado().fase, FasePalabras.instrucciones);
      expect(estado().letra, isNot(antes));
      expect(estado().nivel.dificultad, Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
      expect(estado().metricas.validas, 0);
    });

    test('cambiar el nivel en las instrucciones cambia letra, tiempo y meta', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      final nivel = NivelPalabras.de(Dificultad.dificil);
      expect(estado().nivel.dificultad, Dificultad.dificil);
      expect(nivel.letras, contains(estado().letra));
      expect(estado().textoTiempo, '01:00');
      expect(estado().metricas.meta, nivel.meta);
    });

    test('lee la instrucción sin revelar la letra de la ronda', () async {
      juego().escucharInstruccion();
      await Future<void>.delayed(Duration.zero);
      expect(voz.dichos.single, contains('90 segundos'));
      expect(voz.dichos.single, isNot(contains('letra ${estado().letra}')));
    });
  });

  test('el juego queda en el catálogo, en fluidez verbal', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final juego = c.read(juegoProvider(_id))!;
    expect(juego.dominio, Dominio.fluidezVerbal);
    expect(c.read(juegosDeDominioProvider(Dominio.fluidezVerbal)).first.id, _id);
  });
}
