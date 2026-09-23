import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vivamente/core/models/game.dart';

class Ciclo {
  const Ciclo({
    required this.id,
    required this.adultoId,
    required this.localidadId,
    required this.fechaInicio,
    this.fechaFin,
    this.juegosCompletados = const {},
  });

  final String id;
  final String adultoId;
  final String localidadId;
  final DateTime fechaInicio;
  final DateTime? fechaFin;
  final Set<String> juegosCompletados; // IDs de Minijuego

  bool get completado => fechaFin != null;

  bool estaCompletado(Game j) => juegosCompletados.contains(j.id);
  List<Game> pendientes(List<Game> todos) =>
      todos.where((j) => !estaCompletado(j)).toList();

  factory Ciclo.fromMap(String id, Map<String, dynamic> d) => Ciclo(
        id: id,
        adultoId: d['adultoId'] as String,
        localidadId: d['localidadId'] as String,
        fechaInicio: (d['fechaInicio'] as Timestamp).toDate(),
        fechaFin: (d['fechaFin'] as Timestamp?)?.toDate(),
        juegosCompletados: Set<String>.from(d['juegosCompletados'] as List? ?? const []),
      );
  
  Map<String, dynamic> toMap() => {
        'adultoId': adultoId,
        'localidadId': localidadId,
        'fechaInicio': Timestamp.fromDate(fechaInicio),
        'fechaFin': fechaFin == null ? null : Timestamp.fromDate(fechaFin!),
        'juegosCompletados': juegosCompletados.toList(),
      };
}