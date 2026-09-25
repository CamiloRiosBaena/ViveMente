import 'package:flutter/material.dart';

/// Paleta tomada del diseño "Mente Vital - Flujo Completo".
abstract final class AppColors {
  // Papel y texto
  static const fondo = Color(0xFFFBF6F1); // fondo de página
  static const papel = Color(0xFFFFFAF6); // fondo de cada pantalla
  static const texto = Color(0xFF2B1A0E);
  static const textoSuave = Color(0xFF6B5546);
  static const textoTenue = Color(0xFF9A8574);
  static const borde = Color(0xFFEDDCCD);
  static const bordeTenue = Color(0xFFC9B7A6);
  static const crema = Color(0xFFF8EDE4);

  // Azul: acción, avance y cabeceras
  static const azul = Color(0xFF005883);
  static const azulProfundo = Color(0xFF004266); // admin regional
  static const azulNoche = Color(0xFF002B44); // admin general
  static const azulClaro = Color(0xFFA8CFE3); // texto secundario sobre azul
  static const azulSuave = Color(0xFFE6EFF5);
  static const azulBorde = Color(0xFFC7DEEA);

  // Naranja: selección y marca
  static const naranja = Color(0xFFC2560F);
  static const naranjaSuave = Color(0xFFFDEDE0);
  static const naranjaTexto = Color(0xFF8A3B08);
  static const cafe = Color(0xFF8A3B08); // cabeceras de marca
  static const ambar = Color(0xFFE8A620); // relleno de progreso sobre café
  static const marca = Color(0xFFF47920);
  static const marcaTexto = Color(0xFF3D1A00);

  // Estados
  static const verde = Color(0xFF1E7A4A);
  static const verdeSuave = Color(0xFFE6F2EA);
  static const verdeTexto = Color(0xFF14663C);
  static const rojo = Color(0xFFB3261E);

  // Un color por dominio: solo cambia la cabecera y sus marcas
  static const dominioAtencion = Color(0xFF6E2F06);
  static const dominioMemoria = Color(0xFF9A4209);
  static const dominioEjecutivas = Color(0xFFC2560F);
  static const dominioFluidez = Color(0xFF005883);
}
