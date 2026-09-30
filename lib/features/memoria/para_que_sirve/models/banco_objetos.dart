import 'package:flutter/material.dart';

/// Un objeto de la vida diaria, con un emoji que lo dibuja. Los emoji son de
/// 2018 o antes y de los que vienen a color por defecto, para que se vean
/// igual en equipos viejos y en la web.
class Objeto {
  const Objeto(this.nombre, this.emoji);

  final String nombre;
  final String emoji;

  @override
  bool operator ==(Object other) => other is Objeto && other.nombre == nombre;

  @override
  int get hashCode => nombre.hashCode;

  @override
  String toString() => nombre;
}

/// Nivel 1: un objeto y para qué sirve.
class ObjetoFuncion {
  const ObjetoFuncion(this.objeto, this.funcion, this.explicacion, {this.grupo});

  final Objeto objeto;

  /// «Abrir y cerrar puertas». Las de otros objetos sirven de distractores.
  final String funcion;
  final String explicacion;

  /// Objetos con funciones parecidas (la linterna y el bombillo alumbran):
  /// no se ponen de distractores entre sí.
  final String? grupo;

  bool compatibleCon(ObjetoFuncion otro) =>
      otro.objeto != objeto && (grupo == null || otro.grupo != grupo);
}

/// Los contenedores temáticos del nivel 2.
enum Lugar {
  cocina('Cocina', Icons.kitchen_outlined),
  bano('Baño', Icons.bathtub_outlined),
  herramientas('Caja de herramientas', Icons.handyman_outlined),
  armario('Armario', Icons.checkroom_outlined),
  escritorio('Escritorio', Icons.menu_book_outlined);

  const Lugar(this.etiqueta, this.icono);
  final String etiqueta;
  final IconData icono;
}

/// Nivel 2: un objeto y el lugar al que pertenece.
class ObjetoLugar {
  const ObjetoLugar(this.objeto, this.lugar, this.explicacion);

  final Objeto objeto;
  final Lugar lugar;
  final String explicacion;
}

/// Grupos de las parejas del nivel 3. Los distractores salen de otro grupo,
/// para que no haya dos respuestas razonables.
enum TemaPareja { granja, cocina, hogar, ropa, calle }

/// Nivel 3: un objeto y aquel con el que se relaciona por su uso o su origen
/// (lápiz → papel, abeja → miel).
class Pareja {
  const Pareja(this.objeto, this.pareja, this.tema, this.explicacion, {this.excluir = const []});

  final Objeto objeto;
  final Objeto pareja;
  final TemaPareja tema;
  final String explicacion;

  /// Parejas de otros grupos que igual podrían parecer correctas.
  final List<String> excluir;

  /// Cocina y granja comparten alimentos (pan con miel, cuchara y leche).
  bool compatibleCon(Pareja otra) =>
      otra.tema != tema &&
      !(({tema, otra.tema}).containsAll([TemaPareja.cocina, TemaPareja.granja])) &&
      !excluir.contains(otra.pareja.nombre) &&
      !otra.excluir.contains(pareja.nombre);
}

