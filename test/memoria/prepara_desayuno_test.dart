import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';

import '../helpers/falsos.dart';

const _id = PreparaDesayunoGame.idJuego;

Alimento _a(String nombre) => CatalogoAlimentos.todos.firstWhere((a) => a.nombre == nombre);

void main() {
  group('GeneradorDesayuno', () {
    for (final d in Dificultad.values) {
      test('nivel ${d.nivel}: lista del tamaño del nivel y bandeja que la contiene', () {
        final nivel = NivelDesayuno.de(d);
        final g = GeneradorDesayuno(random: Random(1));
        for (var i = 0; i < 30; i++) {
          final lista = g.lista(nivel);
          final bandeja = g.bandeja(nivel, lista);
          expect(lista.length, inInclusiveRange(nivel.elementosMin, nivel.elementosMax));
          expect(lista.toSet(), hasLength(lista.length), reason: 'sin repetidos');
          expect(bandeja, hasLength(nivel.bandeja));
          expect(bandeja.toSet(), hasLength(nivel.bandeja), reason: 'sin repetidos');
          expect(bandeja, containsAll(lista));
        }
      });
    }

    test('la lista parece un desayuno: como mucho dos del mismo tipo', () {
      final g = GeneradorDesayuno(random: Random(2));
      final nivel = NivelDesayuno.de(Dificultad.medio);
      for (var i = 0; i < 50; i++) {
        final lista = g.lista(nivel);
        for (final t in TipoAlimento.values) {
          expect(lista.where((a) => a.tipo == t).length, lessThanOrEqualTo(GeneradorDesayuno.maxPorTipo));
        }
      }
    });

    test('la lista cambia de un intento al siguiente en el mismo nivel', () {
      final g = GeneradorDesayuno(random: Random(3));
      final nivel = NivelDesayuno.de(Dificultad.facil);
      var anterior = g.lista(nivel).toSet();
      for (var i = 0; i < 30; i++) {
        final nueva = g.lista(nivel).toSet();
        expect(nueva, isNot(equals(anterior)));
        anterior = nueva;
      }
    });
  });

  test('la lista se ve entre 10 y 15 segundos', () {
    expect(NivelDesayuno.exposicion(3), const Duration(seconds: 10));
    expect(NivelDesayuno.exposicion(4), const Duration(seconds: 12));
    expect(NivelDesayuno.exposicion(5), const Duration(seconds: 15));
  });

  test('enumerarAlimentos une con comas y «y»', () {
    expect(enumerarAlimentos([_a('Pan'), _a('Café'), _a('Huevo'), _a('Manzana')]), 'pan, café, huevo y manzana');
    expect(enumerarAlimentos([_a('Pan')]), 'pan');
  });

  group('MetricasDesayuno', () {
    final lista = [_a('Pan'), _a('Café'), _a('Huevo'), _a('Manzana')];

    test('sin orden cuenta aciertos, errores y omisiones con lo que quedó en el plato', () {
      final m = MetricasDesayuno(
        lista: lista,
        plato: [_a('Huevo'), _a('Pan'), _a('Queso'), null],
        conOrden: false,
        tiempo: const Duration(seconds: 20),
      );
      expect(m.aciertos, 2);
      expect(m.errores, 1);
      expect(m.omisiones, 2);
      expect(m.puntaje, 38); // (2 − 0,5) / 4

      final r = m.aResultado(Dificultad.medio);
      expect(r.aciertos, 2);
      expect(r.errores, 1);
      expect(r.omisiones, 2);
      expect(r.latenciaPromedio, 10000);
      expect(r.dificultad, Dificultad.medio);
    });

    test('con orden, la mitad del puntaje es por el puesto', () {
      final todosEnOrden = MetricasDesayuno(lista: lista, plato: [...lista], conOrden: true);
      expect(todosEnOrden.enOrden, 4);
      expect(todosEnOrden.puntaje, 100);

      final revueltos = MetricasDesayuno(lista: lista, plato: lista.reversed.toList(), conOrden: true);
      expect(revueltos.aciertos, 4);
      expect(revueltos.enOrden, 0);
      expect(revueltos.puntaje, 50);

      final dosBien = MetricasDesayuno(
        lista: lista,
        plato: [_a('Pan'), _a('Café'), _a('Manzana'), _a('Huevo')],
        conOrden: true,
      );
      expect(dosBien.enOrden, 2);
      expect(dosBien.puntaje, 75);
    });

    test('el puntaje no baja de 0', () {
      final m = MetricasDesayuno(
        lista: lista,
        plato: [_a('Queso'), _a('Miel'), _a('Té'), _a('Uvas')],
        conOrden: false,
      );
      expect(m.aciertos, 0);
      expect(m.errores, 4);
      expect(m.puntaje, 0);
    });
  });

  group('PreparaDesayunoNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late ProviderContainer c;
    late ProviderSubscription<PreparaDesayunoState> sub;

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        generadorDesayunoProvider.overrideWithValue(GeneradorDesayuno(random: Random(7))),
      ]);
      sub = c.listen(preparaDesayunoProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    PreparaDesayunoNotifier juego() => c.read(preparaDesayunoProvider.notifier);
    PreparaDesayunoState estado() => c.read(preparaDesayunoProvider);
    int enBandeja(Alimento a) => estado().bandeja.indexOf(a);
    int distractor() => estado().bandeja.indexWhere((a) => !estado().lista.contains(a));

    void avanzar(int ms) {
      reloj.avanzar(Duration(milliseconds: ms));
      juego().actualizar();
    }

    /// Hace la práctica sin poner nada y empieza la ronda medida.
    void irAPrueba() {
      juego().empezarPractica();
      avanzar(estado().exposicion.inMilliseconds);
      juego().terminar();
      juego().empezarPrueba();
    }

    /// Pasa la exposición de la ronda medida y deja la bandeja a la vista.
    void irABandeja() {
      irAPrueba();
      avanzar(estado().exposicion.inMilliseconds);
    }

    test('muestra la lista, la lee en voz alta y la oculta al acabar la exposición', () async {
      juego().empezarPractica();
      await Future<void>.delayed(Duration.zero);
      expect(estado().fase, FaseDesayuno.memorizar);
      expect(voz.dichos.single, contains(enumerarAlimentos(estado().lista)));
      expect(estado().cuentaAtras, 10);

      avanzar(4000);
      expect(estado().cuentaAtras, 6);
      // En la lista no se puede elegir nada todavía.
      juego().elegir(enBandeja(estado().lista.first));
      expect(estado().platoVacio, isTrue);

      avanzar(6000);
      expect(estado().fase, FaseDesayuno.bandeja);
      expect(estado().transcurrido, Duration.zero);
    });

    test('tocar pone en el primer puesto libre; tocar el plato lo quita', () {
      irABandeja();
      final lista = estado().lista;

      juego().elegir(enBandeja(lista[1]));
      juego().elegir(enBandeja(lista[0]));
      expect(estado().plato, [lista[1], lista[0], null]);

      // El mismo alimento no se pone dos veces.
      juego().elegir(enBandeja(lista[0]));
      expect(estado().plato, [lista[1], lista[0], null]);

      juego().quitar(0);
      expect(estado().plato, [null, lista[0], null]);
      juego().elegir(enBandeja(lista[2]));
      expect(estado().plato, [lista[2], lista[0], null]);
    });

    test('arrastrar a un puesto ocupado reemplaza lo que había', () {
      irABandeja();
      final lista = estado().lista;
      juego().poner(enBandeja(lista[0]), 2);
      expect(estado().plato, [null, null, lista[0]]);
      juego().poner(distractor(), 2);
      expect(estado().plato[2], isNot(lista[0]));
      expect(estado().enPlato(lista[0]), isFalse);
    });

    test('con el plato lleno avisa y no pone más; el aviso se apaga solo', () {
      irABandeja();
      final lista = estado().lista;
      for (final a in lista) {
        juego().elegir(enBandeja(a));
      }
      expect(estado().platoLleno, isTrue);

      juego().elegir(distractor());
      expect(estado().retro, RetroDesayuno.platoLleno);
      expect(estado().plato, lista);

      avanzar(2000);
      expect(estado().retro, RetroDesayuno.ninguna);
    });

    test('«Listo» revisa el plato, registra solo ese nivel y conserva el resultado', () {
      irABandeja();
      final lista = estado().lista;
      avanzar(15000);
      juego().elegir(enBandeja(lista[0]));
      juego().elegir(enBandeja(lista[1]));
      juego().elegir(distractor());
      juego().terminar();

      expect(estado().fase, FaseDesayuno.resultado);
      expect(estado().metricas.tiempo, const Duration(seconds: 15));
      expect(estado().resultado!.aciertos, 2);
      expect(estado().resultado!.errores, 1);
      expect(estado().resultado!.omisiones, 1);

      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FaseDesayuno.resultado);
    });

    test('en el nivel 3 cuenta el orden', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      expect(estado().nivel.conOrden, isTrue);
      irABandeja();
      final lista = estado().lista;
      for (final a in lista.reversed) {
        juego().elegir(enBandeja(a));
      }
      juego().terminar();
      final m = estado().metricas;
      expect(m.aciertos, lista.length);
      // Al revés, solo el del medio (si la lista es impar) queda en su puesto.
      expect(m.enOrden, lista.length.isOdd ? 1 : 0);
      expect(m.puntaje, lessThan(100));
    });

    test('en pausa la lista se oculta, el tiempo no corre y no se lee', () async {
      juego().empezarPractica();
      avanzar(3000);
      juego().pausar();
      await Future<void>.delayed(Duration.zero);
      expect(estado().pausado, isTrue);
      expect(c.read(lecturaProvider), EstadoLectura.quieta);
      avanzar(20000);
      expect(estado().fase, FaseDesayuno.memorizar);
      expect(estado().transcurrido, const Duration(seconds: 3));

      juego().reanudar();
      avanzar(7000);
      expect(estado().fase, FaseDesayuno.bandeja);

      juego().pausar();
      juego().elegir(enBandeja(estado().lista.first));
      expect(estado().platoVacio, isTrue);
    });

    test('repetir vuelve a las instrucciones con otra lista del mismo nivel', () {
      irABandeja();
      final antes = estado().lista.toSet();
      juego().terminar();
      juego().repetir();

      expect(estado().fase, FaseDesayuno.instrucciones);
      expect(estado().lista.toSet(), isNot(equals(antes)));
      expect(estado().nivel.dificultad, Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
      expect(estado().platoVacio, isTrue);
    });

    test('cambiar el nivel en las instrucciones arma una lista y bandeja de ese nivel', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.medio);
      final nivel = NivelDesayuno.de(Dificultad.medio);
      expect(estado().lista.length, inInclusiveRange(nivel.elementosMin, nivel.elementosMax));
      expect(estado().bandeja, hasLength(nivel.bandeja));
      expect(estado().plato, hasLength(estado().lista.length));
    });

    test('no se puede empezar la ronda medida sin hacer la práctica', () {
      juego().empezarPrueba();
      expect(estado().fase, FaseDesayuno.instrucciones);
    });

    test('la práctica es corta, avisa si cada alimento estaba y no se registra', () {
      juego().empezarPractica();
      expect(estado().practica, isTrue);
      expect(estado().lista, hasLength(NivelDesayuno.elementosPractica));
      expect(estado().bandeja, hasLength(NivelDesayuno.bandejaPractica));
      avanzar(estado().exposicion.inMilliseconds);
      expect(estado().fase, FaseDesayuno.bandeja);

      juego().elegir(distractor());
      expect(estado().retro, RetroDesayuno.noEstaba);
      juego().quitar(0);
      juego().elegir(enBandeja(estado().lista[0]));
      expect(estado().retro, RetroDesayuno.bien);

      juego().terminar();
      expect(estado().fase, FaseDesayuno.finPractica);
      expect(estado().metricas.aciertos, 1);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);
      expect(estado().resultado, isNull);
    });

    test('en la práctica del nivel 3 avisa si el alimento va en otro puesto', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      juego().empezarPractica();
      avanzar(estado().exposicion.inMilliseconds);
      juego().elegir(enBandeja(estado().lista[1]));
      expect(estado().retro, RetroDesayuno.otroPuesto);
      expect(estado().puestoCorrecto, 2);
    });

    test('tras la práctica, la ronda medida trae otra lista del nivel y ya no avisa', () {
      juego().empezarPractica();
      avanzar(estado().exposicion.inMilliseconds);
      final practica = estado().lista;
      juego().terminar();

      juego().empezarPrueba();
      final nivel = NivelDesayuno.de(Dificultad.facil);
      expect(estado().practica, isFalse);
      expect(estado().fase, FaseDesayuno.memorizar);
      expect(estado().lista, hasLength(nivel.elementosMin));
      expect(estado().lista, isNot(equals(practica)));
      expect(estado().bandeja, hasLength(nivel.bandeja));

      avanzar(estado().exposicion.inMilliseconds);
      juego().elegir(distractor());
      expect(estado().retro, RetroDesayuno.ninguna);
    });

    test('desde el fin de la práctica se puede repetirla o volver a las instrucciones', () {
      juego().empezarPractica();
      avanzar(estado().exposicion.inMilliseconds);
      juego().terminar();

      juego().empezarPractica();
      expect(estado().practica, isTrue);
      expect(estado().fase, FaseDesayuno.memorizar);

      avanzar(estado().exposicion.inMilliseconds);
      juego().terminar();
      juego().verInstrucciones();
      expect(estado().fase, FaseDesayuno.instrucciones);
      expect(estado().practica, isFalse);
    });

    test('la instrucción leída no revela la lista', () async {
      juego().escucharInstruccion();
      await Future<void>.delayed(Duration.zero);
      final palabras = voz.dichos.single.toLowerCase().split(RegExp('[^a-záéíóúñü]+'));
      for (final a in estado().lista) {
        expect(palabras, isNot(contains(a.nombre.toLowerCase())));
      }
    });
  });

  test('el juego queda en el catálogo, primero en memoria', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final juego = c.read(juegoProvider(_id))!;
    expect(juego.dominio, Dominio.memoria);
    expect(c.read(juegosDeDominioProvider(Dominio.memoria)).first.id, _id);
  });
}
