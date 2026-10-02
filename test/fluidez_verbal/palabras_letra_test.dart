import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

    test('en el dictado quita conectores y relleno; lo escrito queda entero', () {
      final palabras = ['eh', 'la', 'mesa', 'y', 'pues', 'mano'];
      expect(EvaluadorPalabras.cortar(palabras, dictado: true), [(texto: 'mesa', inicio: 2), (texto: 'mano', inicio: 5)]);
      expect(EvaluadorPalabras.cortar(['la'], dictado: false), [(texto: 'la', inicio: 0)]);
    });

    test('evalúa la ronda en orden: lo descartado no hace repetir y lo aceptado sí', () {
      const ninguno = Ajuste.ninguno;
      expect(EvaluadorPalabras.evaluarTodas(['mesa', 'mesas', 'casa'], 'M', [ninguno, ninguno, ninguno]),
          [Veredicto.valida, Veredicto.repetida, Veredicto.otraLetra]);
      // Si la primera «mesa» fue un error del micrófono, la segunda vale.
      expect(EvaluadorPalabras.evaluarTodas(['mesa', 'mesas'], 'M', [Ajuste.descartada, ninguno]),
          [Veredicto.valida, Veredicto.valida]);
      // Lo que no se ajustó sigue su veredicto, aunque haya otras aceptadas.
      expect(EvaluadorPalabras.evaluarTodas(['casa', 'mesa', 'mesa'], 'M', [Ajuste.aceptada, ninguno, ninguno]),
          [Veredicto.otraLetra, Veredicto.valida, Veredicto.repetida]);
    });
  });

  group('Transcripcion', () {
    const s = Duration(seconds: 1);
    List<String> textos(Transcripcion t) =>
        [for (final r in t.respuestas(EvaluadorPalabras.cortar)) r.texto];

    test('cada envío del reconocedor reemplaza lo anterior de su escucha', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'pera', s);
      t.poner(e, 'perra gato', s * 2);
      expect(textos(t), ['perra', 'gato']);
      // La palabra corregida conserva el momento en que se oyó.
      expect(t.respuestas(EvaluadorPalabras.cortar).map((r) => r.momento), [s, s * 2]);
    });

    test('lo que llega tarde de una escucha anterior no se duplica', () {
      final t = Transcripcion();
      final primera = t.abrir(dictado: true);
      t.poner(primera, 'mesa', s);
      final segunda = t.abrir(dictado: true);
      t.poner(segunda, 'mano', s * 3);
      t.poner(primera, 'mesa mapa', s * 4);
      expect(textos(t), ['mesa', 'mano', 'mapa']);
    });

    test('un resultado vacío no borra lo oído', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'mesa mano', s);
      t.poner(e, '', s * 2, esFinal: true);
      t.poner(e, '', s * 3);
      expect(textos(t), ['mesa', 'mano']);
    });

    test('si el reconocedor empieza de cero tras una pausa, lo anterior se queda', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'mesa', s);
      t.poner(e, 'mesa mano', s * 2);
      // Tras la pausa solo manda la frase nueva, sin final de la anterior.
      t.poner(e, 'mapa', s * 5);
      t.poner(e, 'mapa mora', s * 6);
      expect(textos(t), ['mesa', 'mano', 'mapa', 'mora']);
      // Aunque la frase nueva empiece igual que la anterior.
      t.poner(e, 'mapa', s * 9);
      expect(textos(t), ['mesa', 'mano', 'mapa', 'mora', 'mapa']);
    });

    test('tras una pausa, una palabra parecida es otra respuesta', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'mar', s);
      t.poner(e, 'mal', s * 4);
      t.poner(e, 'mal', s * 5, esFinal: true);
      expect(textos(t), ['mar', 'mal']);
    });

    test('el final puede intercalar conectores sin duplicar la frase', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'moto muro', s);
      t.poner(e, 'moto y la muro', s * 3, esFinal: true);
      expect(textos(t), ['moto', 'muro']);
    });

    test('tras un final, lo que repite lo ya cerrado no se duplica', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'mesa mano', s, esFinal: true);
      t.poner(e, 'mesa mano mapa', s * 2);
      t.poner(e, 'mesa mano mapa', s * 3, esFinal: true);
      expect(textos(t), ['mesa', 'mano', 'mapa']);
      // El que empieza de cero tras el final también sirve.
      t.poner(e, 'mora', s * 4, esFinal: true);
      expect(textos(t), ['mesa', 'mano', 'mapa', 'mora']);
    });

    test('las correcciones rápidas y el final corrigen la frase sin duplicarla', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'man', s);
      t.poner(e, 'mano mesas', s * 2);
      t.poner(e, 'mano', s * 2 + const Duration(milliseconds: 300));
      t.poner(e, 'mano mesa', s * 6, esFinal: true);
      expect(textos(t), ['mano', 'mesa']);
    });

    test('el final que llega a la escucha siguiente corrige la anterior', () {
      final t = Transcripcion();
      final primera = t.abrir(dictado: true);
      t.poner(primera, 'mesa man', s);
      final segunda = t.abrir(dictado: true);
      t.poner(segunda, 'mesa mano', s * 2, esFinal: true);
      t.poner(segunda, 'mapa', s * 3);
      expect(textos(t), ['mesa', 'mano', 'mapa']);
    });

    test('lo escrito mientras el micrófono escucha queda en su lugar', () {
      final t = Transcripcion();
      final e = t.abrir(dictado: true);
      t.poner(e, 'mesa', s);
      t.poner(t.abrir(dictado: false), 'mano', s * 2);
      t.poner(e, 'mesa mapa', s * 3);
      expect(textos(t), ['mesa', 'mano', 'mapa']);
      expect(t.respuestas(EvaluadorPalabras.cortar).map((r) => r.dictada), [true, false, true]);
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

  test('MetricasPalabras cuenta según lo revisado', () {
    const t = Duration(seconds: 1);
    final m = MetricasPalabras.contar(
      meta: 10,
      respuestas: const [RespuestaOida('mesa', t), RespuestaOida('casa', t), RespuestaOida('ruido', t)],
      veredictos: const [Veredicto.valida, Veredicto.otraLetra, Veredicto.otraLetra],
      ajustes: const [Ajuste.ninguno, Ajuste.aceptada, Ajuste.descartada],
      tiempo: const Duration(seconds: 60),
    );
    expect(m.palabras.map((p) => p.texto), ['mesa', 'casa']);
    expect(m.errores, 0);
    expect(m.tiempo, const Duration(seconds: 60));
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

    /// Una palabra que no empieza con la letra de la ronda.
    String otra() => estado().letra == 'Z' ? 'casa' : 'zapato';

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
      expect(estado().oidas, isEmpty);
      expect(estado().textoTiempo, '01:30');
    });

    test('durante la ronda solo se anota; al terminar se evalúa todo', () async {
      empezar();
      expect(escribir('   '), isFalse);
      expect(escribir(' ${l()}ar '), isTrue);
      escribir('${l()}ar');
      escribir(otra());
      expect(estado().oidas, ['${l()}ar', '${l()}ar', otra()]);
      expect(estado().metricas.validas, 0);

      await juego().terminar();
      expect(estado().fase, FasePalabras.revision);
      expect(estado().veredictos, [Veredicto.valida, Veredicto.repetida, Veredicto.otraLetra]);
      expect(estado().metricas.validas, 1);
      expect(estado().metricas.repetidas, 1);
      expect(estado().metricas.otraLetra, 1);
      // Aún no se registra: falta confirmar la revisión.
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
    });

    test('el dictado se muestra al instante y cuenta la versión corregida', () async {
      empezar();
      await juego().alternarMicrofono();
      expect(estado().escuchando, isTrue);
      expect(estado().conectado, isTrue);

      dictado.oir('${l()}ota', esFinal: false);
      expect(estado().oidas, ['${l()}ota']);

      // El reconocedor corrige lo que llevaba: no queda la primera versión.
      dictado.oir('${l()}oto ${l()}uro', esFinal: false);
      expect(estado().oidas, ['${l()}oto', '${l()}uro']);
      dictado.oir('${l()}oto y la ${l()}uro');
      expect(estado().oidas, ['${l()}oto', '${l()}uro']);

      await juego().terminar();
      expect(estado().metricas.palabras.map((p) => p.texto), ['${l()}oto', '${l()}uro']);
      expect(estado().metricas.palabras.every((p) => p.dictada), isTrue);
      expect(estado().metricas.repetidas, 0);
    });

    test('las palabras dictadas se quedan aunque el reconocedor mande vacío o empiece de cero', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir('${l()}ar ${l()}ono', esFinal: false);
      avanzar(3000);
      dictado.oir('');
      dictado.oir('${l()}ata', esFinal: false);
      avanzar(3000);
      dictado.oir('', esFinal: true);
      expect(estado().oidas, ['${l()}ar', '${l()}ono', '${l()}ata']);

      await juego().terminar();
      expect(estado().metricas.validas, 3);
    });

    test('cada palabra conserva el momento en que se oyó', () async {
      empezar();
      await juego().alternarMicrofono();
      avanzar(1000);
      dictado.oir('${l()}ar', esFinal: false);
      avanzar(2000);
      dictado.oir('${l()}ar ${l()}ono');
      await juego().terminar();
      expect(estado().respuestas.map((r) => r.momento), const [Duration(seconds: 1), Duration(seconds: 3)]);
    });

    test('lo que llega tarde de una escucha anterior no se cuenta dos veces', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir('${l()}ar', esFinal: false);

      dictado.cerrarSolo();
      expect(estado().conectado, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 2);
      expect(estado().conectado, isTrue);

      dictado.oir('${l()}ono');
      // El final de la primera escucha llega después de reabrir.
      dictado.oirEn(0, '${l()}ar');
      expect(estado().oidas, ['${l()}ar', '${l()}ono']);

      await juego().terminar();
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.repetidas, 0);
    });

    test('al terminar espera lo último que oyó el micrófono', () async {
      empezar();
      escribir('${l()}ar');
      await juego().alternarMicrofono();
      dictado.oir('${l()}ono', esFinal: false);
      avanzar(89000);
      expect(estado().jugando, isTrue);
      avanzar(1000);
      await pumpEventQueue();

      expect(estado().fase, FasePalabras.revision);
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.tiempo, const Duration(seconds: 90));
      expect(dictado.escuchando, isFalse);
      // Lo que llegue del micrófono después ya no cuenta.
      dictado.oir('${l()}esa');
      expect(estado().respuestas, hasLength(2));
    });

    test('si el reconocedor no entrega el final, cuenta lo que alcanzó a oír', () async {
      dictado.entregaFinal = false;
      empezar();
      await juego().alternarMicrofono();
      dictado.oir('${l()}ono', esFinal: false);
      await juego().terminar();
      expect(estado().fase, FasePalabras.revision);
      expect(estado().metricas.validas, 1);
    });

    test('quien revisa puede quitar o aceptar palabras y luego se registra', () async {
      empezar();
      escribir('${l()}ar');
      escribir('${l()}ar');
      escribir(otra());
      await juego().terminar();

      // La primera fue un error del micrófono: la segunda ya no es repetida.
      juego().ajustar(0, Ajuste.descartada);
      expect(estado().veredictos, [Veredicto.valida, Veredicto.valida, Veredicto.otraLetra]);
      juego().ajustar(2, Ajuste.aceptada);
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.errores, 0);

      juego().ajustar(2, Ajuste.ninguno);
      expect(estado().metricas.validas, 1);

      juego().confirmar();
      expect(estado().fase, FasePalabras.resultado);
      expect(estado().resultado!.aciertos, 1);
      expect(estado().resultado!.errores, 1);
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().resultado!.puntajeMaximo, NivelPalabras.de(Dificultad.facil).meta);
    });

    test('sin palabras no hay nada que revisar: va directo al resultado', () async {
      empezar();
      await juego().terminar();
      expect(estado().fase, FasePalabras.resultado);
      expect(estado().resultado!.aciertos, 0);
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
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

      await juego().alternarMicrofono();
      expect(estado().escuchando, isFalse);
      expect(estado().conectado, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 2);
      expect(dictado.escuchando, isFalse);
    });

    test('en pausa el micrófono se cierra sin perder lo oído y al reanudar vuelve a abrirse', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir('${l()}ar', esFinal: false);
      juego().pausar();
      expect(dictado.escuchando, isFalse);
      expect(estado().escuchando, isTrue);
      expect(estado().conectado, isFalse);
      expect(estado().oidas, ['${l()}ar']);
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(dictado.aperturas, 1);

      juego().reanudar();
      await Future<void>.delayed(Duration.zero);
      expect(dictado.aperturas, 2);
      expect(dictado.escuchando, isTrue);
      dictado.oir('${l()}ono');
      expect(estado().oidas, ['${l()}ar', '${l()}ono']);
    });

    test('sin micrófono se avisa y se puede seguir escribiendo', () async {
      dictado.disponible = false;
      empezar();
      await juego().alternarMicrofono();
      expect(estado().escuchando, isFalse);
      expect(estado().avisoDictado, 1);
      expect(escribir('${l()}ar'), isTrue);
    });

    test('terminar antes de tiempo guarda el tiempo usado', () async {
      empezar();
      avanzar(20000);
      escribir('${l()}ar');
      await juego().terminar();
      juego().confirmar();
      expect(estado().fase, FasePalabras.resultado);
      expect(estado().metricas.tiempo, const Duration(seconds: 20));
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
    });

    test('en pausa el tiempo no corre ni se puede escribir', () {
      empezar();
      avanzar(5000);
      juego().pausar();
      avanzar(20000);
      expect(escribir('${l()}ar'), isFalse);
      expect(estado().oidas, isEmpty);
      expect(estado().transcurrido, const Duration(seconds: 5));
      juego().reanudar();
      avanzar(1000);
      expect(estado().textoTiempo, '01:24');
    });

    test('repetir arma otro intento del mismo nivel con otra letra', () async {
      final antes = estado().letra;
      empezar();
      escribir('${l()}ar');
      await juego().terminar();
      juego().confirmar();
      juego().repetir();

      expect(estado().fase, FasePalabras.instrucciones);
      expect(estado().letra, isNot(antes));
      expect(estado().nivel.dificultad, Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
      expect(estado().metricas.validas, 0);

      // La ronda nueva empieza sin lo anterior.
      empezar();
      expect(estado().oidas, isEmpty);
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
