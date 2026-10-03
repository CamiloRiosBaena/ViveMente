import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/cabecera_marca.dart';
import 'package:vivamente/core/widgets/fondo_glass.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
import 'package:vivamente/features/session/widgets/barra_navegacion_inicio.dart';
import 'package:vivamente/features/session/widgets/inicio_encabezado.dart';
import 'package:vivamente/features/session/widgets/tarjeta_dominio.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

class InicioView extends ConsumerWidget {
  const InicioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GuardaSesion(
      permite: (s) => s.lista,
      destino: '/',
      child: const _Inicio(),
    );
  }
}

class _Inicio extends ConsumerStatefulWidget {
  const _Inicio();

  @override
  ConsumerState<_Inicio> createState() => _InicioState();
}

class _InicioState extends ConsumerState<_Inicio> {
  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  void _aviso(String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));

  @override
  Widget build(BuildContext context) {
    final adulto = ref.watch(sesionProvider).adulto!;
    final progreso = ref.watch(progresoProvider);

    final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);
    final juegos = ref.watch(juegosProvider);
    final nivelesHechos = juegos.fold<int>(
      0,
      (s, juego) => s + ref.watch(nivelesHechosProvider(juego.id)).length,
    );
    final totalNiveles = total * Dificultad.values.length;

    final m = Bp.margenFlujo(context);
    final dominios = Dominio.values.toList();

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: FondoPremium()),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabeceraMarca(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SaludoInicio(saludo: _saludo, adulto: adulto),
                    const SizedBox(height: 20),
                    TarjetaProgreso(nivelesHechos: nivelesHechos, totalNiveles: totalNiveles),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(m, 28, m, BarraNavegacionInicio.alto),
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        '¿Qué deseas ejercitar hoy?',
                        style: AppTheme.titulo(24),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (dominios.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No hay dominios disponibles.',
                            style: AppTheme.cuerpo(16),
                          ),
                        ),
                      )
                    else
                      for (final d in dominios) ...[
                        TarjetaDominio(
                          dominio: d,
                          hechas: progreso[d] ?? 0,
                          onTap: ref.watch(juegosDeDominioProvider(d)).isEmpty
                              ? () => _aviso(
                                    'Las actividades de ${d.etiqueta} aún no están disponibles.',
                                  )
                              : () => context.push('/dominio/${d.name}'),
                        ),
                        const SizedBox(height: 16),
                      ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const BarraNavegacionInicio(actual: SeccionInicio.inicio),
          ),
        ],
      ),
    );
  }
}
