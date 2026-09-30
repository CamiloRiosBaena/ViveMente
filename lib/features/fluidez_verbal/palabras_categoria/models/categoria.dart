/// Una categoría de la ronda, con el diccionario que valida sus palabras.
///
/// Las palabras se comparan sin tildes ni mayúsculas, y se aceptan el plural
/// y, en animales, profesiones y colores, el femenino (perra, doctora, roja).
/// Lo que no está en el diccionario no cuenta, pero queda anotado aparte
/// para que el profesional lo revise.
enum Categoria {
  animales('Animales', 'animales', '🐶', meta: 16, conGenero: true, palabras: _animales),
  frutas('Frutas', 'frutas', '🍎', meta: 12, palabras: _frutas),
  hogar('Objetos del hogar', 'objetos de la casa', '🏠', meta: 14, palabras: _hogar),
  profesiones('Profesiones', 'profesiones u oficios', '💼', meta: 11, conGenero: true, palabras: _profesiones),
  ciudades('Ciudades', 'ciudades, de Colombia o del mundo', '🌆', meta: 12, palabras: _ciudades),

  /// Solo para la práctica.
  colores('Colores', 'colores', '🎨', meta: 6, conGenero: true, palabras: _colores);

  const Categoria(
    this.nombre,
    this.enConsigna,
    this.emoji, {
    required this.meta,
    required this.palabras,
    this.conGenero = false,
  });

  /// «Frutas».
  final String nombre;

  /// «Diga nombres de …»: «frutas», «objetos de la casa».
  final String enConsigna;
  final String emoji;

  /// Palabras válidas que dan el puntaje completo en 60 segundos. Cerca de lo
  /// que dice un adulto mayor sin deterioro con esa categoría.
  final int meta;

  /// Palabras aceptadas, como se muestran.
  final List<String> palabras;

  /// Si se acepta el femenino (gata → gato).
  final bool conGenero;
}

const _animales = [
  'perro', 'gato', 'vaca', 'toro', 'buey', 'ternero', 'becerro', 'novillo', 'caballo', 'yegua', 'potro', 'burro', //
  'asno', 'mula', 'oveja', 'carnero', 'cordero', 'borrego', 'cabra', 'chivo', 'cabro', 'cerdo', 'marrano', 'puerco',
  'chancho', 'lechón', 'gallina', 'gallo', 'pollo', 'pollito', 'pato', 'ganso', 'pavo', 'conejo', 'ratón', 'rata',
  'ardilla', 'hámster', 'cuy', 'curí', 'león', 'tigre', 'leopardo', 'jaguar', 'puma', 'pantera', 'guepardo',
  'lince', 'ocelote', 'elefante', 'jirafa', 'cebra', 'hipopótamo', 'rinoceronte', 'camello', 'dromedario', 'llama',
  'alpaca', 'vicuña', 'oso', 'oso hormiguero', 'oso perezoso', 'panda', 'koala', 'canguro', 'mono', 'mico', 'tití',
  'gorila', 'chimpancé', 'orangután', 'lobo', 'zorro', 'coyote', 'hiena', 'ciervo', 'venado', 'alce', 'reno',
  'antílope', 'gacela', 'búfalo', 'bisonte', 'jabalí', 'castor', 'nutria', 'foca', 'león marino', 'morsa', 'ballena',
  'delfín', 'tiburón', 'orca', 'pez', 'pescado', 'pulpo', 'calamar', 'medusa', 'estrella de mar', 'caballito de mar',
  'cangrejo', 'langosta', 'langostino', 'camarón', 'almeja', 'ostra', 'caracol', 'babosa', 'lombriz', 'gusano',
  'araña', 'escorpión', 'alacrán', 'hormiga', 'abeja', 'abejorro', 'avispa', 'mosca', 'mosquito', 'zancudo',
  'cucaracha', 'grillo', 'saltamontes', 'chapulín', 'mariposa', 'polilla', 'libélula', 'escarabajo', 'cucarrón',
  'mariquita', 'luciérnaga', 'ciempiés', 'pulga', 'piojo', 'garrapata', 'serpiente', 'culebra', 'víbora', 'boa',
  'anaconda', 'cobra', 'cascabel', 'lagarto', 'lagartija', 'iguana', 'camaleón', 'cocodrilo', 'caimán', 'babilla',
  'tortuga', 'morrocoy', 'rana', 'sapo', 'salamandra', 'águila', 'halcón', 'cóndor', 'buitre', 'gallinazo', 'búho',
  'lechuza', 'loro', 'guacamaya', 'perico', 'cotorra', 'paloma', 'tórtola', 'canario', 'colibrí', 'tucán', 'pelícano',
  'flamenco', 'cigüeña', 'garza', 'pingüino', 'avestruz', 'gaviota', 'cuervo', 'golondrina', 'gorrión', 'pájaro',
  'ave', 'pavo real', 'murciélago', 'zarigüeya', 'chucha', 'armadillo', 'perezoso', 'tapir', 'danta', 'chigüiro',
  'capibara', 'guatín', 'guatusa', 'ñeque', 'marmota', 'topo', 'erizo', 'puercoespín', 'mapache', 'comadreja',
  'hurón', 'trucha', 'salmón', 'atún', 'sardina', 'bagre', 'mojarra', 'bocachico', 'tilapia', 'piraña', 'anguila',
  'raya', 'mantarraya', 'pez espada', 'dinosaurio', 'mamut', 'yak', 'suricato', 'chacal', 'turpial',
  'azulejo', 'sinsonte', 'toche', 'garrapatero', 'pisco', 'codorniz', 'faisán', 'perdiz', 'guacharaca',
];

