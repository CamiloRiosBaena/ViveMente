import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/cabecera_marca.dart';
import 'package:vivamente/core/widgets/fondo_glass.dart';
import 'package:vivamente/core/widgets/glass.dart';
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

  Future<void> _ajustes() async {
    final salir = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Glass(
            radio: 24,
            padding: const EdgeInsets.symmetric(vertical: 6),
            opacidad: 0.82,
            blur: 22,
            tinte: AppColors.papel,
            borde: Colors.white.withValues(alpha: 0.72),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.naranjaSuave,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.naranjaTexto),
                ),
                title: Text(
                  'Cerrar sesión',
                  style: AppTheme.cuerpo(19, color: AppColors.texto, weight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textoSuave),
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                onTap: () => Navigator.of(sheetContext).pop(true),
              ),
            ),
          ),
        ),
      ),
    );

    if (salir != true || !mounted) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Glass(
          radio: 26,
          padding: const EdgeInsets.all(24),
          opacidad: 0.86,
          blur: 24,
          tinte: AppColors.papel,
          borde: Colors.white.withValues(alpha: 0.78),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.naranjaSuave,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.naranjaTexto),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '¿Seguro que quieres cerrar sesión?',
                style: AppTheme.titulo(24, height: 1.2),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final estiloCancelar = TextButton.styleFrom(
                    foregroundColor: AppColors.textoSuave,
                    backgroundColor: AppColors.crema,
                    shadowColor: AppColors.cafe.withValues(alpha: 0.18),
                    elevation: 2,
                    minimumSize: const Size.fromHeight(44),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  );
                  final cancelar = TextButton(
                    style: estiloCancelar,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text('Cancelar', style: AppTheme.cuerpo(17, color: AppColors.textoSuave)),
                  );
                  final cerrar = FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      textStyle: AppTheme.titulo(18, color: Colors.white),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar sesión'),
                  );

                  if (constraints.maxWidth < 360) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        cerrar,
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: cancelar,
                        ),
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [cancelar, const SizedBox(width: 8), cerrar],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ref.read(sesionProvider.notifier).cerrar();
    context.go('/');
  }

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
                  padding: EdgeInsets.fromLTRB(m, 28, m, 136),
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
            child: BarraNavegacionInicio(
              onProgreso: () => context.push('/progreso'),
              onAjustes: _ajustes,
            ),
          ),
        ],
      ),
    );
  }
}
