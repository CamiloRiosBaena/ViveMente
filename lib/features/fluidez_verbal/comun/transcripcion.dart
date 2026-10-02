/// Una respuesta tal como se dio, aún sin evaluar.
class RespuestaOida {
  const RespuestaOida(this.texto, this.momento, {this.dictada = false});

  final String texto;

  /// Cuándo se oyó o se envió, desde el inicio de la ronda.
  final Duration momento;

  /// Si llegó por el micrófono en vez del teclado.
  final bool dictada;
}

/// Una respuesta y dónde empieza dentro de las palabras de una frase.
typedef Corte = ({String texto, int inicio});

/// Lo que se dijo o escribió en una ronda, guardado tal cual para evaluarlo
/// al final.
///
/// Cada escucha del micrófono es un segmento, y cada texto escrito otro. El
/// reconocedor de voz no se porta igual en todos los equipos: unos mandan
/// una y otra vez todo lo que llevan oído, corrigiéndolo; otros empiezan de
/// cero tras cada pausa; algunos mandan el resultado final vacío. Por eso un
/// segmento se guarda en frases y nada de lo que llega borra lo ya oído:
/// - lo que se parece a la frase abierta la corrige o la alarga;
/// - lo que no se parece abre otra frase y la anterior se queda;
/// - un texto vacío no cambia nada.
class Transcripcion {
  final _segmentos = <_Segmento>[];

  static final _separador = RegExp(r'[^a-zñáéíóúü]+');

  /// Tras este silencio, un texto más corto que la frase abierta ya no se
  /// toma como corrección sino como otra frase que empieza igual.
  static const _pausaFrase = Duration(milliseconds: 1500);

  bool get vacia => _segmentos.every((s) => s.frases.every((f) => f.palabras.isEmpty));

  /// Abre un segmento y devuelve su número, para [poner].
  int abrir({required bool dictado}) {
    _segmentos.add(_Segmento(dictado));
    return _segmentos.length - 1;
  }

  /// Suma al [segmento] lo que llegó. Con [esFinal] la frase se cierra: lo
  /// que venga después es otra frase. Cada palabra conserva el momento en que
  /// apareció por primera vez en su posición, aunque luego se corrija.
  void poner(int segmento, String texto, Duration ahora, {bool esFinal = false}) {
    final s = _segmentos[segmento];
    var palabras = texto.toLowerCase().split(_separador).where((p) => p.isNotEmpty).toList();

    // El final de una escucha puede llegar tarde, cuando ya se abrió la
    // siguiente: corrige la frase que quedó sin cerrar.
    if (s.dictado && s.frases.isEmpty && palabras.isNotEmpty) {
      final previa = _segmentos.take(segmento).lastWhere((p) => p.dictado, orElse: () => s);
      final f = previa.frases.lastOrNull;
      if (!identical(previa, s) && f != null && !f.cerrada && _mismaFrase(f.palabras, palabras)) {
        f.poner(palabras, ahora);
        f.cerrada = esFinal;
        return;
      }
    }

    // Quien repite todo lo de la escucha trae al inicio las frases ya
    // cerradas: solo interesa lo que sigue.
    final cerradas = [for (final f in s.frases) if (f.cerrada) ...f.palabras];
    if (cerradas.isNotEmpty &&
        palabras.length >= cerradas.length &&
        _parecidas(cerradas, palabras.sublist(0, cerradas.length))) {
      palabras = palabras.sublist(cerradas.length);
    }

    final abierta = s.abierta;
    if (palabras.isEmpty) {
      if (esFinal) abierta?.cerrada = true;
      return;
    }
    if (abierta != null && !_sigue(abierta, palabras, ahora, esFinal: esFinal)) abierta.cerrada = true;
    final f = s.abierta ?? (_Frase()..cambio = ahora);
    if (!identical(f, s.abierta)) s.frases.add(f);
    f.poner(palabras, ahora);
    f.cerrada = esFinal;
  }

  /// Si [palabras] corrige o alarga la frase [f] en vez de empezar otra.
  static bool _sigue(_Frase f, List<String> palabras, Duration ahora, {required bool esFinal}) {
    if (!_mismaFrase(f.palabras, palabras)) return false;
    if (esFinal || ahora - f.cambio < _pausaFrase) return true;
    // Tras una pausa solo la alarga: más larga y con lo anterior al inicio.
    // Si no, es otra frase aunque se parezca («mar» y luego «mal»).
    return palabras.length > f.palabras.length && _parecidas(f.palabras, palabras);
  }

