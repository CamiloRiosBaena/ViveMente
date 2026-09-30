import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/models/alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/providers/prepara_desayuno_provider.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ficha_alimento.dart';
import 'package:vivamente/features/memoria/prepara_desayuno/widgets/ronda_desayuno.dart';

/// La lista del desayuno a la vista durante la exposición, con la cuenta
/// atrás de cuándo se oculta.
class DesayunoListaView extends ConsumerWidget {
  const DesayunoListaView({super.key, required this.onSalir});

  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(preparaDesayunoProvider);
    final notifier = ref.read(preparaDesayunoProvider.notifier);
    final m = Bp.margenFlujo(context);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabeceraRonda(
                titulo: s.practica ? 'Práctica' : 'Memorice la lista',
                subtitulo: s.practica ? 'Memorice la lista' : null,
                onPausa: notifier.pausar,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(m, 20, m, 24),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CuentaAtras(segundos: s.cuentaAtras, fraccion: s.exposicionRestante),
                        const SizedBox(height: 18),
                        // En pausa la lista se oculta: la pausa no alarga la exposición.
                        if (!s.pausado) _Lista(lista: s.lista, conOrden: s.nivel.conOrden),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (s.pausado) Positioned.fill(child: PausaDesayuno(onSeguir: notifier.reanudar, onSalir: onSalir)),
        ],
      ),
    );
  }
}

class _CuentaAtras extends StatelessWidget {
  const _CuentaAtras({required this.segundos, required this.fraccion});

  final int segundos;
  final double fraccion;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'La lista se oculta en $segundos segundos',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.visibility_outlined, color: AppColors.textoSuave, size: 26),
                const SizedBox(width: 8),
                Expanded(child: Text('Se oculta en', style: AppTheme.cuerpo(20, color: AppColors.texto))),
                Text('$segundos s', style: AppTheme.titulo(26, color: Dominio.memoria.color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fraccion,
                minHeight: 12,
                color: Dominio.memoria.color,
                backgroundColor: AppColors.crema,
              ),
            ),
          ],
        ),
      );
}

/// «Para preparar el desayuno necesita:» y un renglón por alimento. En el
/// nivel 3 cada renglón lleva su número.
class _Lista extends StatelessWidget {
  const _Lista({required this.lista, required this.conOrden});

  final List<Alimento> lista;
  final bool conOrden;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: 'Para preparar el desayuno necesita${conOrden ? ', en este orden' : ''}: ${enumerarAlimentos(lista)}.',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borde, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Para preparar el desayuno necesita${conOrden ? ', en este orden' : ''}:',
                style: AppTheme.titulo(24, height: 1.25),
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < lista.length; i++) _Renglon(alimento: lista[i], numero: conOrden ? i + 1 : null),
            ],
          ),
        ),
      );
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.alimento, this.numero});

  final Alimento alimento;
  final int? numero;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.naranjaSuave,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (numero != null) ...[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Dominio.memoria.color, shape: BoxShape.circle),
                child: Text('$numero', style: AppTheme.titulo(19, color: Colors.white)),
              ),
              const SizedBox(width: 14),
            ],
            EmojiAlimento(alimento, tamano: 44),
            const SizedBox(width: 16),
            Expanded(child: Text(alimento.nombre, style: AppTheme.titulo(28, color: AppColors.naranjaTexto))),
          ],
        ),
      );
}
