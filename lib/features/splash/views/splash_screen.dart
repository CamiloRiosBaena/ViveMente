import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Presentación de la marca. Corre sola y al terminar pasa a la bienvenida;
/// no hace falta tocar nada.
///
/// Solo se animan opacidad y transformaciones (escala, desplazamiento), que el
/// motor compone sin volver a pintar, para que se vea fluida también en web.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const _titulo = 'ViveMente';
  static const _tamanoLogo = 140.0;

  /// Entrada de la marca: logo, ondas, título letra a letra, subtítulo y pie.
  late final AnimationController _entrada = AnimationController(
    duration: const Duration(milliseconds: 2600),
    vsync: this,
  );

  /// Salida: todo se desvanece y sube un poco antes de cambiar de pantalla.
  late final AnimationController _salida = AnimationController(
    duration: const Duration(milliseconds: 450),
    vsync: this,
  );

  bool _iniciada = false;

  Animation<double> _tramo(double inicio, double fin, [Curve curva = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _entrada, curve: Interval(inicio, fin, curve: curva));

  // Logo: aparece con un pequeño rebote.
  late final _logoOpacidad = _tramo(0.0, 0.2);
  late final _logoEscala = Tween<double>(begin: 0.4, end: 1).animate(_tramo(0.0, 0.35, Curves.easeOutBack));

  // Dos ondas que salen del logo, una detrás de la otra.
  late final _onda1 = _tramo(0.12, 0.62, Curves.easeOut);
  late final _onda2 = _tramo(0.24, 0.74, Curves.easeOut);

  // Cada letra del título entra un poco después de la anterior.
  late final _letras = [
    for (var i = 0; i < _titulo.length; i++)
      (
        opacidad: _tramo(0.3 + i * 0.035, 0.42 + i * 0.035),
        posicion: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
            .animate(_tramo(0.3 + i * 0.035, 0.5 + i * 0.035, Curves.easeOutBack)),
      ),
  ];

  // Subtítulo, logo institucional y barra de avance.
  late final _subtitulo = _tramo(0.55, 0.8);
  late final _pie = _tramo(0.65, 0.9);

  late final _salidaOpacidad = ReverseAnimation(CurvedAnimation(parent: _salida, curve: Curves.easeIn));
  late final _salidaPosicion = Tween(begin: Offset.zero, end: const Offset(0, -0.04))
      .animate(CurvedAnimation(parent: _salida, curve: Curves.easeIn));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciada) return;
    _iniciada = true;
    _arrancar();
  }

  Future<void> _arrancar() async {
    // Se decodifican las imágenes antes de animar para que no aparezcan a
    // medio camino ni frenen los primeros cuadros.
    await Future.wait([
      precacheImage(const AssetImage('assets/logo.png'), context),
      precacheImage(const AssetImage('assets/Logo_unad_color.png'), context),
    ]);
    if (!mounted) return;

    if (MediaQuery.disableAnimationsOf(context)) {
      // Con movimiento reducido la pantalla aparece completa y espera un poco.
      _entrada.value = 1;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    } else {
      await _entrada.forward();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      await _salida.forward();
    }
    if (mounted) context.go('/');
  }

  @override
  void dispose() {
    _entrada.dispose();
    _salida.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cafe,
      body: FadeTransition(
        opacity: _salidaOpacidad,
        child: SlideTransition(
          position: _salidaPosicion,
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _logoConOndas(),
                          const SizedBox(height: 30),
                          _tituloPorLetras(),
                          const SizedBox(height: 10),
                          FadeTransition(
                            opacity: _subtitulo,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(_subtitulo),
                              child: Text(
                                'Ejercicios de mente para vivir mejor',
                                textAlign: TextAlign.center,
                                style: AppTheme.cuerpo(18, color: Colors.white.withValues(alpha: 0.85))
                                    .copyWith(fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _pie,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(_pie),
                    child: _logoInstitucional(),
                  ),
                ),
                const SizedBox(height: 28),
                _barraAvance(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Logo con dos ondas de luz que se abren detrás de él. Las ondas crecen con
  /// una transformación, así que se pintan por fuera sin ocupar espacio.
  Widget _logoConOndas() {
    Widget onda(Animation<double> t) => FadeTransition(
          opacity: ReverseAnimation(t),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 1.85).animate(t),
            child: Container(
              width: _tamanoLogo,
              height: _tamanoLogo,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.ambar.withValues(alpha: 0.7), width: 2),
              ),
            ),
          ),
        );

    return SizedBox(
      width: _tamanoLogo,
      height: _tamanoLogo,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          onda(_onda1),
          onda(_onda2),
          FadeTransition(
            opacity: _logoOpacidad,
            child: ScaleTransition(
              scale: _logoEscala,
              child: RepaintBoundary(
                child: Container(
                  width: _tamanoLogo,
                  height: _tamanoLogo,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/logo.png', fit: BoxFit.cover, semanticLabel: 'Logo de ViveMente'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloPorLetras() => Semantics(
        header: true,
        label: _titulo,
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _titulo.length; i++)
              FadeTransition(
                opacity: _letras[i].opacidad,
                child: SlideTransition(
                  position: _letras[i].posicion,
                  child: Text(_titulo[i], style: AppTheme.titulo(40, color: Colors.white, height: 1.1)),
                ),
              ),
          ],
        ),
      );

  /// Crédito institucional: una leyenda corta entre dos líneas y el logo de la
  /// UNAD sobre una ficha blanca, que es donde sus colores se leen bien (el
  /// naranja de los puntos y de "Abierta y a Distancia" se perdía sobre café).
  Widget _logoInstitucional() {

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // El PNG trae margen vacío alrededor: se recorta para que el logo
          // llene la ficha en vez de verse pequeño dentro de ella.
          child: ClipRect(
            child: Align(
              widthFactor: 0.8,
              heightFactor: 0.82,
              child: Image.asset(
                'assets/Logo_unad_color.png',
                height: 84,
                semanticLabel: 'Universidad Nacional Abierta y a Distancia, UNAD',
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Línea fina que se llena mientras corre la presentación: indica que la app
  /// avanza sola.
  Widget _barraAvance() => ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          width: 120,
          height: 4,
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.18),
            child: AnimatedBuilder(
              animation: _entrada,
              builder: (_, child) => Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.diagonal3Values(_entrada.value, 1, 1),
                child: child,
              ),
              child: const SizedBox.expand(child: ColoredBox(color: AppColors.ambar)),
            ),
          ),
        ),
      );
}
