import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';

/// Qué pasó con una palabra que el adulto dio.
enum Veredicto {
  /// Es de la categoría y es nueva: cuenta.
  valida,

  /// Ya la había dicho, o su plural o femenino (perseveración).
  repetida,

  /// Es de otra categoría: una fruta cuando se piden animales (intrusión).
  otraCategoria,

  /// No está en el diccionario de ninguna categoría.
  noReconocida,
}

/// El veredicto y, si se reconoció, la palabra tal como está en el
/// diccionario («perros» → «perro»).
typedef Evaluacion = ({Veredicto veredicto, String palabra, Categoria? categoria});

/// Validación semántica: busca cada palabra en el diccionario de la
/// categoría, sin tildes ni mayúsculas y aceptando plurales y femeninos.
abstract final class EvaluadorCategoria {
  static const _sinTilde = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u'};
  static final _separador = RegExp(r'[^a-zñáéíóúü]+');

  /// Palabras sueltas que se dicen entre respuestas y no son respuestas.
  static const _relleno = {
    'y', 'e', 'o', 'u', 'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas', 'de', 'del', 'al', 'a', 'en', //
    'con', 'que', 'este', 'esta', 'ese', 'esa', 'otro', 'otra', 'tambien', 'pues', 'bueno', 'eh', 'em', 'mm', 'mmm',
    'ah', 'ay', 'no', 'si', 'ya', 'mas', 'muy', 'mi', 'me', 'se', 'lo', 'le', 'como', 'hay',
  };

  /// Frases más largas que se buscan en lo dictado («estrella de mar»).
  static const _maxPalabrasFrase = 4;

  /// Minúsculas, sin tildes y con un solo espacio; la ñ se conserva.
  static String normalizar(String texto) => texto
      .toLowerCase()
      .split('')
      .map((c) => _sinTilde[c] ?? c)
      .join()
      .split(_separador)
      .where((p) => p.isNotEmpty)
      .join(' ');

  /// Otras formas de decir una palabra del diccionario, que cuentan como la
  /// misma: una variante de escritura o un femenino que no sale de cambiar
  /// la terminación.
  static const _variantes = {
    'leona': 'león',
    'poetisa': 'poeta',
    'actriz': 'actor',
    'banana': 'banano',
    'pitaya': 'pitahaya',
    'sao paulo': 'São Paulo',
    'computadora': 'computador',
    'television': 'televisor',
  };

  static final Map<Categoria, Map<String, String>> _diccionarios = {
    for (final c in Categoria.values)
      c: {
        for (final p in c.palabras) normalizar(p): p,
        for (final MapEntry(key: v, value: p) in _variantes.entries)
          if (c.palabras.contains(p)) v: p,
      },
  };

  /// La palabra del diccionario de [categoria] a la que corresponde
  /// [normalizada], o `null`. Prueba el plural y, si la categoría lo admite,
  /// el femenino, también en la primera palabra de una frase.
  static String? buscar(String normalizada, Categoria categoria) {
    final dic = _diccionarios[categoria]!;
    for (final forma in _formas(normalizada, conGenero: categoria.conGenero)) {
      final p = dic[forma];
      if (p != null) return p;
    }
    return null;
  }

  /// La palabra tal cual y sus posibles formas base: sin plural (perros,
  /// ratones, luces) y en masculino (perra, doctora). En una frase se cambia
  /// solo la primera palabra (tomates de árbol).
  static Iterable<String> _formas(String n, {required bool conGenero}) sync* {
    yield n;
    final partes = n.split(' ');
    final resto = partes.skip(1).map((p) => ' $p').join();
    for (final base in _singulares(partes.first)) {
      if (base != partes.first) yield '$base$resto';
      if (conGenero) {
        for (final masc in _masculinos(base)) {
          yield '$masc$resto';
        }
      }
    }
  }

  static Iterable<String> _singulares(String p) sync* {
    yield p;
    if (p.endsWith('ces')) yield '${p.substring(0, p.length - 3)}z';
    if (p.endsWith('es')) yield p.substring(0, p.length - 2);
    if (p.endsWith('s')) yield p.substring(0, p.length - 1);
  }

  static Iterable<String> _masculinos(String p) sync* {
    if (p.endsWith('ora')) yield p.substring(0, p.length - 1);
    if (p.endsWith('a')) yield '${p.substring(0, p.length - 1)}o';
  }

  /// Parte un texto (dictado o escrito) en respuestas. Primero busca frases
  /// de varias palabras que estén en algún diccionario («Santa Marta»,
  /// «oso hormiguero»); lo demás va palabra por palabra, sin las de relleno.
  static List<String> separar(String texto, Categoria categoria) {
    final palabras = normalizar(texto).split(' ').where((p) => p.isNotEmpty).toList();
    final respuestas = <String>[];
    var i = 0;
    while (i < palabras.length) {
      var tomadas = 1;
      for (var n = _maxPalabrasFrase; n > 1; n--) {
        if (i + n > palabras.length) continue;
        final frase = palabras.sublist(i, i + n).join(' ');
        if (buscar(frase, categoria) != null || Categoria.values.any((c) => buscar(frase, c) != null)) {
          tomadas = n;
          break;
        }
      }
      final respuesta = palabras.sublist(i, i + tomadas).join(' ');
      final esRelleno = tomadas == 1 && (_relleno.contains(respuesta) || respuesta.length < 2);
      if (!esRelleno || buscar(respuesta, categoria) != null) respuestas.add(respuesta);
      i += tomadas;
    }
    return respuestas;
  }

  /// Veredicto de [respuesta] (ya separada) para [categoria], dadas las
  /// palabras ya [aceptadas] (como están en el diccionario).
  static Evaluacion evaluar(String respuesta, Categoria categoria, Iterable<String> aceptadas) {
    final n = normalizar(respuesta);
    final propia = buscar(n, categoria);
    if (propia != null) {
      final repetida = aceptadas.contains(propia);
      return (veredicto: repetida ? Veredicto.repetida : Veredicto.valida, palabra: propia, categoria: categoria);
    }
    for (final otra in Categoria.values) {
      if (otra == categoria) continue;
      final p = buscar(n, otra);
      if (p != null) return (veredicto: Veredicto.otraCategoria, palabra: p, categoria: otra);
    }
    return (veredicto: Veredicto.noReconocida, palabra: n, categoria: null);
  }
}
