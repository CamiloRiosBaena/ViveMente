import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/campo_etiquetado.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/core/widgets/pantalla_registro.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

const _sexos = ['Femenino', 'Masculino'];

/// Paso 3 de 3 · Datos del adulto mayor nuevo.
class AdultoDatosView extends ConsumerStatefulWidget {
  const AdultoDatosView({super.key});

  @override
  ConsumerState<AdultoDatosView> createState() => _AdultoDatosViewState();
}

class _AdultoDatosViewState extends ConsumerState<AdultoDatosView> {
  final _formKey = GlobalKey<FormState>();
  final _nombres = TextEditingController();
  final _apellidos = TextEditingController();
  final _edad = TextEditingController();
  String? _sexo;
  bool _cargando = false;

  /// Los errores aparecen tras el primer intento de guardar, no mientras se escribe.
  bool _intentado = false;

  @override
  void dispose() {
    _nombres.dispose();
    _apellidos.dispose();
    _edad.dispose();
    super.dispose();
  }

  String? _obligatorio(String? v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  String? _validarEdad(String? v) {
    final e = int.tryParse(v ?? '');
    if (e == null) return 'Obligatorio';
    if (e < 1 || e > 120) return 'No válida';
    return null;
  }

  Future<void> _guardar() async {
    if (_cargando) return;
    setState(() => _intentado = true);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);

    try {
      await ref.read(sesionProvider.notifier).guardarAdulto(
            nombres: _nombres.text.trim(),
            apellidos: _apellidos.text.trim(),
            sexo: _sexo!,
            edad: int.parse(_edad.text),
          );
      if (mounted) context.go('/inicio');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuardaSesion(
      permite: (s) => s.hayEvaluador && s.cedulaAdulto.isNotEmpty,
      destino: '/',
      child: PantallaRegistro(
        paso: 3,
        onAtras: () => volverOIr(context, '/adulto/cedula'),
        titulo: 'Datos del\nadulto mayor',
        cuerpo: Form(
          key: _formKey,
          autovalidateMode: _intentado ? AutovalidateMode.always : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoEtiquetado(
                etiqueta: 'Nombres',
                controller: _nombres,
                autofocus: true,
                habilitado: !_cargando,
                mayusculas: TextCapitalization.words,
                validador: _obligatorio,
              ),
              const SizedBox(height: 20),
              CampoEtiquetado(
                etiqueta: 'Apellidos',
                controller: _apellidos,
                habilitado: !_cargando,
                mayusculas: TextCapitalization.words,
                validador: _obligatorio,
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _CampoSexo(valor: _sexo, onChanged: _cargando ? null : (v) => setState(() => _sexo = v))),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: CampoEtiquetado(
                      etiqueta: 'Edad',
                      controller: _edad,
                      habilitado: !_cargando,
                      teclado: TextInputType.number,
                      formatos: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      accion: TextInputAction.done,
                      onEnviar: _guardar,
                      validador: _validarEdad,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        boton: BotonGrande(texto: 'Guardar y continuar', cargando: _cargando, onPressed: _guardar),
      ),
    );
  }
}

class _CampoSexo extends StatelessWidget {
  const _CampoSexo({required this.valor, required this.onChanged});

  final String? valor;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const EtiquetaCampo('Sexo'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: valor,
            isExpanded: true,
            onChanged: onChanged,
            hint: Text('Elegir', style: AppTheme.cuerpo(20)),
            style: AppTheme.cuerpo(21, color: const Color(0xFF3D2B1C)),
            items: [for (final s in _sexos) DropdownMenuItem(value: s, child: Text(s))],
            validator: (v) => v == null ? 'Elija una opción' : null,
          ),
        ],
      );
}
