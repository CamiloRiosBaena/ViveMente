import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/cabecera_marca.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';

/// Minutos aproximados de la valoración completa.
const _minutosAprox = 30;

/// 01 · Bienvenida: dos puertas, hacer la prueba o entrar al panel del administrador.
class BienvenidaView extends StatelessWidget {
  const BienvenidaView({super.key});

  @override
  Widget build(BuildContext context) {
    final total = Dominio.values.fold<int>(0, (s, d) => s + d.cantidadActividades);

    final e = Bp.escala(context);
    final a = Bp.escalaAlto(context);

    return PantallaFlujo(
      cabecera: CabeceraMarca(
        altoMinimo: Bp.altoCabeceraMarca(context),
        abajo: 28,
        child: Row(
          children: [
            LogoFicha(tamano: 96 * e),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ViveMente',
                      style: AppTheme.titulo(42 * e, color: Colors.white, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Valoración de memoria',
                    style: AppTheme.cuerpo(20 * e, color: Colors.white.withValues(alpha: 0.85), height: 1.25),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      paddingSuperior: Bp.esPantallaBaja(context) ? 14 : 22,
      // Si sobra alto (tablet), el bloque se centra entre la cabecera y el
      // botón en vez de dejar un hueco suelto abajo.
      cuerpo: CuerpoElastico(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(header: true, child: Text('Empecemos la valoración', style: AppTheme.titulo(32 * a, height: 1.15))),
            SizedBox(height: 12 * a),
            Text(
              'Son actividades cortas y se hacen de una sola vez. '
              'Busca un lugar tranquilo y con buena luz.',
              style: AppTheme.cuerpo(20 * a, height: 1.4),
            ),
            SizedBox(height: 16 * a),
            // Las dos cifras ocupan todo el ancho. En pantallas normales van en
            // una tarjeta que llena el espacio con información y no con aire;
            // en celulares bajos se quedan en una línea suelta para que todo
            // quepa sin desplazar.
            _Cifras(total: total, escala: a, enTarjeta: !Bp.esPantallaBaja(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
      pie: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BotonGrande(texto: 'Realizar prueba', onPressed: () => context.push('/evaluador')),
          const SizedBox(height: 16),
          const _SeparadorO(),
          const SizedBox(height: 16),
          _TarjetaLogin(onTap: () => context.push('/login')),
        ],
      ),
    );
  }
}

/// Las cifras de la valoración: minutos y número de actividades.
class _Cifras extends StatelessWidget {
  const _Cifras({required this.total, required this.escala, required this.enTarjeta});

  final int total;
  final double escala;
  final bool enTarjeta;

  @override
  Widget build(BuildContext context) {
    final fila = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _Dato(valor: '$_minutosAprox', etiqueta: 'minutos aprox.', escala: escala)),
          const SizedBox(width: 18),
          Expanded(child: _Dato(valor: '$total', etiqueta: 'actividades', escala: escala)),
        ],
      ),
    );

    if (!enTarjeta) return SizedBox(width: double.infinity, child: fila);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.crema,
        borderRadius: BorderRadius.circular(20),
      ),
      child: fila,
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.etiqueta, this.escala = 1});

  final String valor;
  final String etiqueta;
  final double escala;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 14),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.naranja, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor, style: AppTheme.titulo(40 * escala, color: AppColors.naranjaTexto, height: 1.1)),
            Text(etiqueta, style: AppTheme.cuerpo(18 * escala, color: AppColors.textoSuave)),
          ],
        ),
      );
}

class _SeparadorO extends StatelessWidget {
  const _SeparadorO();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.borde, thickness: 2)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('O BIEN', style: AppTheme.mono(13, letterSpacing: 1)),
          ),
          const Expanded(child: Divider(color: AppColors.borde, thickness: 2)),
        ],
      );
}

class _TarjetaLogin extends StatelessWidget {
  const _TarjetaLogin({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borde = BorderRadius.circular(18);

    return Semantics(
      button: true,
      label: 'Iniciar sesión. Panel de estadísticas del administrador',
      excludeSemantics: true,
      child: Material(
        color: AppColors.azulSuave,
        shape: RoundedRectangleBorder(
          borderRadius: borde,
          side: const BorderSide(color: AppColors.azulBorde, width: 2),
        ),
        child: InkWell(
          borderRadius: borde,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: AppColors.azul, borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.insights_outlined, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Iniciar sesión', style: AppTheme.titulo(22, color: AppColors.azulProfundo)),
                      Text(
                        'Panel del administrador',
                        style: AppTheme.cuerpo(17, color: AppColors.textoSuave),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 30, color: AppColors.azulProfundo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
