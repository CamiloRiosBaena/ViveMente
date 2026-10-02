import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/models/persona.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/theme/dominio_estilo.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/cabecera_marca.dart';
import 'package:vivamente/core/widgets/fondo_glass.dart';

import 'package:vivamente/core/widgets/glass.dart';
import 'package:vivamente/features/juegos/providers/juegos_provider.dart';
import 'package:vivamente/features/juegos/providers/resultados_provider.dart';
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
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text(
            'Cerrar sesión',
            style: AppTheme.cuerpo(19, color: AppColors.texto),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );

    if (salir != true || !mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    ref.read(sesionProvider.notifier).cerrar();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final adulto = ref.watch(sesionProvider).adulto!;
    final progreso = ref.watch(progresoProvider);

    final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);
    final hechas = progreso.values.fold<int>(0, (s, n) => s + n);

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
                    _Saludo(saludo: _saludo, adulto: adulto),
                    const SizedBox(height: 20),
                    _TarjetaProgreso(hechas: hechas, total: total),
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
                        _TarjetaDominio(
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
            child: _BarraInferior(
              onProgreso: () => _aviso('El progreso estará disponible pronto.'),
              onAjustes: _ajustes,
            ),
          ),
        ],
      ),
    );
  }
}

class _Saludo extends StatelessWidget {
  const _Saludo({required this.saludo, required this.adulto});

  final String saludo;
  final Adulto adulto;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  saludo,
                  style: AppTheme.cuerpo(
                    19,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  header: true,
                  child: Text(
                    adulto.primerNombre,
                    style: AppTheme.titulo(32, color: Colors.white, height: 1.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: Text(
              adulto.iniciales,
              style: AppTheme.titulo(19, color: Colors.white),
            ),
          ),
        ],
      );
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({required this.hechas, required this.total});

  final int hechas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final valor = total == 0 ? 0.0 : hechas / total;
    final porcentaje = (valor * 100).round();

    return Semantics(
      label: 'Tu avance en la valoración: $porcentaje por ciento completado',
      excludeSemantics: true,
      child: Glass(
        radio: 20,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        opacidad: 0.16,
        tinte: Colors.white,
        borde: Colors.white.withValues(alpha: 0.30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu avance en la valoración',
              style: AppTheme.cuerpo(
                16,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Barra(
                    valor: valor,
                    color: AppColors.ambar,
                    fondo: Colors.white24,
                    alto: 10,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '$porcentaje %',
                  style: AppTheme.titulo(20, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
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

class _TarjetaDominio extends StatelessWidget {
  const _TarjetaDominio({
    required this.dominio,
    required this.hechas,
    required this.onTap,
  });

  final Dominio dominio;
  final int hechas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = dominio.cantidadActividades;
    final detalle = '$n actividades · $hechas ${hechas == 1 ? 'hecha' : 'hechas'}';
    final oscuro = Color.lerp(dominio.color, Colors.black, 0.18)!;

    return Semantics(
      button: true,
      label: '${dominio.etiqueta}, $detalle',
      excludeSemantics: true,
      child: Glass(
        radio: 22,
        padding: EdgeInsets.zero,
        opacidad: 0.62,
        tinte: Colors.white,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: dominio.color.withValues(alpha: 0.10),
            highlightColor: dominio.color.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [dominio.color, oscuro],
                        ),
                      ),
                      child: Icon(dominio.icono, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dominio.etiqueta,
                          style: AppTheme.titulo(22, height: 1.15),
                        ),
                        const SizedBox(height: 2),
                        Text(detalle, style: AppTheme.cuerpo(17)),
                        const SizedBox(height: 12),
                        _Barra(
                          valor: n == 0 ? 0 : hechas / n,
                          color: AppColors.naranja,
                          fondo: AppColors.borde,
                          alto: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textoSuave,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.onProgreso, required this.onAjustes});

  final VoidCallback onProgreso;
  final VoidCallback onAjustes;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Bp.anchoFlujo - 40),
              child: Glass(
                radio: 30,
                padding: const EdgeInsets.symmetric(vertical: 6),
                opacidad: 0.72,
                tinte: Colors.white,
                blur: 22,
                child: Row(
                  children: [
                    const Expanded(
                      child: _ItemBarra(
                        icono: Icons.home_rounded,
                        etiqueta: 'Inicio',
                        activo: true,
                      ),
                    ),
                    Expanded(
                      child: _ItemBarra(
                        icono: Icons.insights_outlined,
                        etiqueta: 'Progreso',
                        onTap: onProgreso,
                      ),
                    ),
                    Expanded(
                      child: _ItemBarra(
                        icono: Icons.settings_outlined,
                        etiqueta: 'Ajustes',
                        onTap: onAjustes,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ItemBarra extends StatelessWidget {
  const _ItemBarra({
    required this.icono,
    required this.etiqueta,
    this.activo = false,
    this.onTap,
  });

  final IconData icono;
  final String etiqueta;
  final bool activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: activo,
        label: etiqueta,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 30,
                  decoration: BoxDecoration(
                    color: activo ? AppColors.naranja : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icono,
                    size: 22,
                    color: activo ? Colors.white : AppColors.textoSuave,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  etiqueta,
                  style: AppTheme.cuerpo(
                    14,
                    color: activo ? AppColors.texto : AppColors.textoSuave,
                    weight: activo ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
