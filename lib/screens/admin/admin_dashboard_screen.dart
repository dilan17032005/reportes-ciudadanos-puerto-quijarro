import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../auth/welcome_screen.dart';
import '../reports/report_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final client = Supabase.instance.client;

  late Future<List<Map<String, dynamic>>> _reports;

  @override
  void initState() {
    super.initState();
    _reports = _loadReports();
  }

  Future<List<Map<String, dynamic>>> _loadReports() async {
    final rows = await client
        .from('reports')
        .select('id, title, category, status, created_at')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _refresh() async {
    setState(() {
      _reports = _loadReports();
    });

    await _reports;
  }

  Future<void> _signOut() async {
    await client.auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const WelcomeScreen(),
      ),
      (route) => false,
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

  Color _statusColor(String status) => switch (status) {
        'resolved' => Colors.green,
        'in_progress' => Colors.blue,
        'assigned' => Colors.orange,
        'in_review' => Colors.purple,
        'rejected' => Colors.red,
        _ => Colors.grey,
      };

Future<void> _manageReport(Map<String, dynamic> report) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return _ManageReportDialog(
        report: report,
        client: client,
      );
    },
  );

  if (saved != true || !mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Reporte actualizado correctamente.'),
      backgroundColor: Colors.green,
    ),
  );

  await _refresh();
}

  @override
  Widget build(BuildContext context) {
    final email = client.auth.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF153E75),
        foregroundColor: Colors.white,
        title: const Text(
          'Administración municipal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 50,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Text('Error al cargar los reportes'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final reports = snapshot.data ?? [];

          final total = reports.length;

          final resolved = reports.where(
            (r) => r['status'] == 'resolved',
          ).length;

          final pending = reports.where(
            (r) => r['status'] == 'received',
          ).length;

          final inProgress = reports.where(
            (r) => r['status'] == 'in_progress',
          ).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFF153E75),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Panel de administración',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gestiona los reportes ciudadanos y supervisa '
                        'los problemas registrados en el municipio.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Resumen general',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _statCard(
                      'Total reportes',
                      total,
                      Icons.assignment,
                      Colors.blue,
                    ),
                    _statCard(
                      'Pendientes',
                      pending,
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                    _statCard(
                      'En atención',
                      inProgress,
                      Icons.engineering,
                      Colors.indigo,
                    ),
                    _statCard(
                      'Solucionados',
                      resolved,
                      Icons.verified,
                      Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Todos los reportes',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Text(
                        'Todavía no hay reportes registrados.',
                      ),
                    ),
                  ),

                ...reports.map((report) {
                  final status =
                      (report['status'] ?? 'received').toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),

                      leading: CircleAvatar(
                        backgroundColor:
                            _statusColor(status).withOpacity(0.12),
                        child: Icon(
                          Icons.report_problem,
                          color: _statusColor(status),
                        ),
                      ),

                      title: Text(
                        report['title'] ?? 'Reporte ciudadano',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(
                          '${report['category'] ?? 'General'}\n'
                          'Estado: ${_statusLabel(status)}',
                        ),
                      ),

                      trailing: IconButton(
                        tooltip: 'Gestionar reporte',
                        icon: const Icon(
                          Icons.edit_note,
                          color: Color(0xFF153E75),
                          size: 30,
                        ),
                        onPressed: () => _manageReport(report),
                      ),

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailScreen(
                              reportId: report['id'].toString(),
                            ),
                          ),
                        );

                        if (mounted) {
                          await _refresh();
                        }
                      },
                    ),
                  );
                }),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
class _ManageReportDialog extends StatefulWidget {
  final Map<String, dynamic> report;
  final SupabaseClient client;

  const _ManageReportDialog({
    required this.report,
    required this.client,
  });

  @override
  State<_ManageReportDialog> createState() =>
      _ManageReportDialogState();
}

class _ManageReportDialogState
    extends State<_ManageReportDialog> {
  late String selectedStatus;

  final descriptionController = TextEditingController();
  final responsibleController = TextEditingController();
  final positionController = TextEditingController();
  final observationsController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool saving = false;
  String? errorMessage;
  final ImagePicker imagePicker = ImagePicker();

 final List<EvidenceFile> evidenceFiles = [];
  @override
  void initState() {
    super.initState();

    selectedStatus =
        (widget.report['status'] ?? 'received').toString();
  }

Future<void> _takePhoto() async {
  try {
    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (!mounted) return;

    setState(() {
      evidenceFiles.add(
        EvidenceFile(
          name: image.name,
          bytes: bytes,
        ),
      );
    });
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al abrir cámara: $error')),
    );
  }
}

Future<void> _pickImages() async {
  try {
    final images = await imagePicker.pickMultiImage(
      imageQuality: 85,
    );

    for (final image in images) {
      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        evidenceFiles.add(
          EvidenceFile(
            name: image.name,
            bytes: bytes,
          ),
        );
      });
    }
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al elegir imágenes: $error')),
    );
  }
}

