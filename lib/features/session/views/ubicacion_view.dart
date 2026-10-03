import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/localidad.dart';
import 'package:vivamente/core/services/localidades_repository.dart';
import 'package:vivamente/core/services/ubicacion.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/boton_secundario.dart';
import 'package:vivamente/core/widgets/mapa_ubicacion.dart';
import 'package:vivamente/core/widgets/pantalla_registro.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';

/// Paso 1 de 4 · ¿Dónde se aplica? Se toma la posición por GPS y se busca la
/// localidad habilitada que la cubre. Sin ubicación verificada no se sigue.
class UbicacionView extends ConsumerStatefulWidget {
  const UbicacionView({super.key});

  @override
  ConsumerState<UbicacionView> createState() => _UbicacionViewState();
}

class _UbicacionViewState extends ConsumerState<UbicacionView> {
  bool _buscando = false;
  FalloUbicacion? _fallo;

  /// Hay posición pero ninguna localidad habilitada la cubre.
  bool _fueraDeZona = false;

  Ubicacion? _ubicacion;

  Future<void> _ubicar() async {
    if (_buscando) return;
    setState(() {
      _buscando = true;
      _fallo = null;
      _fueraDeZona = false;
      _ubicacion = null;
    });

    try {
      final p = await ref.read(lectorUbicacionProvider).leer();
      final localidad = await ref.read(localidadesProvider).localidadEn(p.latitud, p.longitud);
      if (!mounted) return;
      setState(() {
        if (localidad == null) {
          _fueraDeZona = true;
        } else {
          _ubicacion = Ubicacion(
            latitud: p.latitud,
            longitud: p.longitud,
            precisionMetros: p.precisionMetros,
            fecha: DateTime.now(),
            localidad: localidad,
          );
        }
      });
    } on UbicacionException catch (e) {
      if (mounted) setState(() => _fallo = e.fallo);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  void _continuar() {
    ref.read(sesionProvider.notifier).fijarUbicacion(_ubicacion!);
    context.push('/evaluador');
  }

  Future<void> _ajustes() async {
    final abrio = await ref.read(lectorUbicacionProvider).abrirAjustes(_fallo!);
    if (abrio || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Active la ubicación desde la configuración del navegador o del equipo.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final u = _ubicacion;

    final Widget cuerpo;
    if (_buscando) {
      cuerpo = const _Aviso(
        icono: Icons.satellite_alt_outlined,
        titulo: 'Buscando señal…',
        texto: 'Puede tardar unos segundos. Si está en un lugar cerrado, acérquese a una ventana.',
        cargando: true,
      );
    } else if (u != null) {
      cuerpo = _Verificada(ubicacion: u);
    } else if (_fueraDeZona) {
      cuerpo = const _Aviso(
        icono: Icons.wrong_location_outlined,
        titulo: 'Fuera de una localidad habilitada',
        texto: 'La valoración solo se puede aplicar en los lugares habilitados por el administrador.',
        error: true,
      );
    } else if (_fallo != null) {
      cuerpo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Aviso(icono: Icons.location_off_outlined, titulo: 'No se pudo ubicar', texto: _mensaje(_fallo!), error: true),
          if (_fallo != FalloUbicacion.sinSenal && !kIsWeb) ...[
            const SizedBox(height: 16),
            BotonSecundario(texto: 'Abrir ajustes', icono: Icons.settings_outlined, onPressed: _ajustes),
          ],
        ],
      );
    } else {
      cuerpo = const _Aviso(
        icono: Icons.my_location_rounded,
        titulo: 'Permita el acceso a la ubicación',
        texto: 'Al tocar el botón, el equipo pedirá permiso para usar el GPS.',
      );
    }

    return PantallaRegistro(
      paso: 1,
      icono: Icons.location_on_outlined,
      titulo: '¿Dónde se aplica\nla valoración?',
      subtitulo: 'Se verifica la ubicación por GPS para registrar el lugar de cada sesión.',
      cuerpo: cuerpo,
      boton: u != null
          ? BotonGrande(texto: 'Continuar', onPressed: _continuar)
          : BotonGrande(
              texto: _fallo != null || _fueraDeZona ? 'Intentar de nuevo' : 'Verificar ubicación',
              cargando: _buscando,
              onPressed: _ubicar,
            ),
    );
  }

  String _mensaje(FalloUbicacion f) => switch (f) {
        FalloUbicacion.servicioApagado => 'El GPS del equipo está apagado. Enciéndalo e intente de nuevo.',
        FalloUbicacion.permisoNegado => 'No se dio permiso para usar la ubicación. Es necesario para continuar.',
        FalloUbicacion.permisoBloqueado => 'El permiso de ubicación está bloqueado. Actívelo en los ajustes del equipo.',
        FalloUbicacion.sinSenal => kIsWeb
            ? 'No se obtuvo la posición. Revise que el navegador tenga permiso de ubicación.'
            : 'No se obtuvo señal a tiempo. Intente de nuevo cerca de una ventana o al aire libre.',
      };
}

/// Tarjeta de estado: ícono, título y explicación.
class _Aviso extends StatelessWidget {
  const _Aviso({
    required this.icono,
    required this.titulo,
    required this.texto,
    this.cargando = false,
    this.error = false,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final bool cargando;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error ? AppColors.rojo : AppColors.naranjaTexto;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: error ? AppColors.rojo.withValues(alpha: 0.06) : AppColors.crema,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: error ? AppColors.rojo.withValues(alpha: 0.35) : AppColors.borde, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: cargando
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.naranja),
                    )
                  : Icon(icono, size: 36, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: AppTheme.titulo(21, color: error ? AppColors.rojo : AppColors.texto, height: 1.2)),
                  const SizedBox(height: 6),
                  Text(texto, style: AppTheme.cuerpo(18, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ubicación encontrada: la localidad y las coordenadas que quedan registradas.
class _Verificada extends StatelessWidget {
  const _Verificada({required this.ubicacion});

  final Ubicacion ubicacion;

  @override
  Widget build(BuildContext context) {
    final l = ubicacion.localidad;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.verdeSuave,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.verde.withValues(alpha: 0.4), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 30, color: AppColors.verde),
                const SizedBox(width: 10),
                Flexible(
                  child: Text('Ubicación verificada', style: AppTheme.titulo(19, color: AppColors.verdeTexto)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l.nombre, style: AppTheme.titulo(24, height: 1.2)),
            const SizedBox(height: 2),
            Text(l.zona, style: AppTheme.cuerpo(18, color: AppColors.textoSuave)),
            const SizedBox(height: 12),
            Text(
              '${ubicacion.latitud.toStringAsFixed(5)}, ${ubicacion.longitud.toStringAsFixed(5)}'
              ' · ±${ubicacion.precisionMetros.round()} m',
              style: AppTheme.mono(14),
            ),
            const SizedBox(height: 14),
            MapaUbicacion(ubicacion: ubicacion),
            const SizedBox(height: 8),
            Text(
              'Revise en el mapa que el punto coincide con el lugar donde está.',
              style: AppTheme.cuerpo(16, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
