/// Qué pasó con una palabra que el adulto dio.
enum Veredicto {
  /// Empieza con la letra y es nueva: cuenta.
  valida,

  /// Ya la había dicho, o es el plural de una que ya dijo (perseveración).
  repetida,

  /// No empieza con la letra de la ronda (intrusión).
  otraLetra,

  /// Números, signos o algo que no se lee como una palabra.
  noEsPalabra,
}

/// Reglas para decidir si una palabra cuenta. No hay diccionario: se revisa
/// la forma, la letra inicial y que no se repita.
abstract final class EvaluadorPalabras {
  static final _soloLetras = RegExp(r'^[a-zñáéíóúü]+$');
  static final _vocal = RegExp('[aeiouáéíóúü]');
  static final _tripleLetra = RegExp(r'(.)\1\1');
  static final _separador = RegExp(r'[^a-zA-ZñÑáéíóúüÁÉÍÓÚÜ]+');

  static const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};

  /// Minúsculas y sin tildes; la ñ se conserva porque es otra letra.
  static String normalizar(String palabra) =>
      palabra.trim().toLowerCase().split('').map((c) => _sinTilde[c] ?? c).join();

  /// Parte un texto dictado («mesa, mano y mapa») en palabras sueltas.
  static List<String> separar(String texto) =>
      texto.split(_separador).where((p) => p.isNotEmpty).map((p) => p.toLowerCase()).toList();

  /// Veredicto de [palabra] para [letra], dadas las ya [aceptadas].
  static Veredicto evaluar(String palabra, String letra, Iterable<String> aceptadas) {
    final p = palabra.trim().toLowerCase();
    if (p.length < 2 || !_soloLetras.hasMatch(p) || !_vocal.hasMatch(p) || _tripleLetra.hasMatch(p)) {
      return Veredicto.noEsPalabra;
    }

    final n = normalizar(p);
    if (!n.startsWith(normalizar(letra))) return Veredicto.otraLetra;
    if (aceptadas.any((a) => _mismaPalabra(n, normalizar(a)))) return Veredicto.repetida;
    return Veredicto.valida;
  }

  /// Igual, o una es el plural de la otra (mesa/mesas, pan/panes, luz/luces).
  static bool _mismaPalabra(String a, String b) => a == b || _plural(a, b) || _plural(b, a);

  static bool _plural(String singular, String plural) =>
      plural == '${singular}s' ||
      plural == '${singular}es' ||
      (singular.endsWith('z') && plural == '${singular.substring(0, singular.length - 1)}ces');
}
