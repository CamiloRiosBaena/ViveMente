import 'package:flutter/material.dart';

/// Botón de avance: 76 px de alto, siempre azul. Con [onPressed] nulo queda deshabilitado.
class BotonGrande extends StatelessWidget {
  const BotonGrande({super.key, required this.texto, required this.onPressed, this.cargando = false});
  final String texto;
  final VoidCallback? onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 76,
        child: FilledButton(
          onPressed: cargando ? null : onPressed,
          child: cargando
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                )
              : FittedBox(fit: BoxFit.scaleDown, child: Text(texto, maxLines: 1)),
        ),
      );
}
