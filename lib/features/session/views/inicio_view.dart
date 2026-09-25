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
import 'package:vivamente/core/widgets/tarjeta_elegible.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';
import 'package:vivamente/features/session/widgets/guarda_sesion.dart';

/// 04 · Inicio: avance de la valoración y los cuatro dominios.
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

class _Inicio extends ConsumerWidget {
  const _Inicio();

  String get _saludo {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  void _aviso(BuildContext context, String texto) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));

  Future<void> _ajustes(BuildContext context, WidgetRef ref) async {
    final salir = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text('Cerrar sesión', style: AppTheme.cuerpo(19, color: AppColors.texto)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          onTap: () => Navigator.of(context).pop(true),
        ),
      ),
    );
    if (salir != true || !context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ref.read(sesionProvider.notifier).cerrar();
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adulto = ref.watch(sesionProvider).adulto!;
    final progreso = ref.watch(progresoProvider);
    final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);
    final hechas = progreso.values.fold<int>(0, (s, n) => s + n);
    final m = Bp.margenFlujo(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CabeceraMarca(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Saludo(saludo: _saludo, adulto: adulto),
                const SizedBox(height: 16),
                _TarjetaProgreso(hechas: hechas, total: total),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(m, 22, m, 16),
              children: [
                Semantics(
                  header: true,
                  child: Text('¿Qué deseas ejercitar hoy?', style: AppTheme.titulo(24)),
                ),
                const SizedBox(height: 14),
                for (final d in Dominio.values) ...[
                  _TarjetaDominio(
                    dominio: d,
                    hechas: progreso[d] ?? 0,
                    onTap: () => _aviso(context, 'Las actividades de ${d.etiqueta} aún no están disponibles.'),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BarraInferior(
        onProgreso: () => _aviso(context, 'El progreso estará disponible pronto.'),
        onAjustes: () => _ajustes(context, ref),
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
                Text(saludo, style: AppTheme.cuerpo(19, color: Colors.white.withValues(alpha: 0.85))),
                Semantics(
                  header: true,
                  child: Text(adulto.primerNombre, style: AppTheme.titulo(32, color: Colors.white, height: 1.15)),
                ),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Text(adulto.iniciales, style: AppTheme.titulo(18, color: Colors.white)),
          ),
        ],
      );
}

class _TarjetaProgreso extends StatelessWidget {
  const _TarjetaProgreso({required this.hechas, required this.total});

  final int hechas;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valoración completa · $total actividades',
              style: AppTheme.cuerpo(16, color: Colors.white.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Barra(valor: hechas / total, color: AppColors.ambar, fondo: Colors.white24)),
                const SizedBox(width: 14),
                Text('$hechas de $total', style: AppTheme.titulo(17, color: Colors.white)),
              ],
            ),
          ],
        ),
      );
}

class _Barra extends StatelessWidget {
  const _Barra({required this.valor, required this.color, required this.fondo, this.alto = 8});

  final double valor;
  final Color color;
  final Color fondo;
  final double alto;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(value: valor, minHeight: alto, color: color, backgroundColor: fondo),
      );
}

class _TarjetaDominio extends StatelessWidget {
  const _TarjetaDominio({required this.dominio, required this.hechas, required this.onTap});

  final Dominio dominio;
  final int hechas;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = dominio.cantidadActividades;
    final detalle = '$n actividades · $hechas ${hechas == 1 ? 'hecha' : 'hechas'}';

    return TarjetaElegible(
      onTap: onTap,
      radio: 18,
      padding: const EdgeInsets.all(16),
      etiquetaSemantica: '${dominio.etiqueta}, $detalle',
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: dominio.color, borderRadius: BorderRadius.circular(15)),
            child: Icon(dominio.icono, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dominio.etiqueta, style: AppTheme.titulo(22, height: 1.15)),
                const SizedBox(height: 2),
                Text(detalle, style: AppTheme.cuerpo(17)),
                const SizedBox(height: 10),
                _Barra(valor: hechas / n, color: AppColors.naranja, fondo: AppColors.borde, alto: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraInferior extends StatelessWidget {
  const _BarraInferior({required this.onProgreso, required this.onAjustes});

  final VoidCallback onProgreso;
  final VoidCallback onAjustes;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borde, width: 2)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Bp.anchoFlujo),
              child: Row(
                children: [
                  const Expanded(child: _ItemBarra(icono: Icons.home_rounded, etiqueta: 'Inicio', activo: true)),
                  Expanded(child: _ItemBarra(icono: Icons.insights_outlined, etiqueta: 'Progreso', onTap: onProgreso)),
                  Expanded(child: _ItemBarra(icono: Icons.settings_outlined, etiqueta: 'Ajustes', onTap: onAjustes)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _ItemBarra extends StatelessWidget {
  const _ItemBarra({required this.icono, required this.etiqueta, this.activo = false, this.onTap});

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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 30,
                  decoration: BoxDecoration(
                    color: activo ? AppColors.naranja : AppColors.crema,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icono, size: 22, color: activo ? Colors.white : AppColors.textoSuave),
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