const _frutas = [
  'manzana', 'pera', 'banano', 'plátano', 'guineo', 'naranja', 'mandarina', 'limón', 'lima', 'toronja', //
  'pomelo', 'uva', 'uva pasa', 'fresa', 'frutilla', 'frambuesa', 'mora', 'arándano', 'cereza', 'guinda', 'durazno',
  'melocotón', 'ciruela', 'albaricoque', 'nectarina', 'mango', 'papaya', 'piña', 'sandía', 'patilla', 'melón', 'kiwi',
  'coco', 'guayaba', 'maracuyá', 'granadilla', 'lulo', 'curuba', 'tomate de árbol', 'guanábana', 'chirimoya', 'anón',
  'pitahaya', 'feijoa', 'uchuva', 'mangostino', 'zapote', 'mamoncillo', 'borojó', 'chontaduro', 'badea',
  'carambola', 'corozo', 'níspero', 'higo', 'dátil', 'aguacate', 'tamarindo', 'caimito', 'arazá', 'copoazú',
  'marañón', 'mamey', 'noni', 'grosella', 'membrillo', 'granada', 'babaco', 'guama', 'pomarrosa', 'ciruela pasa',
  'mandarino', 'tangelo', 'lichi', 'gulupa', 'agraz', 'madroño', 'algarrobo', 'mortiño',
];

