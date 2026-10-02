import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Con el micrófono encendido: «Escuchando» mientras el reconocedor oye, o
/// «Un momento…» mientras se vuelve a abrir tras un silencio, para no hablar
/// cuando nadie escucha.
class EstadoEscucha extends StatelessWidget {
  const EstadoEscucha({super.key, required this.conectado});

  final bool conectado;

  @override
  Widget build(BuildContext context) {
    final color = conectado ? AppColors.rojo : AppColors.textoSuave;

    return Semantics(
      liveRegion: true,
      child: Row(
        children: [
          Icon(conectado ? Icons.graphic_eq_rounded : Icons.hourglass_empty_rounded, color: color, size: 22),
          const SizedBox(width: 6),
          Text(
            conectado ? 'Escuchando' : 'Un momento…',
            style: AppTheme.cuerpo(17, color: color, weight: FontWeight.w700),
          ),
          if (conectado) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'diga sus palabras',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.cuerpo(17, color: AppColors.textoSuave).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Lo que se lleva dicho o escrito, sin decir si vale: se revisa al final.
/// Desplazable; al llegar una palabra se baja hasta ella.
class FichasOidas extends StatefulWidget {
  const FichasOidas({super.key, required this.palabras});

  final List<String> palabras;

  @override
  State<FichasOidas> createState() => _FichasOidasState();
}

class _FichasOidasState extends State<FichasOidas> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(FichasOidas antes) {
    super.didUpdateWidget(antes);
    if (widget.palabras.length > antes.palabras.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.only(top: 14),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in widget.palabras)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.azulSuave,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.azulBorde, width: 2),
                ),
                child: Text(p, style: AppTheme.titulo(19, color: AppColors.azul)),
              ),
          ],
        ),
      );
}
