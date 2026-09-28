import 'package:flutter/services.dart';

const cedulaMinDigitos = 6;
const cedulaMaxDigitos = 10;

/// Solo dígitos y hasta [cedulaMaxDigitos].
final List<TextInputFormatter> formatosCedula = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(cedulaMaxDigitos),
];

bool cedulaValida(String cedula) => cedula.length >= cedulaMinDigitos && cedula.length <= cedulaMaxDigitos;
