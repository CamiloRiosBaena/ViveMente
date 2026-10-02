import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/features/fluidez_verbal/comun/widgets/oidas_en_vivo.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/models/categoria.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/providers/palabras_categoria_provider.dart';
import 'package:vivamente/features/fluidez_verbal/palabras_categoria/widgets/ficha_categoria.dart';

/// Ronda: la categoría arriba, cronómetro y cuenta, el campo para escribir
/// con el micrófono al lado, y lo que lleva dicho, sin evaluar: se revisa
/// al terminar.
class CategoriaJuegoView extends ConsumerStatefulWidget {
  const CategoriaJuegoView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  ConsumerState<CategoriaJuegoView> createState() => _CategoriaJuegoViewState();
}

class _CategoriaJuegoViewState extends ConsumerState<CategoriaJuegoView> {
  final _texto = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _texto.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Envía lo escrito y deja el teclado abierto para la siguiente palabra.
  void _enviar() {
    if (ref.read(palabrasCategoriaProvider.notifier).anadir(_texto.text)) _texto.clear();
    _foco.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(palabrasCategoriaProvider);
    final notifier = ref.read(palabrasCategoriaProvider.notifier);
    final m = Bp.margenFlujo(context);
    final tecladoAbierto = MediaQuery.viewInsetsOf(context).bottom > 0;

    ref.listen(palabrasCategoriaProvider.select((s) => s.avisoDictado), (_, _) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text(
            'No se pudo usar el micrófono. Revise que la app tenga permiso '
            'para usarlo, o escriba sus palabras.',
          ),
        ));
    });
    // Al reanudar, el campo vuelve a tomar el teclado.
    ref.listen(palabrasCategoriaProvider.select((s) => s.pausado), (_, pausado) {
      if (!pausado) _foco.requestFocus();
    });

    return Scaffold(
      backgroundColor: AppColors.papel,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(categoria: s.categoria, practica: s.practica, onPausa: notifier.pausar),
              Padding(
                padding: EdgeInsets.fromLTRB(m, 14, m, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Tiempo',
                        valor: s.textoTiempo,
                        icono: Icons.timer_outlined,
                        alerta: s.restante < const Duration(seconds: 15),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Dato(
                        etiqueta: 'Palabras',
                        valor: '${s.oidas.length}',
                        icono: Icons.edit_note_rounded,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(m, 14, m, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _texto,
                        focusNode: _foco,
                        autofocus: true,
                        enabled: !s.pausado,
                        // Sin sugerencias: el teclado no debe proponer palabras.
                        autocorrect: false,
                        enableSuggestions: false,
                        textInputAction: TextInputAction.send,
                        inputFormatters: [
                          // Con espacios, para nombres como «Santa Marta».
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-ZñÑáéíóúüÁÉÍÓÚÜ ]')),
                          LengthLimitingTextInputFormatter(40),
                        ],
                        // Con onEditingComplete el teclado no se cierra al enviar.
                        onEditingComplete: _enviar,
                        style: AppTheme.cuerpo(23, color: AppColors.texto),
                        decoration: InputDecoration(
                          hintText: 'Escriba una palabra',
                          hintStyle: AppTheme.cuerpo(20, color: AppColors.textoTenue),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                          suffixIcon: IconButton(
                            tooltip: 'Añadir',
                            onPressed: _enviar,
                            icon: const Icon(Icons.send_rounded, color: AppColors.azul, size: 28),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _BotonMicrofono(encendido: s.escuchando, onTap: notifier.alternarMicrofono),
                  ],
                ),
              ),
              if (s.escuchando)
                Padding(
                  padding: EdgeInsets.fromLTRB(m, 8, m, 0),
                  child: EstadoEscucha(conectado: s.conectado),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: m),
                  child: FichasOidas(palabras: s.oidas),
                ),
              ),
              // Con el teclado abierto se esconde para dejar sitio a las palabras.
              if (!tecladoAbierto)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(m, 12, m, 20),
                    child: BotonSecundario(
                      texto: 'Terminar',
                      icono: Icons.flag_outlined,
                      onPressed: () => _confirmarTerminar(context, notifier),
                    ),
                  ),
                ),
            ],
          ),
          if (s.pausado) Positioned.fill(child: _Pausa(onSeguir: notifier.reanudar, onSalir: widget.onSalir)),
        ],
      ),
    );
  }

  /// Terminar antes de tiempo se confirma: es fácil tocarlo sin querer.
  static Future<void> _confirmarTerminar(BuildContext context, PalabrasCategoriaNotifier notifier) async {
    final si = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.papel,
        title: Text('¿Terminar ahora?', style: AppTheme.titulo(26)),
        content: Text(
          'Aún le queda tiempo. Si termina, pasa a revisar las palabras que lleva.',
          style: AppTheme.cuerpo(19, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BotonGrande(texto: 'Sí, terminar', onPressed: () => Navigator.pop(context, true)),
              const SizedBox(height: 10),
              BotonSecundario(texto: 'Seguir jugando', onPressed: () => Navigator.pop(context, false)),
            ],
          ),
        ],
      ),
    );
    if (si ?? false) notifier.terminar();
  }
}

