import 'package:flutter/material.dart';

class BarraProgreso extends StatelessWidget {
  const BarraProgreso({
    super.key,
    required this.valor,
    required this.color,
    required this.fondo,
    this.alto = 8,
  });

  final double valor;
  final Color color;
  final Color fondo;
  final double alto;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(99),
    child: LinearProgressIndicator(
      value: valor.clamp(0, 1),
      minHeight: alto,
      color: color,
      backgroundColor: fondo,
    ),
  );
}
