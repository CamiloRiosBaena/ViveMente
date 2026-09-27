enum TipoEstimulo { letra, minuscula, numero, figura, fruta }

/// Una casilla de la cuadrícula: una letra, un número, una figura o una fruta.
/// Dos estímulos son iguales si muestran el mismo símbolo.
class Estimulo {
  const Estimulo(this.simbolo, this.tipo);

  /// Deduce el tipo a partir del símbolo.
  factory Estimulo.de(String simbolo) => Estimulo(simbolo, _tipoDe(simbolo));

  final String simbolo;
  final TipoEstimulo tipo;

  static final _mayuscula = RegExp(r'^[A-ZÑ]$');
  static final _minuscula = RegExp(r'^[a-zñ]$');
  static final _numero = RegExp(r'^[0-9]$');

  static TipoEstimulo _tipoDe(String s) {
    if (_mayuscula.hasMatch(s)) return TipoEstimulo.letra;
    if (_minuscula.hasMatch(s)) return TipoEstimulo.minuscula;
    if (_numero.hasMatch(s)) return TipoEstimulo.numero;
    if (CatalogoEstimulos.frutas.contains(s)) return TipoEstimulo.fruta;
    return TipoEstimulo.figura;
  }

  @override
  bool operator ==(Object other) => other is Estimulo && other.simbolo == simbolo;

  @override
  int get hashCode => simbolo.hashCode;

  @override
  String toString() => simbolo;
}

/// Un estímulo que puede pedirse como objetivo, con cómo se nombra y cuáles se
/// le parecen (para el nivel 3).
class Objetivo {
  const Objetivo({
    required this.simbolo,
    required this.encabezado,
    required this.todos,
    required this.parecidos,
  });

  final String simbolo;

  /// «Encuentra la letra», «Encuentra el número», «Encuentra la figura».
  final String encabezado;

  /// «todas las letras A», «todos los números 7», «todas las estrellas».
  final String todos;

  /// Símbolos que se confunden con este a simple vista.
  final List<String> parecidos;

  Estimulo get estimulo => Estimulo.de(simbolo);
}

/// Todos los estímulos que pueden aparecer.
abstract final class CatalogoEstimulos {
  static const frutas = ['🍎', '🍋', '🍇', '🍐', '🍌', '🍊', '🍒', '🍓', '🍅', '🫐'];

  /// Objetivos posibles: en cada intento se sortea uno.
  static const objetivos = [
    Objetivo(simbolo: 'A', encabezado: 'Encuentra la letra', todos: 'todas las letras A', parecidos: ['4', 'R', 'H', 'a']),
    Objetivo(simbolo: 'E', encabezado: 'Encuentra la letra', todos: 'todas las letras E', parecidos: ['F', 'B', '3', 'e']),
    Objetivo(simbolo: 'M', encabezado: 'Encuentra la letra', todos: 'todas las letras M', parecidos: ['N', 'W', 'H', 'm']),
    Objetivo(simbolo: 'R', encabezado: 'Encuentra la letra', todos: 'todas las letras R', parecidos: ['P', 'B', 'K', 'r']),
    Objetivo(simbolo: 'B', encabezado: 'Encuentra la letra', todos: 'todas las letras B', parecidos: ['8', 'R', 'P', 'b']),
    Objetivo(simbolo: '7', encabezado: 'Encuentra el número', todos: 'todos los números 7', parecidos: ['1', 'T', 'L', '4']),
    Objetivo(simbolo: '8', encabezado: 'Encuentra el número', todos: 'todos los números 8', parecidos: ['B', '3', '0', '6']),
    Objetivo(simbolo: '6', encabezado: 'Encuentra el número', todos: 'todos los números 6', parecidos: ['9', 'b', 'G', '5']),
    Objetivo(simbolo: '★', encabezado: 'Encuentra la figura', todos: 'todas las estrellas', parecidos: ['☆', '✱', '✦', '◆']),
    Objetivo(simbolo: '△', encabezado: 'Encuentra la figura', todos: 'todos los triángulos', parecidos: ['▽', '▲', '◁', '▷']),
    Objetivo(simbolo: '○', encabezado: 'Encuentra la figura', todos: 'todos los círculos', parecidos: ['●', '◎', 'O', '0']),
    Objetivo(simbolo: '□', encabezado: 'Encuentra la figura', todos: 'todos los cuadrados', parecidos: ['■', '◇', '▢', '▭']),
    Objetivo(simbolo: '🍎', encabezado: 'Encuentra la fruta', todos: 'todas las manzanas', parecidos: ['🍒', '🍓', '🍅']),
    Objetivo(simbolo: '🍋', encabezado: 'Encuentra la fruta', todos: 'todos los limones', parecidos: ['🍌', '🍐', '🍊']),
  ];

  /// Mezcla de distractores de los niveles 1 y 2: mayúsculas, minúsculas,
  /// números, figuras y frutas.
  static const variados = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'K', 'L', 'M', 'N', 'P', 'R', 'S', 'T', //
    'a', 'b', 'd', 'e', 'g', 'h', 'm', 'n', 'r', 't', //
    '2', '3', '4', '5', '6', '7', '8', '9', //
    '○', '□', '△', '★', '♥', '◇', //
    '🍎', '🍋', '🍇', '🍐', '🍌', '🍊',
  ];
}
