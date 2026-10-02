import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/fluidez_verbal/comun/transcripcion.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/evaluador_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/metricas_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/nivel_categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

import '../helpers/falsos.dart';

const _id = PalabrasCategoriaGame.idJuego;

Evaluacion _evaluar(String p, Categoria c, [List<String> aceptadas = const []]) =>
    EvaluadorCategoria.evaluar(p, c, aceptadas);

void main() {
  group('EvaluadorCategoria', () {
    test('acepta la palabra sin importar tildes ni mayúsculas', () {
      expect(_evaluar('Perro', Categoria.animales).veredicto, Veredicto.valida);
      expect(_evaluar('raton', Categoria.animales).palabra, 'ratón');
      expect(_evaluar('BOGOTA', Categoria.ciudades).palabra, 'Bogotá');
      expect(_evaluar('maracuya', Categoria.frutas).palabra, 'maracuyá');
    });

    test('reconoce plurales y, donde aplica, el femenino', () {
      expect(_evaluar('perros', Categoria.animales).palabra, 'perro');
      expect(_evaluar('ratones', Categoria.animales).palabra, 'ratón');
      expect(_evaluar('peces', Categoria.animales).palabra, 'pez');
      expect(_evaluar('gata', Categoria.animales).palabra, 'gato');
      expect(_evaluar('doctora', Categoria.profesiones).palabra, 'doctor');
      expect(_evaluar('enfermeras', Categoria.profesiones).palabra, 'enfermero');
      expect(_evaluar('actriz', Categoria.profesiones).palabra, 'actor');
      expect(_evaluar('leona', Categoria.animales).palabra, 'león');
      expect(_evaluar('tomates de árbol', Categoria.frutas).palabra, 'tomate de árbol');
      expect(_evaluar('roja', Categoria.colores).palabra, 'rojo');
    });

    test('la misma palabra en otra forma cuenta como repetida', () {
      expect(_evaluar('perras', Categoria.animales, ['perro']).veredicto, Veredicto.repetida);
      expect(_evaluar('banana', Categoria.frutas, ['banano']).veredicto, Veredicto.repetida);
      // Palabras distintas no se confunden.
      expect(_evaluar('gallo', Categoria.animales, ['gallina']).veredicto, Veredicto.valida);
    });

    test('una palabra de otra categoría es intrusión y dice de cuál', () {
      final e = _evaluar('manzana', Categoria.animales);
      expect(e.veredicto, Veredicto.otraCategoria);
      expect(e.categoria, Categoria.frutas);
      expect(_evaluar('silla', Categoria.frutas).categoria, Categoria.hogar);
    });

    test('lo que no está en ningún diccionario queda como no reconocido', () {
      final e = _evaluar('xyzw', Categoria.animales);
      expect(e.veredicto, Veredicto.noReconocida);
      expect(e.palabra, 'xyzw');
    });

    test('separa lo dictado en respuestas, con frases de varias palabras y sin relleno', () {
      expect(EvaluadorCategoria.separar('perro, gato y el oso hormiguero', Categoria.animales),
          ['perro', 'gato', 'oso hormiguero']);
      expect(EvaluadorCategoria.separar('Santa Marta Cali y San Andrés', Categoria.ciudades),
          ['santa marta', 'cali', 'san andres']);
      expect(EvaluadorCategoria.separar('eh bueno una estrella de mar', Categoria.animales), ['estrella de mar']);
    });

    test('al cortar dice dónde empieza cada respuesta', () {
      expect(EvaluadorCategoria.cortar(['eh', 'el', 'oso', 'hormiguero', 'y', 'gato'], Categoria.animales),
          [(texto: 'oso hormiguero', inicio: 2), (texto: 'gato', inicio: 5)]);
    });

    test('evalúa la ronda en orden: lo descartado no hace repetir y lo aceptado sí', () {
      const n = Ajuste.ninguno;
      List<Veredicto> evaluar(List<String> r, List<Ajuste> a) =>
          EvaluadorCategoria.evaluarTodas(r, Categoria.animales, a).map((e) => e.veredicto).toList();
      expect(evaluar(['perro', 'perros'], [n, n]), [Veredicto.valida, Veredicto.repetida]);
      expect(evaluar(['perro', 'perros'], [Ajuste.descartada, n]), [Veredicto.valida, Veredicto.valida]);
      // Una aceptada cuenta para las repeticiones de las siguientes.
      expect(evaluar(['perro', 'perro'], [Ajuste.aceptada, n]), [Veredicto.valida, Veredicto.repetida]);
    });

    test('ninguna categoría tiene palabras repetidas', () {
      for (final c in Categoria.values) {
        final normalizadas = c.palabras.map(EvaluadorCategoria.normalizar).toList();
        expect(normalizadas.toSet(), hasLength(normalizadas.length), reason: c.nombre);
      }
    });
  });

  test('SorteoCategoria no repite la categoría anterior si hay otra', () {
    final s = SorteoCategoria(random: Random(1));
    final nivel = NivelCategoria.de(Dificultad.facil);
    var anterior = s.elegir(nivel);
    for (var i = 0; i < 20; i++) {
      final c = s.elegir(nivel);
      expect(c, isNot(anterior));
      expect(nivel.categorias, contains(c));
      anterior = c;
    }
    // Con una sola categoría, se repite.
    expect(s.elegir(NivelCategoria.de(Dificultad.dificil)), Categoria.ciudades);
    expect(s.elegir(NivelCategoria.de(Dificultad.dificil)), Categoria.ciudades);
  });

  test('MetricasCategoria cuenta válidas, errores, puntaje y tramos', () {
    var m = const MetricasCategoria(meta: 10);
    m = m
        .anotar(_evaluar('perro', Categoria.animales), const Duration(seconds: 5))
        .anotar(_evaluar('gato', Categoria.animales), const Duration(seconds: 20))
        .anotar(_evaluar('perro', Categoria.animales, ['perro']), const Duration(seconds: 21))
        .anotar(_evaluar('silla', Categoria.animales), const Duration(seconds: 22))
        .anotar(_evaluar('xyzw', Categoria.animales), const Duration(seconds: 23))
        .conTiempo(const Duration(seconds: 60));
    expect(m.validas, 2);
    expect(m.repetidas, 1);
    expect(m.otraCategoria, ['silla']);
    expect(m.noReconocidas, ['xyzw']);
    expect(m.errores, 3);
    expect(m.puntaje, 20);
    expect(m.ritmoMs, 10000);
    expect(m.porTramo(const Duration(seconds: 60)), [1, 1, 0, 0]);

    final r = m.aResultado(Dificultad.facil);
    expect(r.aciertos, 2);
    expect(r.errores, 3);
    expect(r.puntajeMaximo, 10);
  });

  test('MetricasCategoria cuenta según lo revisado', () {
    const t = Duration(seconds: 1);
    const n = Ajuste.ninguno;
    final respuestas = ['perro', 'xyzw', 'silla'];
    final ajustes = [n, Ajuste.aceptada, Ajuste.descartada];
    final m = MetricasCategoria.contar(
      meta: 10,
      respuestas: [for (final r in respuestas) RespuestaOida(r, t)],
      evaluaciones: EvaluadorCategoria.evaluarTodas(respuestas, Categoria.animales, ajustes),
      ajustes: ajustes,
      tiempo: const Duration(seconds: 60),
    );
    expect(m.palabras.map((p) => p.texto), ['perro', 'xyzw']);
    expect(m.errores, 0);
  });

  group('PalabrasCategoriaNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late DictadoFalso dictado;
    late ProviderContainer c;
    late ProviderSubscription<PalabrasCategoriaState> sub;

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      dictado = DictadoFalso();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        dictadoProvider.overrideWithValue(dictado),
        sorteoCategoriaProvider.overrideWithValue(SorteoCategoria(random: Random(7))),
      ]);
      sub = c.listen(palabrasCategoriaProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    PalabrasCategoriaNotifier juego() => c.read(palabrasCategoriaProvider.notifier);
    PalabrasCategoriaState estado() => c.read(palabrasCategoriaProvider);
    String palabra(int i) => estado().categoria.palabras[i];

    void avanzar(int ms) {
      reloj.avanzar(Duration(milliseconds: ms));
      juego().actualizar();
    }

    /// Empieza la práctica y deja pasar la categoría en grande.
    void practicar() {
      juego().empezarPractica();
      avanzar(PalabrasCategoriaNotifier.presentacion.inMilliseconds);
    }

    /// Hace la práctica sin decir nada y empieza la ronda medida.
    void empezar() {
      practicar();
      avanzar(NivelCategoria.duracionPractica.inMilliseconds);
      juego().empezarPrueba();
      avanzar(PalabrasCategoriaNotifier.presentacion.inMilliseconds);
    }

    test('la práctica es con colores, dura 20 segundos, muestra cada palabra y no se registra', () async {
      juego().empezarPractica();
      await Future<void>.delayed(Duration.zero);
      expect(estado().fase, FaseCategoria.presentacion);
      expect(estado().categoria, Categoria.colores);
      expect(voz.dichos.last, 'Su categoría es: colores.');

      avanzar(3000);
      expect(estado().fase, FaseCategoria.jugando);
      expect(estado().textoTiempo, '00:20');
      juego().anadir('rojo');
      juego().anadir('perro');
      avanzar(20000);
      expect(estado().fase, FaseCategoria.finPractica);
      expect(estado().metricas.validas, 1);
      expect(estado().evaluaciones.map((e) => e.veredicto), [Veredicto.valida, Veredicto.otraCategoria]);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
    });

    test('no se puede empezar la ronda medida sin hacer la práctica', () {
      juego().empezarPrueba();
      expect(estado().fase, FaseCategoria.instrucciones);
    });

    test('la ronda medida usa una categoría del nivel, dura 60 segundos y empieza vacía', () {
      practicar();
      juego().anadir('rojo');
      avanzar(20000);
      juego().empezarPrueba();
      avanzar(3000);
      expect(estado().practica, isFalse);
      expect(NivelCategoria.de(Dificultad.facil).categorias, contains(estado().categoria));
      expect(estado().textoTiempo, '01:00');
      expect(estado().oidas, isEmpty);
    });

    test('durante la ronda solo se anota; al terminar se evalúa todo', () async {
      empezar();
      expect(juego().anadir('   '), isFalse);
      expect(juego().anadir(' ${palabra(0)} '), isTrue);
      juego().anadir(palabra(0));
      juego().anadir('silla');
      juego().anadir('qwerty');
      expect(estado().oidas, [palabra(0), palabra(0), 'silla', 'qwerty']);
      expect(estado().metricas.validas, 0);

      await juego().terminar();
      expect(estado().fase, FaseCategoria.revision);
      expect(estado().evaluaciones.map((e) => e.veredicto),
          [Veredicto.valida, Veredicto.repetida, Veredicto.otraCategoria, Veredicto.noReconocida]);
      expect(estado().evaluaciones[2].categoria, Categoria.hogar);
      expect(estado().metricas.noReconocidas, ['qwerty']);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
    });

    test('se pueden escribir varias palabras de una vez', () {
      empezar();
      juego().anadir('${palabra(0)} y ${palabra(1)}');
      expect(estado().oidas, [palabra(0), palabra(1)]);
    });

    test('el dictado se muestra al instante y cuenta la versión corregida', () async {
      empezar();
      // Con la semilla del sorteo, la ronda es de animales.
      expect(estado().categoria, Categoria.animales);
      await juego().alternarMicrofono();
      dictado.oir('oso', esFinal: false);
      expect(estado().oidas, ['oso']);

      // Con la pausa a mitad de la frase, el reconocedor la completa después.
      dictado.oir('oso hormiguero', esFinal: false);
      expect(estado().oidas, ['oso hormiguero']);
      dictado.oir('oso hormiguero y perros');
      expect(estado().oidas, ['oso hormiguero', 'perro']);

      await juego().terminar();
      expect(estado().metricas.palabras.map((p) => p.texto), ['oso hormiguero', 'perro']);
      expect(estado().metricas.palabras.every((p) => p.dictada), isTrue);
    });

    test('lo que llega tarde de una escucha anterior no se cuenta dos veces', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir(palabra(0), esFinal: false);
      dictado.cerrarSolo();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      dictado.oir(palabra(2));
      dictado.oirEn(0, palabra(0));
      expect(estado().oidas, [palabra(0), palabra(2)]);
      await juego().terminar();
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.repetidas, 0);
    });

    test('termina a los 60 segundos con lo último que oyó y se registra al confirmar', () async {
      empezar();
      juego().anadir(palabra(0));
      await juego().alternarMicrofono();
      dictado.oir('qwerty', esFinal: false);
      avanzar(60000);
      await pumpEventQueue();
      expect(estado().fase, FaseCategoria.revision);
      expect(estado().metricas.tiempo, NivelCategoria.duracion);

      // La app no conocía la palabra; quien revisa la acepta.
      juego().ajustar(1, Ajuste.aceptada);
      expect(estado().metricas.validas, 2);
      juego().confirmar();
      expect(estado().fase, FaseCategoria.resultado);
      expect(estado().resultado!.aciertos, 2);
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FaseCategoria.resultado);
    });

    test('sin palabras va directo al resultado', () async {
      empezar();
      await juego().terminar();
      expect(estado().fase, FaseCategoria.resultado);
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
    });

    test('en pausa el tiempo no corre ni se puede escribir', () {
      empezar();
      avanzar(5000);
      juego().pausar();
      avanzar(20000);
      expect(juego().anadir(palabra(0)), isFalse);
      expect(estado().oidas, isEmpty);
      juego().reanudar();
      avanzar(1000);
      expect(estado().textoTiempo, '00:54');
    });

    test('desde el fin de la práctica se puede repetirla o volver a las instrucciones', () {
      practicar();
      avanzar(20000);
      juego().empezarPractica();
      expect(estado().fase, FaseCategoria.presentacion);
      expect(estado().practica, isTrue);
      avanzar(3000);
      avanzar(20000);
      juego().verInstrucciones();
      expect(estado().fase, FaseCategoria.instrucciones);
    });

    test('repetir vuelve a las instrucciones del mismo nivel', () async {
      empezar();
      juego().anadir(palabra(0));
      await juego().terminar();
      juego().confirmar();
      juego().repetir();
      expect(estado().fase, FaseCategoria.instrucciones);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
    });

    test('la instrucción leída no revela la categoría de la ronda', () async {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      juego().escucharInstruccion();
      await Future<void>.delayed(Duration.zero);
      expect(voz.dichos.single.toLowerCase(), isNot(contains('ciudades')));
    });
  });

  test('el juego queda en el catálogo, en fluidez verbal después de la letra', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(juegoProvider(_id))!.dominio, Dominio.fluidezVerbal);
    expect(c.read(juegosDeDominioProvider(Dominio.fluidezVerbal)).map((j) => j.id).last, _id);
  });
}
