import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/atencion/tren_senales/providers/tren_senales_provider.dart';
import 'package:vivamente/features/atencion/tren_senales/tren_senales_game.dart';
import 'package:vivamente/features/juegos/widgets/cabecera_juego.dart';

/// Cierre de la ronda medida con las cifras que quedaron registradas.
class TrenResultadoView extends ConsumerWidget {
  const TrenResultadoView({super.key, required this.onContinuar});

  final VoidCallback onContinuar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = ref.watch(trenSenalesProvider.select((s) => s.metricas));
    final plural = ref.watch(trenSenalesProvider.select((s) => s.objetivo)).plural;
    final nivel = ref.watch(trenSenalesProvider.select((s) => s.nivel.dificultad.nivel));
    final segundos = (m.latenciaPromedio / 1000).toStringAsFixed(1).replaceAll('.', ',');

    return PantallaFlujo(
      cabecera: const CabeceraJuego(juegoId: TrenSenalesGame.idJuego),
      cuerpo: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text('¡Nivel $nivel terminado!', style: AppTheme.titulo(32, height: 1.15))),
            const SizedBox(height: 10),
            Text('Gracias. Estos son los resultados.', style: AppTheme.cuerpo(20, height: 1.4)),
            const SizedBox(height: 22),
            _Cifra(etiqueta: 'Trenes $plural a tiempo', valor: '${m.aciertos} de ${m.objetivos}', destacada: true),
            _Cifra(etiqueta: 'Trenes $plural sin señal', valor: '${m.omisiones}'),
            _Cifra(etiqueta: 'Señales con otro tren', valor: '${m.comisiones}'),
            _Cifra(etiqueta: 'Tiempo de respuesta', valor: m.latencias.isEmpty ? '—' : '$segundos s'),
            const SizedBox(height: 16),
          ],
        ),
      ),
      pie: BotonGrande(texto: 'Continuar', onPressed: onContinuar),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.etiqueta, required this.valor, this.destacada = false});

  final String etiqueta;
  final String valor;
  final bool destacada;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: destacada ? AppColors.verdeSuave : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: destacada ? AppColors.verde : AppColors.borde, width: 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(etiqueta, style: AppTheme.cuerpo(19, color: AppColors.texto))),
            Text(valor, style: AppTheme.titulo(24, color: destacada ? AppColors.verdeTexto : AppColors.texto)),
          ],
        ),
      );
}
