import 'package:flutter/material.dart';
import 'package:vivamente/core/constants/app_colors.dart';
import 'package:vivamente/core/models/game.dart';

/// Color e ícono de cada dominio.
extension DominioEstilo on Dominio {
  Color get color => switch (this) {
        Dominio.atencion => AppColors.dominioAtencion,
        Dominio.memoria => AppColors.dominioMemoria,
        Dominio.funcionesEjecutiva => AppColors.dominioEjecutivas,
        Dominio.fluidezVerbal => AppColors.dominioFluidez,
      };

  IconData get icono => switch (this) {
        Dominio.atencion => Icons.center_focus_strong_outlined,
        Dominio.memoria => Icons.psychology_outlined,
        Dominio.funcionesEjecutiva => Icons.account_tree_outlined,
        Dominio.fluidezVerbal => Icons.record_voice_over_outlined,
      };
}