Future<void> _pickDocuments() async {
  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],    );

    if (files.isEmpty) return;

    for (final file in files) {
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        evidenceFiles.add(
          EvidenceFile(
            name: file.name,
            bytes: bytes,
          ),
        );
      });
    }
  } catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al elegir archivos: $error')),
    );
  }
}
Future<List<String>> _uploadEvidence(String reportId) async {
  final uploadedPaths = <String>[];

  for (var i = 0; i < evidenceFiles.length; i++) {
   final file = evidenceFiles[i];
  final bytes = file.bytes;

 final extension = file.extension.toLowerCase();
    final safeName = file.name.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    final path =
'$reportId/resolutions/${DateTime.now().millisecondsSinceEpoch}_${i}_$safeName';
  final contentType = switch (extension) {
  'jpg' || 'jpeg' => 'image/jpeg',
  'png' => 'image/png',
  'webp' => 'image/webp',
  'pdf' => 'application/pdf',
  _ => throw Exception(
      'Formato no permitido: .$extension. Usa imágenes o PDF.',
    ),
};
    await widget.client.storage
        .from('report-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    uploadedPaths.add(path);
  }

  return uploadedPaths;
}
  @override
  void dispose() {
    descriptionController.dispose();
    responsibleController.dispose();
    positionController.dispose();
    observationsController.dispose();

    super.dispose();
  }

Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;

  setState(() {
    saving = true;
    errorMessage = null;
  });

  try {
    final reportId = widget.report['id'].toString();

    if (selectedStatus == 'resolved') {
      // Buscar si ya existe información de resolución.
      final existing = await widget.client
          .from('report_resolutions')
          .select('id, evidence_paths')
          .eq('report_id', reportId)
          .maybeSingle();

      // Subir las nuevas evidencias.
     debugPrint('IMÁGENES SELECCIONADAS: ${evidenceFiles.length}');

final newPaths = await _uploadEvidence(reportId);

debugPrint('RUTAS SUBIDAS: $newPaths');
      // Conservar las evidencias anteriores.
      final previousPaths =
          (existing?['evidence_paths'] as List<dynamic>? ?? [])
              .map((path) => path.toString())
              .toList();

      final allPaths = [...previousPaths, ...newPaths];

      final resolutionData = {
        'report_id': reportId,
        'description': descriptionController.text.trim(),
        'responsible_name': responsibleController.text.trim(),
        'responsible_position': positionController.text.trim(),
        'observations': observationsController.text.trim(),
        'evidence_paths': allPaths,
      };

      if (existing == null) {
        await widget.client
            .from('report_resolutions')
            .insert(resolutionData);
      } else {
        await widget.client
            .from('report_resolutions')
            .update(resolutionData)
            .eq('report_id', reportId);
      }
    }

    // Actualizar el estado del reporte.
    await widget.client
        .from('reports')
        .update({
          'status': selectedStatus,
        })
        .eq('id', reportId);

    if (!mounted) return;

    Navigator.of(context).pop(true);
  } catch (error) {
    if (!mounted) return;

    setState(() {
      saving = false;
      errorMessage = 'No se pudo guardar: $error';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Gestionar reporte',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.report['title']?.toString() ??
                      'Reporte ciudadano',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Estado del reporte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'received',
                      child: Text('Recibido'),
                    ),
                    DropdownMenuItem(
                      value: 'in_review',
                      child: Text('En revisión'),
                    ),
                    DropdownMenuItem(
                      value: 'assigned',
                      child: Text('Asignado'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('En atención'),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text('Resuelto'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rechazado'),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() {
                              selectedStatus = value;
                            });
                          }
                        },
                ),

                if (selectedStatus == 'resolved') ...[
                  const SizedBox(height: 22),

                  const Divider(),

                  const Text(
                    'Información de la solución',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción de la solución',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (value) {
                      if (selectedStatus == 'resolved' &&
                          (value == null ||
                              value.trim().isEmpty)) {
                        return 'Describe cómo se solucionó';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: responsibleController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del responsable',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (selectedStatus == 'resolved' &&
                          (value == null ||
                              value.trim().isEmpty)) {
                        return 'Ingresa el responsable';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: positionController,
                    decoration: const InputDecoration(
                      labelText: 'Cargo del responsable',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: observationsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                ],
const SizedBox(height: 16),

const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Evidencias de resolución',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 10),

Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    OutlinedButton.icon(
      onPressed: saving ? null : _takePhoto,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Tomar foto'),
    ),
    OutlinedButton.icon(
      onPressed: saving ? null : _pickImages,
      icon: const Icon(Icons.photo_library),
      label: const Text('Galería'),
    ),
    OutlinedButton.icon(
      onPressed: saving ? null : _pickDocuments,
      icon: const Icon(Icons.attach_file),
      label: const Text('Adjuntar archivos'),
    ),
  ],
),

if (evidenceFiles.isNotEmpty) ...[
  const SizedBox(height: 12),
  ...evidenceFiles.asMap().entries.map((entry) {
    final index = entry.key;
    final file = entry.value;

    return ListTile(
      dense: true,
      leading: Icon(
file.extension.toLowerCase() == 'pdf'
            ? Icons.picture_as_pdf
            : Icons.image,
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${(file.size / 1024).toStringAsFixed(1)} KB'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: saving
            ? null
            : () {
                setState(() {
                  evidenceFiles.removeAt(index);
                });
              },
      ),
    );
  }),
],
                if (errorMessage != null) ...[
                  const SizedBox(height: 15),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),

        ElevatedButton.icon(
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save),
          label: Text(
            saving ? 'Guardando...' : 'Guardar cambios',
          ),
          onPressed: saving ? null : _save,
        ),
      ],
    );
  }
}
class EvidenceFile {
  final String name;
  final Uint8List bytes;

  EvidenceFile({
    required this.name,
    required this.bytes,
  });

  String get extension {
    return name.contains('.')
        ? name.split('.').last.toLowerCase()
        : '';
  }

  int get size => bytes.length;
}
