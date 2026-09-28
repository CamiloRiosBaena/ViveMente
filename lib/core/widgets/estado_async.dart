import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';   

class EstadoAsync<T> extends StatelessWidget {
  const EstadoAsync({super.key, required this.valor, required this.builder});
  final AsyncValue<T> valor;
  final Widget Function(BuildContext, T) builder;

  @override
  Widget build(BuildContext context) => valor.when(
        data: (d) => builder(context, d),
        error: (e, _) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      );
}