import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/localidad.dart';
import 'package:vivamente/core/theme/app_theme.dart';

/// Mapa de OpenStreetMap con el punto leído por GPS, su margen de error y, si
/// la localidad tiene coordenadas, el área habilitada. Necesita internet para
/// cargar el mapa; sin conexión solo se ven las marcas sobre fondo liso.
class MapaUbicacion extends StatelessWidget {
  const MapaUbicacion({super.key, required this.ubicacion, this.alto = 220});

  final Ubicacion ubicacion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(ubicacion.latitud, ubicacion.longitud);
    final l = ubicacion.localidad;
    final centroLocalidad =
        l.latitud == null || l.longitud == null ? null : LatLng(l.latitud!, l.longitud!);

    return Semantics(
      label: 'Mapa con la ubicación actual',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: alto,
          child: ColoredBox(
            color: AppColors.crema,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: punto,
                initialZoom: 17,
                minZoom: 5,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.vivamente',
                ),
                CircleLayer(circles: [
                  if (centroLocalidad != null)
                    CircleMarker(
                      point: centroLocalidad,
                      radius: l.radioMetros,
                      useRadiusInMeter: true,
                      color: AppColors.verde.withValues(alpha: 0.10),
                      borderColor: AppColors.verde,
                      borderStrokeWidth: 2,
                    ),
                  CircleMarker(
                    point: punto,
                    radius: ubicacion.precisionMetros,
                    useRadiusInMeter: true,
                    color: AppColors.azul.withValues(alpha: 0.15),
                    borderColor: AppColors.azul.withValues(alpha: 0.5),
                    borderStrokeWidth: 1,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: punto,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on_rounded, size: 44, color: AppColors.naranja),
                  ),
                ]),
                // Crédito que pide OpenStreetMap; propio porque el de
                // flutter_map no cabe en celulares angostos.
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.white.withValues(alpha: 0.8),
                    child: Text('© OpenStreetMap', style: AppTheme.cuerpo(12, color: AppColors.texto)),
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
