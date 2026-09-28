import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vivamente/core/theme/app_theme.dart';
import 'package:vivamente/core/widgets/boton_grande.dart';
import 'package:vivamente/core/widgets/cabecera_flujo.dart';
import 'package:vivamente/core/widgets/pantalla_flujo.dart';
import 'package:vivamente/features/auth/providers/auth_provider.dart';

/// Ingreso del profesional (admin regional o general).
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _usuario = TextEditingController();
  final _clave = TextEditingController();
  bool _ocultarClave = true;

  @override
  void dispose() {
    _usuario.dispose();
    _clave.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(_usuario.text.trim(), _clave.text);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthAutenticado) context.go('/panel');
    });

    final estado = ref.watch(authProvider);
    final cargando = estado is AuthCargando;

    return PantallaFlujo(
      cabecera: CabeceraFlujo(
        titulo: 'Ingreso del profesional',
        onAtras: () => volverOIr(context, '/'),
      ),
      cuerpo: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Escriba su usuario y contraseña para ver los resultados.',
                style: AppTheme.cuerpo(19, height: 1.45),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _usuario,
                enabled: !cargando,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                style: AppTheme.cuerpo(21, color: const Color(0xFF3D2B1C)),
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Escriba su usuario' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clave,
                enabled: !cargando,
                obscureText: _ocultarClave,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _enviar(),
                style: AppTheme.cuerpo(21, color: const Color(0xFF3D2B1C)),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _ocultarClave ? 'Mostrar contraseña' : 'Ocultar contraseña',
                    icon: Icon(
                      _ocultarClave ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _ocultarClave = !_ocultarClave),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Escriba su contraseña' : null,
              ),
              if (estado is AuthError) ...[
                const SizedBox(height: 16),
                Text(
                  estado.mensaje,
                  style: AppTheme.cuerpo(17, color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      pie: BotonGrande(texto: 'Ingresar', cargando: cargando, onPressed: _enviar),
    );
  }
}
