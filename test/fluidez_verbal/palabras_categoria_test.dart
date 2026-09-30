import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/dictado.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
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

    test('la práctica es con colores, dura 20 segundos y no se registra', () async {
      juego().empezarPractica();
      await Future<void>.delayed(Duration.zero);
      expect(estado().fase, FaseCategoria.presentacion);
      expect(estado().categoria, Categoria.colores);
      expect(voz.dichos.last, 'Su categoría es: colores.');

      avanzar(3000);
      expect(estado().fase, FaseCategoria.jugando);
      expect(estado().textoTiempo, '00:20');
      juego().anadir('rojo');
      avanzar(20000);
      expect(estado().fase, FaseCategoria.finPractica);
      expect(estado().metricas.validas, 1);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
    });

    test('no se puede empezar la ronda medida sin hacer la práctica', () {
      juego().empezarPrueba();
      expect(estado().fase, FaseCategoria.instrucciones);
    });

    test('la ronda medida usa una categoría del nivel y dura 60 segundos', () {
      empezar();
      expect(estado().practica, isFalse);
      expect(NivelCategoria.de(Dificultad.facil).categorias, contains(estado().categoria));
      expect(estado().textoTiempo, '01:00');
    });

    test('escribir registra y da el refuerzo según el veredicto', () {
      empezar();
      expect(juego().anadir('   '), isFalse);
      expect(juego().anadir(' ${palabra(0)} '), isTrue);
      expect(estado().metricas.palabras.single.texto, palabra(0));
      expect(estado().retro, Veredicto.valida);

      juego().anadir(palabra(0));
      expect(estado().metricas.repetidas, 1);
      expect(estado().retro, Veredicto.repetida);

      juego().anadir('silla');
      expect(estado().retro, Veredicto.otraCategoria);
      expect(estado().categoriaRetro, Categoria.hogar);

      juego().anadir('qwerty');
      expect(estado().retro, Veredicto.noReconocida);
      expect(estado().metricas.noReconocidas, ['qwerty']);

      avanzar(1700);
      expect(estado().retro, isNull);
    });

    test('se pueden escribir varias palabras de una vez', () {
      empezar();
      juego().anadir('${palabra(0)} y ${palabra(1)}');
      expect(estado().metricas.palabras.map((p) => p.texto), [palabra(0), palabra(1)]);
    });

    test('el dictado muestra lo que oye y se guarda solo', () async {
      empezar();
      await juego().alternarMicrofono();
      dictado.oir(palabra(0), esFinal: false);
      expect(estado().parcial, palabra(0));
      expect(estado().metricas.validas, 0);

      avanzar(1000);
      expect(estado().metricas.palabras.map((p) => p.texto), [palabra(0)]);
      expect(estado().metricas.palabras.single.dictada, isTrue);

      dictado.oir('${palabra(0)} ${palabra(2)}');
      expect(estado().metricas.validas, 2);
      expect(estado().metricas.repetidas, 0);
    });

    test('termina a los 60 segundos, registra solo ese nivel y conserva el resultado', () {
      empezar();
      juego().anadir(palabra(0));
      avanzar(60000);
      expect(estado().fase, FaseCategoria.resultado);
      expect(estado().metricas.tiempo, NivelCategoria.duracion);
      expect(estado().resultado!.aciertos, 1);
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FaseCategoria.resultado);
    });

    test('en pausa el tiempo no corre ni se puede escribir', () {
      empezar();
      avanzar(5000);
      juego().pausar();
      avanzar(20000);
      expect(juego().anadir(palabra(0)), isFalse);
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

    test('repetir vuelve a las instrucciones del mismo nivel', () {
      empezar();
      avanzar(60000);
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