/// «Diga palabras de:» y la categoría con su emoji. En la práctica lo dice.
class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.categoria, required this.practica, required this.onPausa});

  final Categoria categoria;
  final bool practica;
  final VoidCallback onPausa;

  @override
  Widget build(BuildContext context) {
    final m = Bp.margenFlujo(context);

    return Container(
      color: Dominio.fluidezVerbal.color,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(m, 12, m, 14),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Pausar',
                excludeSemantics: true,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: onPausa,
                    child: const SizedBox(
                      width: 52,
                      height: 52,
                      child: Icon(Icons.pause_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Semantics(
                  header: true,
                  label: '${practica ? 'Práctica. ' : ''}Diga palabras de la categoría ${categoria.nombre}',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        practica ? 'PRÁCTICA' : 'DIGA PALABRAS DE:',
                        style: AppTheme.mono(13, color: AppColors.azulClaro, letterSpacing: 1, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(categoria.nombre, style: AppTheme.titulo(26, color: Colors.white, height: 1.1)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              EmojiCategoria(categoria, tamano: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor, required this.icono, this.alerta = false});

  final String etiqueta;
  final String valor;
  final IconData icono;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final color = alerta ? AppColors.rojo : AppColors.texto;

    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: alerta ? AppColors.rojo : AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            Icon(icono, color: alerta ? AppColors.rojo : AppColors.textoSuave, size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(etiqueta.toUpperCase(), style: AppTheme.mono(12, color: AppColors.textoSuave, letterSpacing: 1)),
                  Text(valor, style: AppTheme.titulo(24, color: color, height: 1.1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enciende o apaga el micrófono; encendido se pone rojo.
class _BotonMicrofono extends StatelessWidget {
  const _BotonMicrofono({required this.encendido, required this.onTap});

  final bool encendido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        toggled: encendido,
        label: encendido ? 'Apagar el micrófono' : 'Encender el micrófono',
        excludeSemantics: true,
        child: Material(
          color: encendido ? AppColors.rojo : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: encendido ? AppColors.rojo : AppColors.borde, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(
                encendido ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: encendido ? Colors.white : AppColors.azul,
                size: 32,
              ),
            ),
          ),
        ),
      );
}

class _Pausa extends StatelessWidget {
  const _Pausa({required this.onSeguir, required this.onSalir});

  final VoidCallback onSeguir;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black54,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.papel,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(header: true, child: Text('En pausa', style: AppTheme.titulo(30))),
                  const SizedBox(height: 8),
                  Text('El tiempo está detenido. Siga cuando esté listo.', style: AppTheme.cuerpo(19, height: 1.4)),
                  const SizedBox(height: 22),
                  BotonGrande(texto: 'Seguir', onPressed: onSeguir),
                  const SizedBox(height: 12),
                  BotonSecundario(texto: 'Salir de la actividad', onPressed: onSalir),
                ],
              ),
            ),
          ),
        ),
      );
}
