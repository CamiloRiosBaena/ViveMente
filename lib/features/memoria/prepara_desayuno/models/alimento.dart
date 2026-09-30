enum TipoAlimento { bebida, fruta, otro }

/// Un alimento de la bandeja, con su nombre y un emoji que lo dibuja. Dos
/// alimentos son iguales si se llaman igual.
class Alimento {
  const Alimento(this.nombre, this.emoji, this.tipo);

  final String nombre;
  final String emoji;
  final TipoAlimento tipo;

  @override
  bool operator ==(Object other) => other is Alimento && other.nombre == nombre;

  @override
  int get hashCode => nombre.hashCode;

  @override
  String toString() => nombre;
}

/// Todos los alimentos que pueden salir. Son de desayuno y se distinguen bien
/// entre sí a simple vista; los emoji son de 2018 o antes para que se vean en
/// equipos viejos. El café lleva el selector de emoji (FE0F): sin él algunas
/// fuentes lo dibujan como un símbolo en blanco y negro.
abstract final class CatalogoAlimentos {
  static const todos = [
    Alimento('Pan', '🍞', TipoAlimento.otro),
    Alimento('Huevo', '🥚', TipoAlimento.otro),
    Alimento('Queso', '🧀', TipoAlimento.otro),
    Alimento('Tocineta', '🥓', TipoAlimento.otro),
    Alimento('Aguacate', '🥑', TipoAlimento.otro),
    Alimento('Tomate', '🍅', TipoAlimento.otro),
    Alimento('Galletas', '🍪', TipoAlimento.otro),
    Alimento('Cereal', '🥣', TipoAlimento.otro),
    Alimento('Miel', '🍯', TipoAlimento.otro),
    Alimento('Café', '☕\u{FE0F}', TipoAlimento.bebida),
    Alimento('Leche', '🥛', TipoAlimento.bebida),
    Alimento('Té', '🍵', TipoAlimento.bebida),
    Alimento('Jugo', '🥤', TipoAlimento.bebida),
    Alimento('Manzana', '🍎', TipoAlimento.fruta),
    Alimento('Banano', '🍌', TipoAlimento.fruta),
    Alimento('Naranja', '🍊', TipoAlimento.fruta),
    Alimento('Uvas', '🍇', TipoAlimento.fruta),
    Alimento('Fresas', '🍓', TipoAlimento.fruta),
    Alimento('Pera', '🍐', TipoAlimento.fruta),
    Alimento('Piña', '🍍', TipoAlimento.fruta),
  ];

  /// Ejemplo de las instrucciones.
  static const ejemplo = [
    Alimento('Pan', '🍞', TipoAlimento.otro),
    Alimento('Café', '☕\u{FE0F}', TipoAlimento.bebida),
    Alimento('Huevo', '🥚', TipoAlimento.otro),
  ];
}

/// «pan, café, huevo y manzana».
String enumerarAlimentos(List<Alimento> alimentos) {
  final nombres = alimentos.map((a) => a.nombre.toLowerCase()).toList();
  if (nombres.length < 2) return nombres.join();
  return '${nombres.sublist(0, nombres.length - 1).join(', ')} y ${nombres.last}';
}