/// Todo el contenido del juego.
abstract final class BancoObjetos {
  // Objetos.
  static const _llave = Objeto('Llave', '🔑');
  static const _escoba = Objeto('Escoba', '🧹');
  static const _martillo = Objeto('Martillo', '🔨');
  static const _sombrilla = Objeto('Sombrilla', '🌂');
  static const _linterna = Objeto('Linterna', '🔦');
  static const _jabon = Objeto('Jabón', '🧼');
  static const _cuchara = Objeto('Cuchara', '🥄');
  static const _telefono = Objeto('Teléfono', '📞');
  static const _gafas = Objeto('Gafas', '👓');
  static const _bombillo = Objeto('Bombillo', '💡');
  static const _candado = Objeto('Candado', '🔒');
  static const _esponja = Objeto('Esponja', '🧽');
  static const _sarten = Objeto('Sartén', '🍳');
  static const _ducha = Objeto('Ducha', '🚿');
  static const _hilo = Objeto('Hilo', '🧵');
  static const _regla = Objeto('Regla', '📏');
  static const _pastilla = Objeto('Pastilla', '💊');
  static const _camara = Objeto('Cámara', '📷');
  static const _radio = Objeto('Radio', '📻');
  static const _monedero = Objeto('Monedero', '👛');
  static const _pila = Objeto('Pila', '🔋');
  static const _cuchillo = Objeto('Cuchillo', '🔪');
  static const _salero = Objeto('Salero', '🧂');
  static const _cubiertos = Objeto('Cubiertos', '🍴');
  static const _taza = Objeto('Taza', '🍵');
  static const _papelHigienico = Objeto('Papel higiénico', '🧻');
  static const _crema = Objeto('Crema', '🧴');
  static const _banera = Objeto('Bañera', '🛁');
  static const _llaveInglesa = Objeto('Llave inglesa', '🔧');
  static const _tornillo = Objeto('Tornillo', '🔩');
  static const _medias = Objeto('Medias', '🧦');
  static const _zapatos = Objeto('Zapatos', '👟');
  static const _guantes = Objeto('Guantes', '🧤');
  static const _bufanda = Objeto('Bufanda', '🧣');
  static const _gorra = Objeto('Gorra', '🧢');
  static const _camisa = Objeto('Camisa', '👕');
  static const _vestido = Objeto('Vestido', '👗');
  static const _libro = Objeto('Libro', '📖');
  static const _clip = Objeto('Clip', '📎');
  static const _chincheta = Objeto('Chinche', '📌');
  static const _cuaderno = Objeto('Cuaderno', '📓');
  static const _puerta = Objeto('Puerta', '🚪');
  static const _enchufe = Objeto('Enchufe', '🔌');
  static const _televisor = Objeto('Televisor', '📺');
  static const _carta = Objeto('Carta', '💌');
  static const _buzon = Objeto('Buzón', '📬');
  static const _sopa = Objeto('Sopa', '🍲');
  static const _pan = Objeto('Pan', '🍞');
  static const _abeja = Objeto('Abeja', '🐝');
  static const _miel = Objeto('Miel', '🍯');
  static const _gallina = Objeto('Gallina', '🐔');
  static const _huevo = Objeto('Huevo', '🥚');
  static const _oveja = Objeto('Oveja', '🐑');
  static const _lana = Objeto('Lana', '🧶');
  static const _vaca = Objeto('Vaca', '🐄');
  static const _leche = Objeto('Leche', '🥛');
  static const _cana = Objeto('Caña de pescar', '🎣');
  static const _pez = Objeto('Pez', '🐟');
  static const _agua = Objeto('Agua', '💧');
  static const _tarjeta = Objeto('Tarjeta', '💳');
  static const _cajero = Objeto('Cajero', '🏧');

  /// Ejemplo de las instrucciones. No sale como pregunta, pero su función sí
  /// puede salir como distractor.
  static const ejemplo = ObjetoFuncion(_llave, 'Abrir y cerrar puertas',
      'La llave abre y cierra las cerraduras de puertas, cajones y candados.', grupo: 'cerradura');

