import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';

// Cada minijuego tiene su propio bloque, separado por una línea en blanco, en
// los imports y en el catálogo. Cada rama llena solo el suyo, así que al
// unirlas en develop no se tocan las mismas líneas y el merge no choca.

// Atención 1 · Tren de las señales
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';

// Atención 2 · Encuentra el objetivo

// Atención 3

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

      // Atención 3
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
