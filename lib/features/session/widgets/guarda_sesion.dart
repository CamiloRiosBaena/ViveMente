import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/features/session/providers/sesion_provider.dart';

/// Muestra [child] solo si la sesión cumple [permite]; si no (por ejemplo al
/// recargar la PWA en mitad del flujo) vuelve a [destino].
class GuardaSesion extends ConsumerStatefulWidget {
  const GuardaSesion({
    super.key,
    required this.permite,
    required this.destino,
    required this.child,
  });

  final bool Function(SesionState) permite;
  final String destino;
  final Widget child;

  @override
  ConsumerState<GuardaSesion> createState() => _GuardaSesionState();
}

class _GuardaSesionState extends ConsumerState<GuardaSesion> {
  bool _redirigido = false;

  @override
  Widget build(BuildContext context) {
    if (widget.permite(ref.watch(sesionProvider))) return widget.child;

    if (!_redirigido) {
      _redirigido = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(widget.destino);
      });
    }
    return const Scaffold();
  }
}
