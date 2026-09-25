import 'package:flutter_riverpod/flutter_riverpod.dart';

sealed class AuthState { const AuthState(); }

class AuthInicial extends AuthState { const AuthInicial(); }
class AuthCargando extends AuthState { const AuthCargando(); }
class AuthAutenticado extends AuthState {
  const AuthAutenticado(this.rol, this.localidadId);
  final String rol; 
  final String? localidadId;
}

class AuthError extends AuthState { const AuthError(this.mensaje); final String mensaje; }

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthInicial();

  Future<void> login(String usuario, String clave) async {
    state = const AuthCargando();
    try {
      state = const AuthAutenticado('adminLocal', 'gamarra');
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);