const _hogar = [
  'mesa', 'silla', 'sofá', 'sillón', 'cama', 'colchón', 'almohada', 'cobija', 'sábana', 'cobertor', 'edredón', //
  'cortina', 'alfombra', 'tapete', 'lámpara', 'bombillo', 'foco', 'espejo', 'reloj', 'despertador', 'cuadro',
  'portarretrato', 'florero', 'jarrón', 'televisor', 'radio', 'nevera', 'refrigerador', 'congelador',
  'estufa', 'horno', 'microondas', 'licuadora', 'batidora', 'tostadora', 'cafetera', 'olla', 'olla a presión',
  'sartén', 'paila', 'cuchara', 'cucharón', 'tenedor', 'cuchillo', 'plato', 'vaso', 'taza', 'pocillo', 'jarra',
  'copa', 'tetera', 'colador', 'rallador', 'tabla de picar', 'bandeja', 'servilleta', 'mantel', 'escoba', 'trapero',
  'recogedor', 'balde', 'cubeta', 'aspiradora', 'plancha', 'tabla de planchar', 'lavadora', 'secadora', 'lavaplatos',
  'jabón', 'detergente', 'esponja', 'toalla', 'cepillo', 'cepillo de dientes', 'crema dental', 'peine', 'secador',
  'ventilador', 'abanico', 'calentador', 'armario', 'clóset', 'ropero', 'cómoda', 'mesa de noche', 'nochero',
  'escritorio', 'estante', 'repisa', 'biblioteca', 'librero', 'cajón', 'gaveta', 'perchero', 'gancho', 'percha',
  'teléfono', 'celular', 'computador', 'control remoto', 'enchufe', 'interruptor', 'puerta',
  'ventana', 'llave', 'candado', 'timbre', 'cerradura', 'basurero', 'caneca', 'papelera', 'matera', 'maceta',
  'cojín', 'hamaca', 'mecedora', 'banco', 'butaca', 'taburete', 'baúl', 'canasta', 'cesto', 'termo', 'botella',
  'extractor', 'lavamanos', 'ducha', 'sanitario', 'inodoro', 'tina', 'bañera', 'grifo', 'vela', 'candelabro',
  'fósforo', 'encendedor', 'linterna', 'pila', 'tijeras', 'aguja', 'hilo', 'dedal', 'costurero', 'máquina de coser',
  'escalera', 'martillo', 'destornillador', 'alicate', 'taladro', 'calendario', 'parlante', 'equipo de sonido',
  'tendedero', 'pinza', 'papel higiénico', 'jabonera', 'espumadera', 'destapador', 'abrelatas', 'sacacorchos',
  'mortero', 'pilón', 'molinillo', 'tapa', 'recipiente', 'tarro', 'frasco', 'extensión', ];

const _profesiones = [
  'médico', 'doctor', 'enfermero', 'odontólogo', 'dentista', 'psicólogo', 'psiquiatra', 'fisioterapeuta', //
  'nutricionista', 'farmaceuta', 'farmacéutico', 'veterinario', 'bacteriólogo', 'cirujano', 'pediatra', 'ginecólogo',
  'cardiólogo', 'oftalmólogo', 'optómetra', 'terapeuta', 'partero', 'paramédico', 'camillero', 'profesor', 'maestro',
  'docente', 'rector', 'educador', 'abogado', 'juez', 'notario', 'fiscal', 'policía', 'militar', 'soldado',
  'bombero', 'guardia', 'vigilante', 'celador', 'detective', 'ingeniero', 'arquitecto', 'contador', 'economista',
  'administrador', 'secretario', 'recepcionista', 'gerente', 'vendedor', 'cajero', 'comerciante', 'tendero',
  'mesero', 'cocinero', 'chef', 'panadero', 'pastelero', 'repostero', 'carnicero', 'barista', 'cantinero',
  'mecánico', 'electricista', 'plomero', 'fontanero', 'carpintero', 'ebanista', 'albañil', 'pintor', 'soldador',
  'herrero', 'cerrajero', 'zapatero', 'sastre', 'modista', 'costurero', 'peluquero', 'barbero', 'estilista',
  'manicurista', 'maquillador', 'agricultor', 'campesino', 'granjero', 'ganadero', 'jardinero', 'pescador', 'minero',
  'leñador', 'apicultor', 'conductor', 'chofer', 'taxista', 'camionero', 'piloto', 'azafata', 'marinero',
  'capitán', 'mensajero', 'cartero', 'repartidor', 'domiciliario', 'periodista', 'escritor', 'poeta',   'editor', 'fotógrafo', 'camarógrafo', 'actor', 'cantante', 'músico', 'bailarín', 'artista', 'escultor',
  'diseñador', 'dibujante', 'locutor', 'presentador', 'científico', 'biólogo', 'químico', 'físico', 'matemático',
  'astrónomo', 'geólogo', 'historiador', 'filósofo', 'sociólogo', 'antropólogo', 'arqueólogo', 'bibliotecario',
  'traductor', 'intérprete', 'informático', 'programador', 'técnico', 'operario', 'obrero', 'niñero', 'cuidador',
  'sacerdote', 'cura', 'pastor', 'monja', 'alcalde', 'gobernador', 'presidente', 'senador', 'concejal', 'político',
  'diplomático', 'embajador', 'empresario', 'banquero', 'asesor', 'analista', 'auditor', 'topógrafo', 'guía',
  'guardabosques', 'salvavidas', 'árbitro', 'entrenador', 'deportista', 'futbolista', 'ciclista', 'boxeador',
  'torero', 'payaso', 'mago', 'portero', 'conserje', 'aseador', 'barrendero', 'reciclador', 'lustrabotas',
  'embolador', 'relojero', 'joyero', 'orfebre', 'tejedor', 'artesano', 'alfarero', 'ceramista', 'impresor',
  'empleada doméstica', 'enfermera jefe', 'odontóloga', 'auxiliar de enfermería', 'auxiliar de vuelo', 'aviador',
  'astronauta', 'inventor', 'investigador', 'publicista', 'dermatólogo', 'neurólogo', 'urólogo', 'anestesiólogo',
];

