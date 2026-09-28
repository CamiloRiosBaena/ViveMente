/// Colores posibles de locomotoras y vagones. El valor visual de cada uno vive
/// en `tren_colores.dart`, junto a los widgets.
enum ColorTren {
  rojo('rojo'),
  azul('azul'),
  verde('verde'),
  amarillo('amarillo'),
  morado('morado'),
  gris('gris'),
  cafe('café'),
  naranja('naranja'),
  vino('vino'),
  rosado('rosado'),
  terracota('terracota'),
  celeste('celeste'),
  turquesa('turquesa'),
  marino('marino'),
  lila('lila'),
  oliva('oliva'),
  lima('lima'),
  verdeOscuro('verde oscuro'),
  mostaza('mostaza'),
  dorado('dorado'),
  // Vagón de relleno, neutro y común a todos los trenes
  relleno('');

  const ColorTren(this.etiqueta);
  final String etiqueta;

  /// «trenes rojos», «trenes azules». Los colores objetivo son adjetivos que
  /// concuerdan; los demás (vino, lila, café…) se usan igual en plural.
  String get plural => switch (this) {
        ColorTren.rojo => 'rojos',
        ColorTren.azul => 'azules',
        ColorTren.verde => 'verdes',
        ColorTren.amarillo => 'amarillos',
        ColorTren.morado => 'morados',
        _ => etiqueta,
      };
}

/// Qué colores sirven de objetivo y, para cada uno, cuáles contrastan y cuáles
/// se le parecen.
abstract final class PaletaTren {
  /// Colores fáciles de nombrar; en cada intento se sortea uno.
  static const objetivos = [
    ColorTren.rojo,
    ColorTren.azul,
    ColorTren.verde,
    ColorTren.amarillo,
    ColorTren.morado,
  ];

  /// Ordenados de más a menos contrastante: el nivel 1 toma los primeros.
  static const _contrastantes = {
    ColorTren.rojo: [ColorTren.azul, ColorTren.verde, ColorTren.amarillo, ColorTren.morado, ColorTren.gris],
    ColorTren.azul: [ColorTren.rojo, ColorTren.amarillo, ColorTren.verde, ColorTren.naranja, ColorTren.cafe],
    ColorTren.verde: [ColorTren.rojo, ColorTren.amarillo, ColorTren.morado, ColorTren.azul, ColorTren.cafe],
    ColorTren.amarillo: [ColorTren.azul, ColorTren.rojo, ColorTren.morado, ColorTren.verde, ColorTren.gris],
    ColorTren.morado: [ColorTren.amarillo, ColorTren.verde, ColorTren.rojo, ColorTren.naranja, ColorTren.gris],
  };

  static const _parecidos = {
    ColorTren.rojo: [ColorTren.naranja, ColorTren.vino, ColorTren.rosado, ColorTren.terracota],
    ColorTren.azul: [ColorTren.celeste, ColorTren.turquesa, ColorTren.marino, ColorTren.lila],
    ColorTren.verde: [ColorTren.oliva, ColorTren.lima, ColorTren.turquesa, ColorTren.verdeOscuro],
    ColorTren.amarillo: [ColorTren.naranja, ColorTren.mostaza, ColorTren.lima, ColorTren.dorado],
    ColorTren.morado: [ColorTren.lila, ColorTren.vino, ColorTren.marino, ColorTren.rosado],
  };

  static List<ColorTren> contrastantes(ColorTren objetivo) => _contrastantes[objetivo]!;
  static List<ColorTren> parecidos(ColorTren objetivo) => _parecidos[objetivo]!;
}

/// Un tren de la secuencia. Cuenta como objetivo solo si la locomotora es del
/// color objetivo: los vagones pueden serlo para confundir.
class Tren {
  const Tren({
    required this.id,
    required this.locomotora,
    required this.vagones,
    required this.salida,
    required this.esObjetivo,
  });

  final int id;
  final ColorTren locomotora;
  final List<ColorTren> vagones;

  /// Momento, desde el inicio de la ronda, en que asoma por la derecha.
  final Duration salida;

  final bool esObjetivo;
}
