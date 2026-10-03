import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/reloj.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/encuentra_objetivo_game.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/estimulo.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/generador_cuadricula.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/metricas_busqueda.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/models/nivel_busqueda.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/providers/encuentra_objetivo_provider.dart';
import 'package:vivamente/features/atencion/encuentra_objetivo/widgets/ficha_estimulo.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

import '../helpers/falsos.dart';

const _id = EncuentraObjetivoGame.idJuego;

void main() {
  group('GeneradorCuadricula', () {
    for (final d in Dificultad.values) {
      test('nivel ${d.nivel}: llena la cuadrícula con la cantidad de objetivos del nivel', () {
        final nivel = NivelBusqueda.de(d);
        final g = GeneradorCuadricula(random: Random(1));
        for (final objetivo in CatalogoEstimulos.objetivos) {
          final casillas = g.cuadricula(nivel, objetivo);
          final n = casillas.where((c) => c == objetivo.estimulo).length;
          expect(casillas, hasLength(nivel.casillas));
          expect(n, inInclusiveRange(nivel.objetivosMin, nivel.objetivosMax));
        }
      });
    }

    test('los parecidos al objetivo solo aparecen en el nivel 3', () {
      final g = GeneradorCuadricula(random: Random(2));
      final a = CatalogoEstimulos.objetivos.first;
      final parecidos = a.parecidos.map(Estimulo.de).toSet();

      for (final d in [Dificultad.facil, Dificultad.medio]) {
        final casillas = g.cuadricula(NivelBusqueda.de(d), a);
        expect(casillas.where(parecidos.contains), isEmpty, reason: 'nivel ${d.nivel}');
      }
      final dificil = g.cuadricula(NivelBusqueda.de(Dificultad.dificil), a);
      expect(dificil.where(parecidos.contains).length, greaterThan(8));
    });

    test('el objetivo cambia de un intento al siguiente en el mismo nivel', () {
      final g = GeneradorCuadricula(random: Random(4));
      var anterior = g.elegirObjetivo(Dificultad.facil);
      final vistos = {anterior.simbolo};
      for (var i = 0; i < 40; i++) {
        final nuevo = g.elegirObjetivo(Dificultad.facil);
        expect(nuevo.simbolo, isNot(anterior.simbolo));
        vistos.add(nuevo.simbolo);
        anterior = nuevo;
      }
      // Se mezclan letras, números, figuras y frutas.
      expect(vistos.map((s) => Estimulo.de(s).tipo).toSet().length, greaterThan(2));
    });

    test('las posiciones de los objetivos cambian en cada cuadrícula', () {
      final g = GeneradorCuadricula(random: Random(5));
      final o = CatalogoEstimulos.objetivos.first;
      final nivel = NivelBusqueda.de(Dificultad.facil);
      Set<int> posiciones() {
        final c = g.cuadricula(nivel, o);
        return {for (var i = 0; i < c.length; i++) if (c[i] == o.estimulo) i};
      }

      expect(posiciones(), isNot(posiciones()));
    });
  });

  test('Estimulo deduce su tipo', () {
    expect(Estimulo.de('A').tipo, TipoEstimulo.letra);
    expect(Estimulo.de('a').tipo, TipoEstimulo.minuscula);
    expect(Estimulo.de('7').tipo, TipoEstimulo.numero);
    expect(Estimulo.de('★').tipo, TipoEstimulo.figura);
    expect(Estimulo.de('🍎').tipo, TipoEstimulo.fruta);
  });

  test('toda figura que puede salir tiene un ícono que la dibuja', () {
    final simbolos = {
      ...CatalogoEstimulos.variados,
      for (final o in CatalogoEstimulos.objetivos) ...[o.simbolo, ...o.parecidos],
    };
    final figuras = simbolos.where((s) => Estimulo.de(s).tipo == TipoEstimulo.figura);
    expect(figuras.where((f) => !TextoEstimulo.figuras.containsKey(f)), isEmpty);
  });

  test('MetricasBusqueda calcula precisión y puntaje', () {
    const m = MetricasBusqueda(disponibles: 20, aciertos: 15, errores: 4, tiempo: Duration(seconds: 102));
    expect((m.precision * 100).round(), 79);
    expect(m.omisiones, 5);
    expect(m.puntaje, 65); // (15 − 4 × 0,5) / 20
    expect(formatoReloj(m.tiempo), '01:42');

    final r = m.aResultado(Dificultad.medio);
    expect(r.aciertos, 15);
    expect(r.errores, 4);
    expect(r.omisiones, 5);
    expect(r.puntajeBruto, 65);
    expect(r.puntajeMaximo, 100);
    expect(r.dificultad, Dificultad.medio);
    expect(const MetricasBusqueda(disponibles: 5, errores: 9).puntaje, 0);
  });

  group('EncuentraObjetivoNotifier', () {
    late RelojFalso reloj;
    late VozFalsa voz;
    late ProviderContainer c;
    late ProviderSubscription<EncuentraObjetivoState> sub;

    setUp(() {
      reloj = RelojFalso();
      voz = VozFalsa();
      c = ProviderContainer(overrides: [
        relojProvider.overrideWithValue(reloj),
        vozProvider.overrideWithValue(voz),
        generadorCuadriculaProvider.overrideWithValue(GeneradorCuadricula(random: Random(7))),
      ]);
      sub = c.listen(encuentraObjetivoProvider, (_, _) {});
    });

    tearDown(() {
      sub.close();
      c.dispose();
    });

    EncuentraObjetivoNotifier juego() => c.read(encuentraObjetivoProvider.notifier);
    EncuentraObjetivoState estado() => c.read(encuentraObjetivoProvider);
    List<int> objetivos() => [for (var i = 0; i < estado().casillas.length; i++) if (estado().esObjetivo(i)) i];
    int unDistractor() => List.generate(estado().casillas.length, (i) => i).firstWhere((i) => !estado().esObjetivo(i));

    void avanzar(int ms) {
      reloj.avanzar(Duration(milliseconds: ms));
      juego().actualizar();
    }

    /// Hace la práctica completa y entra a la ronda medida.
    void aLaPrueba() {
      juego().empezarPractica();
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      juego().empezarPrueba();
    }

    test('no se puede tocar antes de la práctica', () {
      juego().tocar(objetivos().first);
      expect(estado().metricas.aciertos, 0);
      expect(estado().textoTiempo, '02:00');
    });

    test('no se puede saltar la práctica', () {
      juego().empezarPrueba();
      expect(estado().fase, FaseBusqueda.instrucciones);
    });

    test('la práctica usa una cuadrícula corta, no se registra y lleva al fin de práctica', () {
      final objetivo = estado().objetivo.simbolo;
      juego().empezarPractica();

      expect(estado().fase, FaseBusqueda.practica);
      expect(estado().casillas, hasLength(NivelBusqueda.de(Dificultad.facil).practica.casillas));
      expect(estado().rejilla.columnas, 4);
      expect(estado().metricas.disponibles, NivelBusqueda.objetivosPractica);
      expect(estado().textoTiempo, '01:00');
      expect(estado().objetivo.simbolo, objetivo);

      juego().tocar(unDistractor());
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      expect(estado().fase, FaseBusqueda.finPractica);
      expect(estado().metricas.aciertos, NivelBusqueda.objetivosPractica);
      expect(estado().metricas.errores, 1);
      expect(c.read(nivelesHechosProvider(_id)), isEmpty);

      // Se puede repetir; luego la ronda medida trae la cuadrícula del nivel.
      juego().empezarPractica();
      expect(estado().fase, FaseBusqueda.practica);
      expect(estado().metricas.aciertos, 0);
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      juego().empezarPrueba();
      expect(estado().fase, FaseBusqueda.prueba);
      expect(estado().casillas, hasLength(NivelBusqueda.de(Dificultad.facil).casillas));
      expect(estado().objetivo.simbolo, objetivo);
      expect(estado().textoTiempo, '02:00');
    });

    test('la práctica se cierra al minuto aunque falten objetivos', () {
      juego().empezarPractica();
      avanzar(60000);
      expect(estado().fase, FaseBusqueda.finPractica);
      expect(estado().metricas.aciertos, 0);
    });

    test('del fin de la práctica se puede volver a las instrucciones', () {
      juego().empezarPractica();
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      juego().verInstrucciones();
      expect(estado().fase, FaseBusqueda.instrucciones);
      expect(estado().casillas, hasLength(NivelBusqueda.de(Dificultad.facil).casillas));
    });

    test('acierto marca la casilla una sola vez; error no suma y deja seguir', () {
      aLaPrueba();
      final o = objetivos().first;

      juego().tocar(o);
      expect(estado().encontradas, {o});
      expect(estado().metricas.aciertos, 1);
      expect(estado().retro, RetroBusqueda.correcto);

      juego().tocar(o); // ya encontrada: no vuelve a contar
      expect(estado().metricas.aciertos, 1);
      expect(estado().metricas.errores, 0);

      final d = unDistractor();
      juego().tocar(d);
      expect(estado().metricas.errores, 1);
      expect(estado().metricas.aciertos, 1);
      expect(estado().retro, RetroBusqueda.incorrecto);
      expect(estado().casillaError, d);
      expect(estado().jugando, isTrue);

      // El refuerzo se apaga solo, rápido.
      avanzar(800);
      expect(estado().retro, RetroBusqueda.ninguna);
      expect(estado().casillaError, isNull);
    });

    test('termina al encontrar todos, registra solo ese nivel y conserva el resultado', () {
      aLaPrueba();
      avanzar(30000);
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      expect(estado().fase, FaseBusqueda.resultado);
      expect(estado().metricas.tiempo, const Duration(seconds: 30));
      expect(estado().metricas.puntaje, 100);

      // Quedó registrado el nivel 1 y se eligió el 2, sin borrar la pantalla.
      expect(c.read(nivelesHechosProvider(_id)), {Dificultad.facil});
      expect(c.read(juegoCompletoProvider(_id)), isFalse);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.medio);
      expect(estado().fase, FaseBusqueda.resultado);
      expect(estado().resultado!.aciertos, estado().metricas.disponibles);
    });

    test('termina a los 2 minutos con lo que haya encontrado', () {
      aLaPrueba();
      juego().tocar(objetivos().first);
      avanzar(60000);
      expect(estado().textoTiempo, '01:00');
      avanzar(60000);
      expect(estado().fase, FaseBusqueda.resultado);
      expect(estado().metricas.tiempo, NivelBusqueda.duracion);
      expect(estado().resultado!.omisiones, estado().metricas.disponibles - 1);
    });

    test('en pausa el tiempo no corre ni cuentan los toques', () {
      aLaPrueba();
      avanzar(5000);
      juego().pausar();
      avanzar(20000);
      juego().tocar(objetivos().first);
      expect(estado().metricas.aciertos, 0);
      expect(estado().transcurrido, const Duration(seconds: 5));
      juego().reanudar();
      avanzar(1000);
      expect(estado().textoTiempo, '01:54');
    });

    test('repetir arma otra cuadrícula con otro objetivo en el mismo nivel', () {
      final antes = estado().objetivo.simbolo;
      aLaPrueba();
      for (final o in objetivos()) {
        juego().tocar(o);
      }
      juego().repetir();

      expect(estado().fase, FaseBusqueda.instrucciones);
      expect(estado().objetivo.simbolo, isNot(antes));
      expect(estado().nivel.dificultad, Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(_id)), Dificultad.facil);
      expect(estado().metricas.aciertos, 0);
    });

    test('cambiar el nivel en las instrucciones arma una cuadrícula de ese nivel', () {
      c.read(dificultadJuegoProvider(_id).notifier).elegir(Dificultad.dificil);
      expect(estado().nivel.dificultad, Dificultad.dificil);
      expect(estado().casillas, hasLength(NivelBusqueda.de(Dificultad.dificil).casillas));
    });

    test('lee la instrucción con el objetivo del intento', () async {
      juego().escucharInstruccion();
      await Future<void>.delayed(Duration.zero);
      expect(voz.dichos.single, contains(estado().objetivo.todos));
    });
  });
}