const _ciudades = [
  // Colombia
  'Bogotá', 'Medellín', 'Cali', 'Barranquilla', 'Cartagena', 'Cúcuta', 'Bucaramanga', 'Pereira', 'Santa Marta', //
  'Ibagué', 'Manizales', 'Villavicencio', 'Pasto', 'Montería', 'Neiva', 'Armenia', 'Valledupar', 'Popayán',
  'Sincelejo', 'Tunja', 'Riohacha', 'Quibdó', 'Florencia', 'Yopal', 'Leticia', 'Arauca', 'Mocoa', 'San Andrés',
  'Puerto Carreño', 'Inírida', 'Mitú', 'San José del Guaviare', 'Buenaventura', 'Tuluá', 'Palmira', 'Buga', 'Cartago',
  'Girardot', 'Soacha', 'Zipaquirá', 'Chía', 'Facatativá', 'Fusagasugá', 'Duitama', 'Sogamoso', 'Chiquinquirá',
  'Barrancabermeja', 'Floridablanca', 'Girón', 'Piedecuesta', 'Bello', 'Envigado', 'Itagüí', 'Rionegro',
  'Apartadó', 'Turbo', 'Sabaneta', 'La Dorada', 'Honda', 'Espinal', 'Melgar', 'Magangué', 'Lorica', 'Cereté',
  'Sahagún', 'Aguachica', 'Ocaña', 'Pamplona', 'Maicao', 'Ipiales', 'Tumaco', 'Jamundí', 'Yumbo', 'Dosquebradas',
  'Santa Rosa de Cabal', 'Calarcá', 'Soledad', 'Malambo', 'Sabanalarga', 'Ciénaga', 'Fundación', 'El Banco',
  'Mompox', 'Villa de Leyva', 'Guatapé', 'Jardín', 'Salento', 'Filandia', 'Barichara', 'San Gil', 'Socorro',
  'Vélez', 'Puerto Boyacá', 'Puerto Berrío', 'Caucasia', 'Santa Fe de Antioquia', 'La Ceja', 'Marinilla', 'Guarne',
  'Mosquera', 'Funza', 'Cajicá', 'Sibaté', 'La Mesa', 'Villeta', 'Anapoima', 'Garzón', 'Pitalito', 'La Plata',
  'Chaparral', 'Líbano', 'Mariquita', 'Puerto López', 'Granada', 'Acacías', 'Aguazul', 'Plato', 'Corozal', 'Tolú',
  'Coveñas', 'Necoclí', 'El Carmen de Bolívar', 'Turbaco', 'Arjona', 'Montelíbano', 'Planeta Rica',
  'Santander de Quilichao', 'Puerto Asís', 'Sibundoy', 'Chinchiná', 'Riosucio', 'Anserma', 'Santa Rosa', 'Zarzal',
  'Sevilla', 'Roldanillo', 'Caicedonia', 'Guaduas', 'Puerto Salgar', 'Bahía Solano', 'Nuquí', 'Capurganá',
  // Mundo
  'Madrid', 'Barcelona', 'Valencia', 'Bilbao', 'Málaga', 'París', 'Londres', 'Roma', 'Milán', 'Venecia', 'Nápoles',
  'Berlín', 'Múnich', 'Viena', 'Ámsterdam', 'Bruselas', 'Lisboa', 'Oporto', 'Atenas', 'Moscú', 'Estambul', 'Praga',
  'Varsovia', 'Budapest', 'Dublín', 'Estocolmo', 'Oslo', 'Copenhague', 'Helsinki', 'Zúrich', 'Ginebra', 'Mónaco',
  'Nueva York', 'Los Ángeles', 'Chicago', 'Miami', 'Houston', 'Washington', 'San Francisco', 'Las Vegas', 'Boston',
  'Orlando', 'Nueva Orleans', 'Dallas', 'Atlanta', 'Filadelfia', 'Toronto', 'Montreal', 'Vancouver', 'México',
  'Ciudad de México', 'Guadalajara', 'Monterrey', 'Cancún', 'Acapulco', 'Guatemala', 'San José', 'Panamá',
  'Managua', 'Tegucigalpa', 'San Salvador', 'La Habana', 'Santo Domingo', 'San Juan', 'Caracas', 'Maracaibo',
  'Mérida', 'Quito', 'Guayaquil', 'Cuenca', 'Lima', 'Cusco', 'Arequipa', 'La Paz', 'Santa Cruz', 'Sucre', 'Santiago',
  'Valparaíso', 'Buenos Aires', 'Córdoba', 'Rosario', 'Mendoza', 'Montevideo', 'Asunción', 'Río de Janeiro',
  'São Paulo', 'Brasilia', 'Salvador', 'Manaos', 'Tokio', 'Pekín', 'Shanghái', 'Hong Kong', 'Seúl',
  'Bangkok', 'Singapur', 'Nueva Delhi', 'Delhi', 'Bombay', 'Dubái', 'Jerusalén', 'Belén', 'Nazaret', 'El Cairo',
  'Ciudad del Cabo', 'Johannesburgo', 'Nairobi', 'Casablanca', 'Sídney', 'Melbourne', 'Lourdes', 'Fátima',
  'Ciudad del Vaticano', 'Vaticano', 'Toledo', 'Salamanca', 'Marsella', 'Lyon', 'Liverpool',
  'Manchester', 'Edimburgo', 'Frankfurt', 'Hamburgo', ];

const _colores = [
  'rojo', 'azul', 'verde', 'amarillo', 'negro', 'blanco', 'gris', 'morado', 'violeta', 'rosado', 'rosa', 'naranja', //
  'anaranjado', 'café', 'marrón', 'beige', 'crema', 'dorado', 'plateado', 'celeste', 'lila', 'fucsia', 'turquesa',
  'vinotinto', 'ocre', 'salmón', 'mostaza', 'índigo', 'magenta', 'granate', 'carmesí', 'escarlata', 'aguamarina',
  'caqui', 'terracota', 'bermellón', 'púrpura', 'cian', 'marfil', 'bronce', 'cobre', 'verde oliva', 'azul oscuro',
  'azul claro', 'verde claro', 'verde oscuro', 'palo de rosa', 'coral', 'lavanda', 'mora',
];
