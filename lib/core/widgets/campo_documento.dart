import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CampoDocumento extends StatelessWidget {
  const CampoDocumento({ super.key, this.label = 'Numero de documento', required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label),
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    validator: (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null
  );
}