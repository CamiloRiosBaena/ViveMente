import 'package:vivamente/features/fluidez_verbal/comun/transcripcion.dart';

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

  /// Palabras sueltas que se dicen entre respuestas y no son respuestas.
  static const _relleno = {
    'el', 'la', 'lo', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'al', 'en', 'con', 'que', //
    'pues', 'bueno', 'eh', 'em', 'mm', 'mmm', 'ah', 'ay',
  };

  /// Parte un texto dictado («mesa, mano y mapa») en palabras sueltas.
  static List<String> separar(String texto) =>
      texto.split(_separador).where((p) => p.isNotEmpty).map((p) => p.toLowerCase()).toList();

  /// Cada palabra es una respuesta. En el dictado se quitan las de una letra
  /// («y», «a») y las de relleno («la», «eh»): son conectores, no respuestas.
  /// Escritas se evalúan todas.
  static List<Corte> cortar(List<String> palabras, {required bool dictado}) => [
        for (final (i, p) in palabras.indexed)
          if (!dictado || (p.length > 1 && !_relleno.contains(normalizar(p)))) (texto: p, inicio: i),
      ];

  /// Veredicto de cada respuesta, en orden. Para saber si una se repite
  /// cuentan las anteriores que valen (por la evaluación o porque se
  /// aceptaron), no las descartadas.
  static List<Veredicto> evaluarTodas(List<String> respuestas, String letra, List<Ajuste> ajustes) {
    final aceptadas = <String>[];
    final veredictos = <Veredicto>[];
    for (final (i, r) in respuestas.indexed) {
      final v = evaluar(r, letra, aceptadas);
      veredictos.add(v);
      final ajuste = ajustes[i];
      if (ajuste == Ajuste.aceptada || (ajuste == Ajuste.ninguno && v == Veredicto.valida)) aceptadas.add(r);
    }
    return veredictos;
  }

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
