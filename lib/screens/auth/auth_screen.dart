import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/validators/form_validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.register = false});
  final bool register;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  late bool _register;

  @override
  void initState() {
    super.initState();
    _register = widget.register;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

String? _required(String? value) {
  return FormValidators.validateRequired(value);
}
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!SupabaseConfig.isConfigured) {
      _message('Falta configurar Supabase. La interfaz está lista, pero la autenticación aún no está conectada.');
      return;
    }
    setState(() => _busy = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (_register) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'full_name': _name.text.trim(), 'requested_role': 'citizen'},
        );
        if (mounted) {
          _message('Cuenta creada. Revisa tu correo si se requiere confirmar el registro.');
        }
      } else {
        await auth.signInWithPassword(
            email: _email.text.trim(), password: _password.text);
        // El formulario se abrió encima de WelcomeScreen con Navigator.push.
        // Al autenticar, volvemos a la ruta raíz para que AuthGate lea
        // currentSession y muestre el panel del ciudadano.
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } on AuthException catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('No se pudo completar la operación. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reportes Ciudadanos')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(_register ? Icons.person_add_alt_1 : Icons.lock_outline,
                          size: 48, color: const Color(0xFF155EEF)),
                      const SizedBox(height: 16),
                      Text(_register ? 'Crear cuenta ciudadana' : 'Bienvenido',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        _register
                            ? 'Regístrate para comunicar problemas de tu comunidad.'
                            : 'Ingresa para continuar con tus reportes.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 28),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                              labelText: 'Nombre completo',
                              prefixIcon: Icon(Icons.person_outline)),
                          validator: _required,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email_outlined)),
validator: FormValidators.validateEmail,                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        autofillHints: _register
                            ? const [AutofillHints.newPassword]
                            : const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                          ),
                        ),
validator: (value) {
  return FormValidators.validatePassword(
    value,
    register: _register,
  );
},                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(_register ? 'Crear cuenta' : 'Ingresar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _register = !_register),
                        child: Text(_register
                            ? '¿Ya tienes cuenta? Inicia sesión'
                            : '¿No tienes cuenta? Regístrate'),
                      ),
                      if (!SupabaseConfig.isConfigured) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Modo de configuración: para activar el acceso real, se debe proporcionar la clave pública (anon/publishable) de Supabase mediante SUPABASE_ANON_KEY. No uses la clave service_role en la aplicación.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B), height: 1.5),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}