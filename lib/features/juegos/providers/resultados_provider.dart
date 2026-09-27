import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';

typedef ResultadosPorNivel = Map<Dificultad, ResultadoJuego>;

/// Resultados de la sesión: por id de juego, el último de cada nivel. Se
/// guardan en memoria y se limpian al cambiar de adulto; saldrán del [Ciclo]
/// cuando se persista.
class ResultadosNotifier extends Notifier<Map<String, ResultadosPorNivel>> {
  @override
  Map<String, ResultadosPorNivel> build() {
    ref.watch(sesionProvider.select((s) => s.adulto?.id));
    return const {};
  }

  /// Guarda el resultado de [dificultad] y deja elegido el siguiente nivel que
  /// falte, para que al volver a entrar se siga desde ahí.
  void registrar(String juegoId, Dificultad dificultad, ResultadoJuego resultado) {
    final niveles = {...?state[juegoId], dificultad: resultado};
    state = {...state, juegoId: niveles};

    final pendiente = Dificultad.values.where((d) => !niveles.containsKey(d)).firstOrNull;
    if (pendiente != null) ref.read(dificultadJuegoProvider(juegoId).notifier).elegir(pendiente);
  }

  /// Borra lo hecho en los juegos de [dominio] y los devuelve al nivel 1.
  void reiniciarDominio(Dominio dominio) {
    final ids = ref.read(juegosDeDominioProvider(dominio)).map((j) => j.id).toSet();
    state = {...state}..removeWhere((id, _) => ids.contains(id));
    for (final id in ids) {
      ref.invalidate(dificultadJuegoProvider(id));
    }
  }
}

final resultadosProvider =
    NotifierProvider<ResultadosNotifier, Map<String, ResultadosPorNivel>>(ResultadosNotifier.new);

/// Niveles ya hechos de un juego.
final nivelesHechosProvider = Provider.family<Set<Dificultad>, String>(
  (ref, id) => ref.watch(resultadosProvider.select((r) => r[id]?.keys.toSet() ?? const {})),
);

/// Un juego está completo solo cuando se hicieron todos sus niveles.
final juegoCompletoProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(nivelesHechosProvider(id)).length == Dificultad.values.length,
);

/// Niveles hechos en todo el dominio; sirve para saber si hay algo que reiniciar.
final nivelesHechosDominioProvider = Provider.family<int, Dominio>(
  (ref, d) => ref
      .watch(juegosDeDominioProvider(d))
      .fold(0, (s, j) => s + ref.watch(nivelesHechosProvider(j.id)).length),
);

/// Actividades completas por dominio.
final progresoProvider = Provider<Map<Dominio, int>>((ref) => {
      for (final d in Dominio.values)
        d: ref.watch(juegosDeDominioProvider(d)).where((j) => ref.watch(juegoCompletoProvider(j.id))).length,
    });

/// Primer juego del dominio que no está completo; `null` si ya están todos.
final siguienteJuegoProvider = Provider.family<Game?, Dominio>(
  (ref, d) => ref.watch(juegosDeDominioProvider(d)).where((j) => !ref.watch(juegoCompletoProvider(j.id))).firstOrNull,
);
