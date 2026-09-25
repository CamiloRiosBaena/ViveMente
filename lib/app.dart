import 'package:flutter/material.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/utils/breakpoints.dart';
import 'package:vivamente/routes/app_routes.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppTheme.light, 
      routerConfig: appRouter, 
      title: 'ViveMente',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // En tablet y escritorio el texto sube un poco: es la misma vista, pero
        // se lee desde más lejos. Se respeta el ajuste del sistema y se acota
        // para que ninguna pantalla se desarme.
        final factor = mq.textScaler.scale(1) * (Bp.esCelular(context) ? 1.0 : 1.12);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(factor.clamp(1.0, 1.3))),
          child: child!,
        );
      },
    );
  }
}