  static const funciones = [
    ejemplo,
    ObjetoFuncion(_escoba, 'Barrer el piso', 'La escoba recoge el polvo y la basura del piso.'),
    ObjetoFuncion(_martillo, 'Clavar puntillas', 'Con el martillo se golpean las puntillas para clavarlas en la madera.'),
    ObjetoFuncion(_sombrilla, 'Protegerse de la lluvia', 'La sombrilla se abre sobre la cabeza para no mojarse cuando llueve.'),
    ObjetoFuncion(_linterna, 'Alumbrar en la oscuridad',
        'La linterna da luz cuando se va la energía o de noche, y funciona con pilas.', grupo: 'luz'),
    ObjetoFuncion(_jabon, 'Lavarse las manos', 'El jabón, con agua, quita la mugre y los microbios de las manos.', grupo: 'aseo'),
    ObjetoFuncion(_cuchara, 'Tomar la sopa', 'La cuchara es cóncava: recoge los líquidos como la sopa o el caldo.'),
    ObjetoFuncion(_telefono, 'Hablar con alguien que está lejos',
        'El teléfono lleva la voz a otra persona, aunque esté en otra ciudad.'),
    ObjetoFuncion(_gafas, 'Ver mejor', 'Las gafas corrigen la vista para leer o ver de lejos con claridad.'),
    ObjetoFuncion(_bombillo, 'Iluminar la casa', 'El bombillo convierte la energía en luz para alumbrar los cuartos.', grupo: 'luz'),
    ObjetoFuncion(_candado, 'Asegurar una reja o una maleta',
        'El candado mantiene cerrada una reja, una cadena o una maleta; se abre con su llave.', grupo: 'cerradura'),
    ObjetoFuncion(_esponja, 'Lavar los platos', 'La esponja, con jabón, restriega la loza hasta dejarla limpia.', grupo: 'aseo'),
    ObjetoFuncion(_sarten, 'Fritar los alimentos', 'En la sartén se fritan huevos, plátanos y otros alimentos con un poco de aceite.'),
    ObjetoFuncion(_ducha, 'Bañarse', 'La ducha deja caer el agua para bañarse de pies a cabeza.', grupo: 'aseo'),
    ObjetoFuncion(_hilo, 'Coser la ropa', 'Con hilo y aguja se cosen los botones y se remiendan las prendas.'),
    ObjetoFuncion(_regla, 'Medir y trazar líneas rectas', 'La regla tiene marcas en centímetros para medir y trazar derecho.'),
    ObjetoFuncion(_pastilla, 'Tratar una enfermedad',
        'Las pastillas son medicamentos; se toman como las indica el médico.'),
    ObjetoFuncion(_camara, 'Tomar fotos', 'La cámara guarda imágenes de personas, lugares y momentos.'),
    ObjetoFuncion(_radio, 'Escuchar noticias y música', 'El radio recibe las emisoras con noticias, música y programas.'),
    ObjetoFuncion(_monedero, 'Guardar el dinero', 'En el monedero se llevan las monedas y los billetes sin perderlos.'),
    ObjetoFuncion(_pila, 'Dar energía a los aparatos',
        'Las pilas guardan energía para el control remoto, el reloj o la linterna.', grupo: 'luz'),
  ];

  static const ejemploLugar =
      ObjetoLugar(_taza, Lugar.cocina, 'La taza va en la cocina: en ella se sirven el café, el té o el chocolate.');

