import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';

// Cada minijuego tiene su propio bloque, separado por una línea en blanco, en
// los imports y en el catálogo. Cada rama llena solo el suyo, así que al
// unirlas en develop no se tocan las mismas líneas y el merge no choca.

// Atención 1 · Tren de las señales
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';

// Atención 2 · Encuentra el objetivo
import 'package:vivamente/features/atencion/encuentra_objetivo/encuentra_objetivo_game.dart';

// Atención 3

// Memoria 1 · Prepara el desayuno
import 'package:vivamente/features/memoria/prepara_desayuno/prepara_desayuno_game.dart';

// Memoria 2 · ¿Para qué sirve?
import 'package:vivamente/features/memoria/para_que_sirve/para_que_sirve_game.dart';

// Fluidez verbal 1 · Palabras con una letra
import 'package:vivamente/features/fluidez_verbal/palabras_letra/palabras_letra_game.dart';

// Fluidez verbal 2 · Palabras por categoría
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/palabras_categoria_game.dart';

/// Nivel elegido para cada juego, por id. Empieza en fácil.
class DificultadNotifier extends Notifier<Dificultad> {
  DificultadNotifier(this.juegoId);

  final String juegoId;

  @override
  Dificultad build() => Dificultad.facil;

  void elegir(Dificultad d) => state = d;
}

final dificultadJuegoProvider =
    NotifierProvider.family<DificultadNotifier, Dificultad, String>(DificultadNotifier.new);

/// Catálogo de minijuegos en el orden en que se aplican, cada uno con el nivel
/// elegido. Para sumar un juego basta con agregarlo en su bloque.
final juegosProvider = Provider<List<Game>>((ref) => [
      // Atención 1 · Tren de las señales
      TrenSenalesGame(dificultad: ref.watch(dificultadJuegoProvider(TrenSenalesGame.idJuego))),

      // Atención 2 · Encuentra el objetivo
      EncuentraObjetivoGame(dificultad: ref.watch(dificultadJuegoProvider(EncuentraObjetivoGame.idJuego))),

      // Atención 3

      // Memoria 1 · Prepara el desayuno
      PreparaDesayunoGame(dificultad: ref.watch(dificultadJuegoProvider(PreparaDesayunoGame.idJuego))),

      // Memoria 2 · ¿Para qué sirve?
      ParaQueSirveGame(dificultad: ref.watch(dificultadJuegoProvider(ParaQueSirveGame.idJuego))),

      // Fluidez verbal 1 · Palabras con una letra
      PalabrasLetraGame(dificultad: ref.watch(dificultadJuegoProvider(PalabrasLetraGame.idJuego))),

      // Fluidez verbal 2 · Palabras por categoría
      PalabrasCategoriaGame(dificultad: ref.watch(dificultadJuegoProvider(PalabrasCategoriaGame.idJuego))),
    ]);

final juegosDeDominioProvider = Provider.family<List<Game>, Dominio>(
  (ref, d) => ref.watch(juegosProvider).where((j) => j.dominio == d).toList(),
);

final juegoProvider = Provider.family<Game?, String>(
  (ref, id) => ref.watch(juegosProvider).where((j) => j.id == id).firstOrNull,
);

/// Lugar del juego en la valoración completa: «1 de 23».
typedef PosicionJuego = ({int numero, int total});

final posicionJuegoProvider = Provider.family<PosicionJuego, String>((ref, id) {
  final orden = Dominio.values.expand((d) => ref.watch(juegosDeDominioProvider(d))).toList();
  final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);
  return (numero: orden.indexWhere((j) => j.id == id) + 1, total: total);
});
