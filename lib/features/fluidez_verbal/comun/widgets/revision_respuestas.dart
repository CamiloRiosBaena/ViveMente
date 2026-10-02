import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/fluidez_verbal/comun/transcripcion.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// Una respuesta como se muestra en la revisión.
class ItemRevision {
  const ItemRevision({required this.texto, required this.ajuste, this.motivo, this.grave = false});

  final String texto;
  final Ajuste ajuste;

  /// Por qué no cuenta según la app; `null` si cuenta.
  final String? motivo;

  /// Si el motivo es un error claro (otra letra u otra categoría) y no una
  /// duda (repetida, no reconocida).
  final bool grave;

  bool get cuenta => ajuste == Ajuste.aceptada || (ajuste == Ajuste.ninguno && motivo == null);
}

/// Al terminar la ronda: todo lo que se dijo o escribió, con lo que la app
/// decidió de cada palabra. Quien revisa puede quitar lo que el micrófono
/// oyó mal o aceptar una palabra que la app no reconoció; luego ve el
/// resultado.
class RevisionView extends StatelessWidget {
  const RevisionView({
    super.key,
    required this.juegoId,
    required this.items,
    required this.onAjustar,
    required this.onConfirmar,
  });

  final String juegoId;
  final List<ItemRevision> items;
  final void Function(int i, Ajuste ajuste) onAjustar;
  final VoidCallback onConfirmar;

  @override
  Widget build(BuildContext context) {
    final cuentan = items.where((i) => i.cuenta).length;

    return PantallaFlujo(
      cabecera: CabeceraJuego(juegoId: juegoId),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('Revise las palabras', style: AppTheme.titulo(32, height: 1.15))),
            const SizedBox(height: 8),
            Text(
              'Si el micrófono oyó mal una palabra, toque Quitar. '
              'Si una palabra sí valía y la app no la reconoció, toque Aceptar.',
              style: AppTheme.cuerpo(19, height: 1.4),
            ),
            const SizedBox(height: 14),
            Text(
              cuentan == 1 ? 'Cuenta 1 palabra.' : 'Cuentan $cuentan palabras.',
              style: AppTheme.titulo(21, color: AppColors.verdeTexto),
            ),
            const SizedBox(height: 10),
            ListaRevision(items: items, onAjustar: onAjustar),
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: BotonGrande(texto: 'Ver resultado', onPressed: onConfirmar),
    );
  }
}

/// Las respuestas una debajo de otra, con su veredicto. Sin [onAjustar] solo
/// se muestran (al terminar la práctica).
class ListaRevision extends StatelessWidget {
  const ListaRevision({super.key, required this.items, this.onAjustar});

  final List<ItemRevision> items;
  final void Function(int i, Ajuste ajuste)? onAjustar;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed)
            _Fila(item: item, onAjustar: onAjustar == null ? null : (a) => onAjustar!(i, a)),
        ],
      );
}

class _Fila extends StatelessWidget {
  const _Fila({required this.item, required this.onAjustar});

  final ItemRevision item;
  final ValueChanged<Ajuste>? onAjustar;

  @override
  Widget build(BuildContext context) {
    final descartada = item.ajuste == Ajuste.descartada;
    final (fondo, borde, color) = descartada
        ? (Colors.white, AppColors.borde, AppColors.textoTenue)
        : item.cuenta
            ? (AppColors.verdeSuave, AppColors.verde.withValues(alpha: 0.4), AppColors.verdeTexto)
            : item.grave
                ? (const Color(0xFFFDE4E1), AppColors.rojo.withValues(alpha: 0.4), AppColors.rojo)
                : (AppColors.naranjaSuave, AppColors.naranja.withValues(alpha: 0.4), AppColors.naranjaTexto);
    final detalle = switch (item.ajuste) {
      Ajuste.descartada => 'No se tiene en cuenta',
      Ajuste.aceptada => 'Aceptada al revisar',
      Ajuste.ninguno => item.motivo ?? 'Cuenta',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borde, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            descartada
                ? Icons.remove_circle_outline_rounded
                : item.cuenta
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.texto,
                  style: AppTheme.titulo(20, color: descartada ? AppColors.textoTenue : AppColors.texto).copyWith(
                    decoration: descartada ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(detalle, style: AppTheme.cuerpo(15, color: color)),
              ],
            ),
          ),
          if (onAjustar != null) ...[
            if (item.ajuste != Ajuste.ninguno)
              _Accion(texto: 'Deshacer', onTap: () => onAjustar!(Ajuste.ninguno))
            else ...[
              if (!item.cuenta) _Accion(texto: 'Aceptar', onTap: () => onAjustar!(Ajuste.aceptada)),
              _Accion(texto: 'Quitar', onTap: () => onAjustar!(Ajuste.descartada)),
            ],
          ],
        ],
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({required this.texto, required this.onTap});

  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.azul,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: AppTheme.titulo(17),
        ),
        child: Text(texto),
      );
}