  static const lugares = [
    ObjetoLugar(_cuchara, Lugar.cocina, 'La cuchara va en la cocina: con ella se sirve y se toma la sopa.'),
    ObjetoLugar(_sarten, Lugar.cocina, 'La sartén va en la cocina: sirve para fritar los alimentos en la estufa.'),
    ObjetoLugar(_cuchillo, Lugar.cocina, 'El cuchillo va en la cocina: sirve para picar y tajar los alimentos.'),
    ObjetoLugar(_salero, Lugar.cocina, 'El salero va en la cocina o en la mesa: guarda la sal para sazonar.'),
    ObjetoLugar(_cubiertos, Lugar.cocina, 'El tenedor y el cuchillo se guardan en la cocina y se usan en la mesa.'),
    ObjetoLugar(_jabon, Lugar.bano, 'El jabón va en el baño: sirve para lavarse las manos y el cuerpo.'),
    ObjetoLugar(_papelHigienico, Lugar.bano, 'El papel higiénico va en el baño, junto al sanitario.'),
    ObjetoLugar(_ducha, Lugar.bano, 'La ducha está en el baño: allí nos bañamos.'),
    ObjetoLugar(_crema, Lugar.bano, 'La crema se guarda en el baño: humecta la piel después del baño.'),
    ObjetoLugar(_banera, Lugar.bano, 'La bañera está en el baño: se llena de agua para bañarse.'),
    ObjetoLugar(_martillo, Lugar.herramientas, 'El martillo va en la caja de herramientas: sirve para clavar.'),
    ObjetoLugar(_llaveInglesa, Lugar.herramientas,
        'La llave inglesa va en la caja de herramientas: aprieta y afloja tuercas.'),
    ObjetoLugar(_tornillo, Lugar.herramientas,
        'Los tornillos se guardan en la caja de herramientas para armar y arreglar cosas.'),
    ObjetoLugar(_medias, Lugar.armario, 'Las medias se guardan en el armario, con la ropa.'),
    ObjetoLugar(_zapatos, Lugar.armario, 'Los zapatos se guardan en el armario o en el zapatero.'),
    ObjetoLugar(_guantes, Lugar.armario, 'Los guantes se guardan en el armario: abrigan las manos cuando hace frío.'),
    ObjetoLugar(_bufanda, Lugar.armario, 'La bufanda se guarda en el armario: abriga el cuello.'),
    ObjetoLugar(_gorra, Lugar.armario, 'La gorra se guarda en el armario: protege la cabeza del sol.'),
    ObjetoLugar(_camisa, Lugar.armario, 'La camisa se cuelga en el armario, con el resto de la ropa.'),
    ObjetoLugar(_vestido, Lugar.armario, 'El vestido se cuelga en el armario, con el resto de la ropa.'),
    ObjetoLugar(_libro, Lugar.escritorio, 'El libro va en el escritorio o en la biblioteca: allí se lee y se estudia.'),
    ObjetoLugar(_regla, Lugar.escritorio, 'La regla va en el escritorio: sirve para medir y trazar líneas.'),
    ObjetoLugar(_clip, Lugar.escritorio, 'El clip va en el escritorio: mantiene juntas las hojas de papel.'),
    ObjetoLugar(_chincheta, Lugar.escritorio, 'El chinche va en el escritorio: sujeta papeles en un tablero.'),
    ObjetoLugar(_cuaderno, Lugar.escritorio, 'El cuaderno va en el escritorio: en él se escribe y se toman notas.'),
  ];

  static const ejemploPareja = Pareja(_gallina, _huevo, TemaPareja.granja, 'La gallina pone los huevos.');

  /// El ejemplo no sale como pregunta, pero el huevo sí puede ser distractor.
  static const parejas = [
    ejemploPareja,
    Pareja(_llave, _puerta, TemaPareja.hogar, 'La llave abre y cierra la puerta.', excluir: ['Buzón']),
    Pareja(_enchufe, _televisor, TemaPareja.hogar, 'El televisor se conecta al enchufe para funcionar.'),
    Pareja(_pila, _linterna, TemaPareja.hogar, 'La linterna funciona con pilas.'),
    Pareja(_jabon, _agua, TemaPareja.hogar, 'El jabón se usa con agua para lavar.'),
    Pareja(_cuchara, _sopa, TemaPareja.cocina, 'La sopa se toma con cuchara.'),
    Pareja(_pan, _cuchillo, TemaPareja.cocina, 'El pan se corta en tajadas con el cuchillo.'),
    Pareja(_hilo, _camisa, TemaPareja.ropa, 'Con hilo se cosen y se arreglan prendas como la camisa.'),
    Pareja(_medias, _zapatos, TemaPareja.ropa, 'Las medias se ponen y luego van los zapatos encima.'),
    Pareja(_abeja, _miel, TemaPareja.granja, 'Las abejas producen la miel en el panal.'),
    Pareja(_oveja, _lana, TemaPareja.granja, 'La lana se saca del pelo de la oveja.'),
    Pareja(_vaca, _leche, TemaPareja.granja, 'La vaca da la leche.'),
    Pareja(_carta, _buzon, TemaPareja.calle, 'Las cartas se dejan en el buzón para enviarlas.'),
    Pareja(_tarjeta, _cajero, TemaPareja.calle, 'Con la tarjeta se saca dinero del cajero.'),
    Pareja(_cana, _pez, TemaPareja.calle, 'Con la caña de pescar se pescan los peces.'),
    Pareja(_gafas, _libro, TemaPareja.calle, 'Las gafas ayudan a leer la letra de los libros.',
        excluir: ['Televisor']),
  ];
}
