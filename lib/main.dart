import 'core/config/supabase_config.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/citizen/citizen_dashboard_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const ReportesCiudadanosApp());
}
class ReportesCiudadanosApp extends StatelessWidget {
  const ReportesCiudadanosApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Reportes Ciudadanos',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const WelcomeScreen();
    }

    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session =
            client.auth.currentSession ?? snapshot.data?.session;

        if (session == null) {
          return const WelcomeScreen();
        }

        return UserRoleGate(
          key: ValueKey(session.user.id),
          userId: session.user.id,
        );
      },
    );
  }
}

class UserRoleGate extends StatefulWidget {
  final String userId;

  const UserRoleGate({
    super.key,
    required this.userId,
  });

  @override
  State<UserRoleGate> createState() => _UserRoleGateState();
}

class _UserRoleGateState extends State<UserRoleGate> {
  late Future<String> _role;

  @override
  void initState() {
    super.initState();
    _role = _loadRole();
  }

  Future<String> _loadRole() async {
    final result = await Supabase.instance.client
        .from('user_roles')
        .select('role')
        .eq('user_id', widget.userId)
        .maybeSingle();

    return result?['role']?.toString() ?? 'citizen';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _role,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron verificar tus permisos.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _role = _loadRole();
                        });
                      },
                      child: const Text('Reintentar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                      },
                      child: const Text('Cerrar sesión'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final role = snapshot.data ?? 'citizen';

        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        // Los ciudadanos y, temporalmente, los funcionarios
        // utilizan el panel ciudadano.
        return const CitizenDashboardScreen();
      },
    );
  }
}