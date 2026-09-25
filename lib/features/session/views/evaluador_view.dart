import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/utils/cedula.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_registro.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';

/// Paso 1 de 3 · ¿Quién aplica? Se verifica la cédula: si el evaluador ya existe
/// se entra directo; si no, se pide el nombre una sola vez.
class EvaluadorView extends ConsumerStatefulWidget {
  const EvaluadorView({super.key});

  @override
  ConsumerState<EvaluadorView> createState() => _EvaluadorViewState();
}

class _EvaluadorViewState extends ConsumerState<EvaluadorView> {
  final _cedula = TextEditingController();
  final _nombre = TextEditingController();
  final _foco = FocusNode();

  bool _nuevo = false;
  bool _cargando = false;

  @override
  void dispose() {
    _cedula.dispose();
    _nombre.dispose();
    _foco.dispose();
    super.dispose();
  }

  bool get _puedeContinuar =>
      cedulaValida(_cedula.text) && (!_nuevo || _nombre.text.trim().length >= 3);

  void _alCambiarCedula(String _) => setState(() => _nuevo = false);

  Future<void> _continuar() async {
    if (!_puedeContinuar || _cargando) return;
    setState(() => _cargando = true);
    final sesion = ref.read(sesionProvider.notifier);

    try {
      if (_nuevo) {
        await sesion.registrarEvaluador(_cedula.text, _nombre.text.trim());
      } else if (!await sesion.iniciarConCedula(_cedula.text)) {
        if (!mounted) return;
        setState(() => _nuevo = true);
        _foco.requestFocus();
        return;
      }
      if (mounted) context.push('/adulto/cedula');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PantallaRegistro(
      paso: 1,
      icono: Icons.person_outline_rounded,
      titulo: '¿Quién aplica\nla valoración?',
      subtitulo: 'Queda registrado con la fecha y hora de cada sesión para efectos de auditoría.',
      cuerpo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CampoEtiquetado(
            etiqueta: 'Cédula del evaluador',
            controller: _cedula,
            autofocus: true,
            habilitado: !_cargando,
            teclado: TextInputType.number,
            formatos: formatosCedula,
            accion: _nuevo ? TextInputAction.next : TextInputAction.done,
            onChanged: _alCambiarCedula,
            onEnviar: _nuevo ? null : _continuar,
            ayuda: 'Este dato no se puede editar una vez guardada la sesión.',
          ),
          if (_nuevo) ...[
            const SizedBox(height: 22),
            CampoEtiquetado(
              etiqueta: 'Nombre del evaluador',
              controller: _nombre,
              focusNode: _foco,
              habilitado: !_cargando,
              mayusculas: TextCapitalization.words,
              accion: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onEnviar: _continuar,
              ayuda: 'Es la primera vez que ingresa con esta cédula. '
                  'Escriba su nombre; quedará guardado para las próximas sesiones.',
            ),
          ],
        ],
      ),
      boton: BotonGrande(
        texto: _nuevo ? 'Guardar y continuar' : 'Continuar',
        cargando: _cargando,
        onPressed: _puedeContinuar ? _continuar : null,
      ),
    );
  }
}
