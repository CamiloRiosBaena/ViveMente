import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Campo de texto con la etiqueta encima y una nota de ayuda debajo.
class CampoEtiquetado extends StatelessWidget {
  const CampoEtiquetado({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.ayuda,
    this.hint,
    this.teclado,
    this.formatos,
    this.mayusculas = TextCapitalization.none,
    this.accion = TextInputAction.next,
    this.autofocus = false,
    this.focusNode,
    this.habilitado = true,
    this.onChanged,
    this.onEnviar,
    this.validador,
  });

  final String etiqueta;
  final TextEditingController controller;
  final String? ayuda;
  final String? hint;
  final TextInputType? teclado;
  final List<TextInputFormatter>? formatos;
  final TextCapitalization mayusculas;
  final TextInputAction accion;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool habilitado;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEnviar;
  final FormFieldValidator<String>? validador;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EtiquetaCampo(etiqueta),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: habilitado,
            autofocus: autofocus,
            focusNode: focusNode,
            keyboardType: teclado,
            inputFormatters: formatos,
            textCapitalization: mayusculas,
            textInputAction: accion,
            onChanged: onChanged,
            onFieldSubmitted: onEnviar == null ? null : (_) => onEnviar!(),
            validator: validador,
            style: AppTheme.cuerpo(23, color: const Color(0xFF3D2B1C)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTheme.cuerpo(22, color: AppColors.textoTenue),
            ),
          ),
          if (ayuda != null) ...[
            const SizedBox(height: 10),
            Text(ayuda!, style: AppTheme.cuerpo(17, color: AppColors.textoTenue, height: 1.4)),
          ],
        ],
      );
}

/// Etiqueta en negrita que va sobre un campo.
class EtiquetaCampo extends StatelessWidget {
  const EtiquetaCampo(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) =>
      Text(texto, style: AppTheme.cuerpo(19, color: AppColors.texto, weight: FontWeight.w700));
}