  /// Si [b] es otra versión de la frase [a]: empieza igual y conserva, en
  /// orden, al menos la mitad de las palabras de la más corta. Así el
  /// reconocedor puede intercalar conectores («moto muro» → «moto y la
  /// muro») o corregir alguna.
  static bool _mismaFrase(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty || !_parecida(a.first, b.first)) return false;
    // Palabras en común y en el mismo orden (subsecuencia común más larga).
    var fila = List.filled(b.length + 1, 0);
    for (final x in a) {
      final nueva = List.filled(b.length + 1, 0);
      for (var j = 0; j < b.length; j++) {
        nueva[j + 1] = _parecida(x, b[j])
            ? fila[j] + 1
            : (fila[j + 1] > nueva[j] ? fila[j + 1] : nueva[j]);
      }
      fila = nueva;
    }
    final corta = a.length < b.length ? a.length : b.length;
    return 2 * fila[b.length] >= corta;
  }

  /// Si las dos empiezan con las mismas palabras, salvo pequeñas
  /// correcciones.
  static bool _parecidas(List<String> a, List<String> b) {
    final n = a.length < b.length ? a.length : b.length;
    if (n == 0) return false;
    for (var i = 0; i < n; i++) {
      if (!_parecida(a[i], b[i])) return false;
    }
    return true;
  }

  /// La misma palabra, una que se está completando («man» → «mano») o con una
  /// letra cambiada, de más o de menos («pera» → «perra»).
  static bool _parecida(String a, String b) {
    if (a == b || a.startsWith(b) || b.startsWith(a)) return true;
    if ((a.length - b.length).abs() > 1) return false;
    var i = 0;
    while (i < a.length && i < b.length && a[i] == b[i]) {
      i++;
    }
    var j = 0;
    while (j < a.length - i && j < b.length - i && a[a.length - 1 - j] == b[b.length - 1 - j]) {
      j++;
    }
    return a.length - i - j <= 1 && b.length - i - j <= 1;
  }

  void limpiar() => _segmentos.clear();

  /// Las respuestas en el orden en que se dieron. [cortar] parte las
  /// palabras de una frase en respuestas (cada juego sabe cuáles son relleno
  /// o cuáles van juntas).
  List<RespuestaOida> respuestas(List<Corte> Function(List<String> palabras, {required bool dictado}) cortar) {
    final todas = <(int, RespuestaOida)>[];
    for (final s in _segmentos) {
      for (final f in s.frases) {
        for (final c in cortar(f.palabras, dictado: s.dictado)) {
          todas.add((todas.length, RespuestaOida(c.texto, f.momentos[c.inicio], dictada: s.dictado)));
        }
      }
    }
    // Lo escrito mientras el micrófono escuchaba queda en su lugar.
    todas.sort((a, b) {
      final t = a.$2.momento.compareTo(b.$2.momento);
      return t != 0 ? t : a.$1.compareTo(b.$1);
    });
    return [for (final (_, r) in todas) r];
  }
}

class _Segmento {
  _Segmento(this.dictado);

  final bool dictado;
  final frases = <_Frase>[];

  _Frase? get abierta => frases.isNotEmpty && !frases.last.cerrada ? frases.last : null;
}

/// Lo que el reconocedor oyó de un tirón, entre dos pausas.
class _Frase {
  List<String> palabras = const [];

  /// Nunca se acorta: si el reconocedor quita una palabra y luego la vuelve
  /// a poner, conserva su momento.
  final List<Duration> momentos = [];

  /// Cuándo cambió por última vez.
  Duration cambio = Duration.zero;

  /// Ya llegó su resultado final, o empezó otra frase después.
  bool cerrada = false;

  void poner(List<String> nuevas, Duration ahora) {
    palabras = nuevas;
    cambio = ahora;
    while (momentos.length < palabras.length) {
      momentos.add(ahora);
    }
  }
}

/// Lo que decide quien revisa una respuesta al terminar.
enum Ajuste {
  /// Cuenta según la evaluación automática.
  ninguno,

  /// Cuenta como válida aunque la app no la reconociera.
  aceptada,

  /// No se tiene en cuenta: el micrófono oyó mal o se coló un ruido.
  descartada,
}
