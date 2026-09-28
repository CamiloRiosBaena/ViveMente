import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/utils/cedula.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/core/widgets/pantalla_registro.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

/// Paso 2 de 3 · Cédula del adulto mayor. Si ya está registrado se salta el
/// paso de datos y se entra al inicio.
class AdultoCedulaView extends ConsumerStatefulWidget {
  const AdultoCedulaView({super.key});

  @override
  ConsumerState<AdultoCedulaView> createState() => _AdultoCedulaViewState();
}

class _AdultoCedulaViewState extends ConsumerState<AdultoCedulaView> {
  final _cedula = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _cedula.dispose();
    super.dispose();
  }

  bool get _valida => cedulaValida(_cedula.text);

  Future<void> _continuar() async {
    if (!_valida || _cargando) return;
    setState(() => _cargando = true);

    try {
      final existe = await ref.read(sesionProvider.notifier).elegirAdulto(_cedula.text);
      if (!mounted) return;
      if (existe) {
        context.go('/inicio');
      } else {
        context.push('/adulto/datos');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuardaSesion(
      permite: (s) => s.hayEvaluador,
      destino: '/',
      child: PantallaRegistro(
        paso: 2,
        onAtras: () => volverOIr(context, '/evaluador'),
        titulo: 'Cédula del adulto\nmayor',
        subtitulo: 'Identificación del adulto mayor para registro de los resultados',
        cuerpo: CampoEtiquetado(
          etiqueta: 'Número de cédula',
          controller: _cedula,
          autofocus: true,
          habilitado: !_cargando,
          teclado: TextInputType.number,
          formatos: formatosCedula,
          accion: TextInputAction.done,
          onChanged: (_) => setState(() {}),
          onEnviar: _continuar,
          ayuda: 'Este dato no se puede editar una vez guardada la sesión.',
        ),
        boton: BotonGrande(
          texto: 'Continuar',
          cargando: _cargando,
          onPressed: _valida ? _continuar : null,
        ),
      ),
    );
  }
}
