import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class ReportDetailScreen extends StatefulWidget {
  final String reportId;

  const ReportDetailScreen({
    super.key,
    required this.reportId,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late Future<Map<String, dynamic>> _report;

  @override
  void initState() {
    super.initState();
    _report = _loadReport();
  }

  Future<Map<String, dynamic>> _loadReport() async {
    final client = Supabase.instance.client;

    final report = await client
        .from('reports')
        .select(
          'id, title, category, description, status, created_at, '
          'latitude, longitude',
        )
        .eq('id', widget.reportId)
        .single();

    final photos = await client
        .from('public_report_photos')
        .select('storage_path')
        .eq('report_id', widget.reportId);

    final resolution = await client
        .from('public_report_resolutions')
        .select()
        .eq('report_id', widget.reportId)
        .maybeSingle();

    return {
      ...Map<String, dynamic>.from(report),
      'photos': List<Map<String, dynamic>>.from(photos),
      'resolution': resolution == null
          ? null
          : Map<String, dynamic>.from(resolution),
    };
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

  String _formatDate(dynamic date) {
    if (date == null) return 'No disponible';

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();

      return '${parsed.day.toString().padLeft(2, '0')}/'
          '${parsed.month.toString().padLeft(2, '0')}/'
          '${parsed.year}';
    } catch (_) {
      return date.toString();
    }
  }

  Widget _buildResolution(Map<String, dynamic> resolution) {
    final evidence =
        List<String>.from(resolution['evidence_paths'] ?? []);

    return Card(
      color: Colors.green.shade50,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.green.shade300,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified,
                  color: Colors.green,
                  size: 34,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'REPORTE SOLUCIONADO',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            Text(
              'INFORME DE SOLUCIÓN',
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 18),

            _resolutionItem(
              Icons.build_circle,
              'Trabajo realizado',
              resolution['description'],
            ),

            _resolutionItem(
              Icons.person,
              'Responsable',
              resolution['responsible_name'],
            ),

            _resolutionItem(
              Icons.badge,
              'Cargo',
              resolution['responsible_position'],
            ),

            _resolutionItem(
              Icons.calendar_month,
              'Fecha de solución',
              _formatDate(resolution['resolved_at']),
            ),

            _resolutionItem(
              Icons.notes,
              'Observaciones',
              resolution['observations'],
            ),

            const Divider(height: 28),

            const Text(
              'EVIDENCIAS DE LA SOLUCIÓN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (evidence.isEmpty)
              const Text(
                'No se adjuntaron fotografías de la solución.',
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: evidence.map((path) {
                  final imageUrl = Supabase.instance.client.storage
                      .from('report-photos')
                      .getPublicUrl(path);

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 145,
                      height: 145,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(
                        width: 145,
                        height: 145,
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'La solución ha sido registrada por la administración municipal.',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resolutionItem(
    IconData icon,
    String title,
    dynamic value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.green.shade800,
            size: 23,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value?.toString().isNotEmpty == true
                      ? value.toString()
                      : 'No especificado',
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del reporte'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _report,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No se pudo cargar el reporte: ${snapshot.error}',
                ),
              ),
            );
          }

          final report = snapshot.data!;

          final photos =
              report['photos'] as List<Map<String, dynamic>>;

          final resolution =
              report['resolution'] as Map<String, dynamic>?;

          final latitude = report['latitude'];
          final longitude = report['longitude'];

          final status = report['status'] ?? 'pending';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // INFORMACIÓN DEL REPORTE

              Text(
                report['title'] ?? 'Reporte ciudadano',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Categoría: ${report['category'] ?? 'General'}',
              ),

              const SizedBox(height: 8),

              Text(
                'Estado: ${_statusLabel(status)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status == 'resolved'
                      ? Colors.green
                      : Colors.orange.shade800,
                ),
              ),

              const SizedBox(height: 18),

              // INFORME ADMINISTRATIVO

              if (resolution != null)
                _buildResolution(resolution!)
              else if (status == 'resolved')
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.green,
                    ),
                  ),
                  child: const Text(
                    '✓ REPORTE MARCADO COMO RESUELTO\n\n'
                    'El informe administrativo todavía no está disponible.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const Divider(height: 30),

              const Text(
                'Descripción original',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                report['description'] ?? 'Sin descripción',
              ),

              const SizedBox(height: 24),

              const Text(
                'Fotografías originales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (photos.isEmpty)
                const Text(
                  'Este reporte no tiene fotografías.',
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: photos.map((photo) {
                    final path =
                        photo['storage_path'].toString();

                    final imageUrl =
                        Supabase.instance.client.storage
                            .from('report-photos')
                            .getPublicUrl(path);

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 145,
                        height: 145,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(
                          width: 145,
                          height: 145,
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              const Text(
                'Ubicación del problema',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (latitude != null && longitude != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 280,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          (latitude as num).toDouble(),
                          (longitude as num).toDouble(),
                        ),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.appciudadana.reportes',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                (latitude as num).toDouble(),
                                (longitude as num).toDouble(),
                              ),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'El marcador indica dónde se encuentra el problema reportado.',
                  style: TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final lat =
                          (latitude as num).toDouble();

                      final lng =
                          (longitude as num).toDouble();

                      final uri = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
                      );

                      final opened = await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );

                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No se pudo abrir Google Maps.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Cómo llegar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ] else
                const Text(
                  'Ubicación no disponible.',
                ),

              const SizedBox(height: 24),

              Text(
                'Fecha de creación: '
                '${_formatDate(report['created_at'])}',
              ),
            ],
          );
        },
      ),
    );
  }
}