import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/widgets/cabecera_flujo.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/session/widgets/barra_progreso.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

class ProgresoView extends StatelessWidget {
  const ProgresoView({super.key});

  @override
  Widget build(BuildContext context) => GuardaSesion(
    permite: (s) => s.lista,
    destino: '/',
    child: const _ContenidoProgreso(),
  );
}

class _ContenidoProgreso extends ConsumerWidget {
  const _ContenidoProgreso();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juegos = ref.watch(juegosProvider);
    final completadas = juegos
        .where((j) => ref.watch(juegoCompletoProvider(j.id)))
        .length;
    final valor = juegos.isEmpty ? 0.0 : completadas / juegos.length;

    return PantallaFlujo(
      cabecera: CabeceraFlujo(
        titulo: 'Progreso',
        eyebrow: 'VALORACIÓN',
        onAtras: () => context.canPop() ? context.pop() : context.go('/inicio'),
        abajo: Text(
          'Actividades completadas y nivel actual',
          style: AppTheme.cuerpo(
            18,
            color: Colors.white.withValues(alpha: 0.84),
          ),
        ),
      ),
      cuerpo: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _ResumenProgreso(
            completadas: completadas,
            total: juegos.length,
            valor: valor,
          ),
          const SizedBox(height: 24),
          for (final dominio in Dominio.values) ...[
            _SeccionProgreso(dominio: dominio),
            const SizedBox(height: 26),
          ],
        ],
      ),
    );
  }
}

class _ResumenProgreso extends StatelessWidget {
  const _ResumenProgreso({
    required this.completadas,
    required this.total,
    required this.valor,
  });

  final int completadas;
  final int total;
  final double valor;

  @override
  Widget build(BuildContext context) => Glass(
    radio: 24,
    padding: const EdgeInsets.all(20),
    opacidad: 0.94,
    tinte: AppColors.cafe,
    borde: Colors.white.withValues(alpha: 0.24),
    child: Row(
      children: [
        SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: valor.clamp(0, 1),
                  color: AppColors.ambar,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  strokeWidth: 7,
                ),
              ),
              Text(
                '${(valor * 100).round()}%',
                style: AppTheme.titulo(19, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AVANCE GENERAL',
                style: AppTheme.mono(
                  12,
                  color: Colors.white.withValues(alpha: 0.72),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completadas de $total',
                style: AppTheme.titulo(25, color: Colors.white, height: 1.1),
              ),
              const SizedBox(height: 3),
              Text(
                'actividades completadas',
                style: AppTheme.cuerpo(
                  15,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SeccionProgreso extends ConsumerWidget {
  const _SeccionProgreso({required this.dominio});

  final Dominio dominio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juegos = ref.watch(juegosDeDominioProvider(dominio));
    final completadas = juegos
        .where((j) => ref.watch(juegoCompletoProvider(j.id)))
        .length;
    final valor = juegos.isEmpty ? 0.0 : completadas / juegos.length;
    final porcentaje = (valor * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: dominio.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dominio.color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(dominio.icono, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dominio.etiqueta,
                      style: AppTheme.titulo(20, height: 1.15),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${juegos.length} actividades · $porcentaje% completado',
                      style: AppTheme.cuerpo(14, color: AppColors.textoSuave),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$completadas/${juegos.length}',
                style: AppTheme.titulo(16, color: dominio.color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BarraProgreso(
          valor: valor,
          color: dominio.color,
          fondo: AppColors.borde,
          alto: 6,
        ),
        const SizedBox(height: 12),
        if (juegos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin actividades disponibles',
              style: AppTheme.cuerpo(16),
            ),
          )
        else
          for (final juego in juegos) ...[
            _ActividadProgreso(juego: juego),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _ActividadProgreso extends ConsumerWidget {
  const _ActividadProgreso({required this.juego});

  final Game juego;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nivelesHechos = ref.watch(nivelesHechosProvider(juego.id));
    final completa = ref.watch(juegoCompletoProvider(juego.id));
    final enCurso = nivelesHechos.isNotEmpty && !completa;
    final colorEstado = completa
        ? AppColors.verdeTexto
        : enCurso
        ? AppColors.naranjaTexto
        : AppColors.textoSuave;
    final tinte = completa
        ? AppColors.verdeSuave
        : enCurso
        ? AppColors.naranjaSuave
        : Colors.white;
    final estado = completa
        ? 'Completada'
        : nivelesHechos.isEmpty
        ? 'Sin iniciar · Nivel ${juego.dificultad.nivel} seleccionado'
        : 'Siguiente · Nivel ${juego.dificultad.nivel} ${juego.dificultad.etiqueta}';

    return Glass(
      radio: 18,
      padding: const EdgeInsets.all(14),
      opacidad: 0.84,
      tinte: tinte,
      borde: colorEstado.withValues(alpha: 0.20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: juego.dominio.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(juego.icono, color: juego.dominio.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(juego.titulo, style: AppTheme.titulo(18, height: 1.2)),
                    const SizedBox(height: 2),
                    Text(
                      estado,
                      style: AppTheme.cuerpo(
                        15,
                        color: colorEstado,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final dificultad in Dificultad.values)
                _NivelIndicador(
                  dificultad: dificultad,
                  completado: nivelesHechos.contains(dificultad),
                  actual: !completa && juego.dificultad == dificultad,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NivelIndicador extends StatelessWidget {
  const _NivelIndicador({
    required this.dificultad,
    required this.completado,
    required this.actual,
  });

  final Dificultad dificultad;
  final bool completado;
  final bool actual;

  @override
  Widget build(BuildContext context) {
    final color = completado
        ? AppColors.verdeTexto
        : actual
        ? AppColors.naranjaTexto
        : AppColors.textoSuave;
    final fondo = completado
        ? AppColors.verdeSuave
        : actual
        ? AppColors.naranjaSuave
        : Colors.white.withValues(alpha: 0.58);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (completado) ...[
            Icon(Icons.check_rounded, size: 15, color: color),
            const SizedBox(width: 4),
          ] else if (actual) ...[
            Icon(Icons.play_arrow_rounded, size: 15, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            'N${dificultad.nivel} · ${dificultad.etiqueta}',
            style: AppTheme.cuerpo(14, color: color, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
