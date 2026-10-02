import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/cabecera_flujo.dart';
import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';

import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

/// Actividades de un dominio, con la siguiente por hacer resaltada. Una
/// actividad queda hecha solo cuando se completan sus tres niveles.
class DominioView extends ConsumerWidget {
  const DominioView({super.key, required this.dominio});

  final Dominio dominio;

  Future<void> _reiniciar(BuildContext context, WidgetRef ref, int niveles) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.papel,
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.rojo, size: 40),
        title: Text('¿Reiniciar las actividades?', style: AppTheme.titulo(24)),
        content: Text(
          'Se borrarán los resultados de ${niveles == 1 ? '1 nivel completado' : '$niveles niveles completados'} '
          'en ${dominio.etiqueta} y todas las actividades volverán a empezar desde el nivel 1. '
          'Esta acción no se puede deshacer.',
          style: AppTheme.cuerpo(19, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: AppTheme.titulo(19, color: AppColors.textoSuave)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rojo,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Sí, reiniciar', style: AppTheme.titulo(19, color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    ref.read(resultadosProvider.notifier).reiniciarDominio(dominio);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Se reiniciaron las actividades de ${dominio.etiqueta}.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final juegos = ref.watch(juegosDeDominioProvider(dominio));
    final siguiente = ref.watch(siguienteJuegoProvider(dominio));
    final nivelesHechos = ref.watch(nivelesHechosDominioProvider(dominio));
    void volver() => volverOIr(context, '/inicio');

    return GuardaSesion(
      permite: (s) => s.lista,
      destino: '/',
      child: PantallaFlujo(
        cabecera: CabeceraFlujo(
          titulo: dominio.etiqueta,
          color: dominio.color,
          onAtras: volver,
          abajo: Text(
            '${dominio.descripcion} ${dominio.cantidadActividades} actividades cortas, '
            'cada una con ${Dificultad.values.length} niveles.',
            style: AppTheme.cuerpo(18, color: Colors.white.withValues(alpha: 0.85), height: 1.4),
          ),
        ),
        cuerpo: ListView.separated(
          itemCount: juegos.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _TarjetaActividad(
            numero: i + 1,
            juego: juegos[i],
            esSiguiente: juegos[i].id == siguiente?.id,
            onTap: () => context.push('/juego/${juegos[i].id}'),
          ),
        ),
        pie: Column(
          children: [
            if (siguiente == null)
              BotonGrande(texto: 'Volver al inicio', onPressed: volver)
            else
              BotonGrande(
                texto: 'Empezar actividad ${juegos.indexOf(siguiente) + 1}',
                onPressed: () => context.push('/juego/${siguiente.id}'),
              ),
            if (nivelesHechos > 0) ...[
              const SizedBox(height: 12),
              BotonSecundario(
                texto: 'Reiniciar actividades',
                icono: Icons.restart_alt_rounded,
                onPressed: () => _reiniciar(context, ref, nivelesHechos),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaActividad extends ConsumerStatefulWidget {
  const _TarjetaActividad({
    required this.numero,
    required this.juego,
    required this.esSiguiente,
    required this.onTap,
  });

  final int numero;
  final Game juego;
  final bool esSiguiente;
  final VoidCallback onTap;

  @override
  ConsumerState<_TarjetaActividad> createState() => _TarjetaActividadState();
}

class _TarjetaActividadState extends ConsumerState<_TarjetaActividad> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final juego = widget.juego;
    final numero = widget.numero;
    final esSiguiente = widget.esSiguiente;

    final hechos = ref.watch(nivelesHechosProvider(juego.id));
    final completa = ref.watch(juegoCompletoProvider(juego.id));
    final total = Dificultad.values.length;
    final minutos = (juego.duracionEstimada.inSeconds / 60).ceil();

    final (estado, colorBase) = completa
        ? ('Completa', AppColors.verdeTexto)
        : esSiguiente
            ? ('Siguiente', AppColors.textoSuave)
            : ('Pendiente', AppColors.textoSuave);

    // Todas las tarjetas pendientes (incluida la "siguiente") parten neutras
    // y pasan a naranja solo con el mouse encima. La completa se queda en verde.
    final colorEstado = completa
        ? colorBase
        : _hover
            ? AppColors.naranja
            : colorBase;
    final colorContenedor = completa
        ? AppColors.verde
        : _hover
            ? AppColors.naranja
            : AppColors.crema;
    final resaltada = _hover && !completa;

    final detalle = completa
        ? '$estado · $total de $total niveles'
        : '$estado · Nivel ${juego.dificultad.nivel} · $minutos min';

    return Semantics(
      button: true,
      selected: esSiguiente,
      label: 'Actividad $numero, ${juego.titulo}, $detalle, '
          '${hechos.length} de $total niveles hechos',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (v) => setState(() => _hover = v),
          borderRadius: BorderRadius.circular(18),
          child: Glass(
            radio: 18,
            opacidad: 0.6,
            tinte: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorContenedor,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: completa
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
                      : Text(
                          '$numero',
                          style: AppTheme.titulo(22, color: resaltada ? Colors.white : AppColors.textoSuave),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(juego.titulo, style: AppTheme.titulo(22, height: 1.15)),
                      const SizedBox(height: 2),
                      Text(detalle, style: AppTheme.cuerpo(17, color: colorEstado, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      _Niveles(hechos: hechos),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tres fichas «N1 N2 N3»: verdes las hechas.
class _Niveles extends StatelessWidget {
  const _Niveles({required this.hechos});

  final Set<Dificultad> hechos;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          for (final d in Dificultad.values) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: hechos.contains(d) ? AppColors.verdeSuave : AppColors.crema,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: hechos.contains(d) ? AppColors.verde : AppColors.borde),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hechos.contains(d)) ...[
                    const Icon(Icons.check_rounded, size: 15, color: AppColors.verdeTexto),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    'N${d.nivel}',
                    style: AppTheme.cuerpo(
                      15,
                      color: hechos.contains(d) ? AppColors.verdeTexto : AppColors.textoSuave,
                      weight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ],
      );
}
