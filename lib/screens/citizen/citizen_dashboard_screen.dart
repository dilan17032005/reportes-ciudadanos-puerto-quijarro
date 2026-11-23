import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/welcome_screen.dart';
import '../reports/create_report_screen.dart';
import '../reports/report_detail_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() =>
      _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState
    extends State<CitizenDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _communityReports;
  late Future<List<Map<String, dynamic>>> _myReports;

  @override
  void initState() {
    super.initState();

    _communityReports = _loadReports();
    _myReports = _loadReports(onlyMine: true);
  }

  // Cargar reportes comunitarios o solamente los propios.
  Future<List<Map<String, dynamic>>> _loadReports({
    bool onlyMine = false,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return [];

    var query = client
        .from('reports')
        .select('id, title, category, status, created_at');

    if (onlyMine) {
      query = query.eq('user_id', user.id);
    }

    final rows = await query.order(
      'created_at',
      ascending: false,
    );

    return List<Map<String, dynamic>>.from(rows);
  }

  // Actualizar las dos listas.
  Future<void> _refresh() async {
    try {
      final results = await Future.wait([
        _loadReports(),
        _loadReports(onlyMine: true),
      ]);

      if (!mounted) return;

      setState(() {
        _communityReports = Future.value(results[0]);
        _myReports = Future.value(results[1]);
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _communityReports = Future.error(error);
        _myReports = Future.error(error);
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes ciudadanos'),
          actions: [
            IconButton(
              tooltip: 'Actualizar reportes',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.public),
                text: 'Muro comunitario',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'Mis reportes',
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateReportScreen(),
              ),
            );

            if (mounted) {
              await _refresh();
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Nuevo reporte'),
        ),

        body: TabBarView(
          children: [
            // PRIMERA PESTAÑA: MURO COMUNITARIO
            _buildReportsList(
              future: _communityReports,
              emptyTitle: 'Todavía no hay reportes',
              emptyMessage:
                  'Cuando los ciudadanos registren problemas, '
                  'aparecerán aquí.',
            ),

            // SEGUNDA PESTAÑA: MIS REPORTES
            _buildReportsList(
              future: _myReports,
              header: _buildWelcome(email),
              emptyTitle: 'Todavía no tienes reportes',
              emptyMessage:
                  'Cuando registres un problema, '
                  'podrás consultar aquí su estado.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            style: const TextStyle(
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ayúdanos a mejorar Puerto Quijarro. '
            'Registra un problema de tu barrio y consulta aquí su avance.',
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList({
    required Future<List<Map<String, dynamic>>> future,
    required String emptyTitle,
    required String emptyMessage,
    Widget? header,
  }) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 150),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 45,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No se pudieron cargar los reportes.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                Center(
                  child: ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ),
              ],
            );
          }

          final reports = snapshot.data ?? [];

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              if (header != null) header,

              if (header == null) ...[
                const Text(
                  'Problemas reportados por la comunidad',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
              ],

              if (reports.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 35,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        emptyTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

              ...reports.map((report) {
                final status =
                    (report['status'] ?? 'pending').toString();

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailScreen(
                            reportId: report['id'].toString(),
                          ),
                        ),
                      );
                    },
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F0FF),
                      child: Icon(
                        Icons.report_problem_outlined,
                        color: Color(0xFF155EEF),
                      ),
                    ),
                    title: Text(
                      (report['title'] ?? 'Reporte ciudadano')
                          .toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${report['category'] ?? 'General'}'
                      ' · ${_statusLabel(status)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              }),
              const SizedBox(height: 90),
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
        'received' => 'Recibido',
        'in_review' => 'En revisión',
        'assigned' => 'Asignado',
        'in_progress' => 'En atención',
        'resolved' => 'Resuelto',
        'rejected' => 'Rechazado',
        _ => 'Pendiente',
      };
}