import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/services/voz.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';

import '../helpers/falsos.dart';

/// Juego mínimo para probar la infraestructura sin depender de uno real.
class _JuegoFalso extends Game {
  const _JuegoFalso(this.id, this.dificultad);

  @override
  final String id;
  @override
  final Dificultad dificultad;
  @override
  String get titulo => 'Falso $id';
  @override
  String get descripcion => 'Prueba';
  @override
  String get instrucciones => '';
  @override
  Dominio get dominio => Dominio.atencion;
  @override
  IconData get icono => const IconData(0);
  @override
  Duration get duracionEstimada => const Duration(minutes: 1);
  @override
  Widget build({required FinalizarJuego finalizarJuego, required VoidCallback onBack}) => const SizedBox();
}

const _resultado = ResultadoJuego(puntajeBruto: 1, puntajeMaximo: 1, duracion: Duration(seconds: 30));

void main() {
  group('Resultados por nivel', () {
    late ProviderContainer c;
    const id = 'a';
    const otro = 'b';

    setUp(() => c = ProviderContainer(overrides: [
          juegosProvider.overrideWith((ref) => [
                _JuegoFalso(id, ref.watch(dificultadJuegoProvider(id))),
                _JuegoFalso(otro, ref.watch(dificultadJuegoProvider(otro))),
              ]),
        ]));
    tearDown(() => c.dispose());

    test('un nivel hecho no completa la actividad y deja elegido el siguiente', () {
      c.read(resultadosProvider.notifier).registrar(id, Dificultad.facil, _resultado);

      expect(c.read(nivelesHechosProvider(id)), {Dificultad.facil});
      expect(c.read(juegoCompletoProvider(id)), isFalse);
      expect(c.read(progresoProvider)[Dominio.atencion], 0);
      expect(c.read(dificultadJuegoProvider(id)), Dificultad.medio);
      expect(c.read(juegoProvider(id))!.dificultad, Dificultad.medio);
    });

    test('con los tres niveles la actividad queda completa y sigue la otra', () {
      final n = c.read(resultadosProvider.notifier);
      for (final d in Dificultad.values) {
        n.registrar(id, d, _resultado);
      }
      expect(c.read(juegoCompletoProvider(id)), isTrue);
      expect(c.read(progresoProvider)[Dominio.atencion], 1);
      expect(c.read(siguienteJuegoProvider(Dominio.atencion))!.id, otro);
    });

    test('reiniciar el dominio borra lo hecho y vuelve al nivel 1', () {
      final n = c.read(resultadosProvider.notifier)
        ..registrar(id, Dificultad.facil, _resultado)
        ..registrar(otro, Dificultad.facil, _resultado)
        ..registrar(otro, Dificultad.medio, _resultado);
      expect(c.read(nivelesHechosDominioProvider(Dominio.atencion)), 3);

      n.reiniciarDominio(Dominio.atencion);
      expect(c.read(nivelesHechosProvider(id)), isEmpty);
      expect(c.read(nivelesHechosDominioProvider(Dominio.atencion)), 0);
      expect(c.read(dificultadJuegoProvider(id)), Dificultad.facil);
      expect(c.read(dificultadJuegoProvider(otro)), Dificultad.facil);
    });

    test('la posición cuenta el orden del catálogo sobre el total de la valoración', () {
      final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);
      expect(c.read(posicionJuegoProvider(otro)), (numero: 2, total: total));
    });
  });

  group('Lectura en voz alta', () {
    late VozFalsa voz;
    late ProviderContainer c;

    setUp(() {
      voz = VozFalsa();
      c = ProviderContainer(overrides: [vozProvider.overrideWithValue(voz)]);
    });
    tearDown(() => c.dispose());

    test('lee, y al alternar se detiene', () async {
      await c.read(lecturaProvider.notifier).alternar('hola');
      expect(voz.dichos, ['hola']);
      expect(c.read(lecturaProvider), EstadoLectura.leyendo);

      await c.read(lecturaProvider.notifier).alternar('hola');
      expect(c.read(lecturaProvider), EstadoLectura.quieta);
    });

    test('sin motor de voz avisa que no está disponible en vez de quedarse leyendo', () async {
      voz.disponible = false;
      await c.read(lecturaProvider.notifier).leer('hola');
      expect(voz.dichos, isEmpty);
      expect(c.read(lecturaProvider), EstadoLectura.noDisponible);

      // Se puede volver a intentar.
      voz.disponible = true;
      await c.read(lecturaProvider.notifier).leer('hola');
      expect(c.read(lecturaProvider), EstadoLectura.leyendo);
    });
  });
}
