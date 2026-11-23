import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  static const LatLng _puertoQuijarro = LatLng(-17.7833, -57.7667);
  LatLng? _selectedLocation;
  double? _accuracyMeters;
  bool _gettingLocation = false;
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Calles y vías';
  bool _saving = false;
  final ImagePicker _picker = ImagePicker();
List<XFile> _selectedPhotos = [];

Future<void> _pickPhotos() async {
  try {
    final remaining = 3 - _selectedPhotos.length;

    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes agregar 3 fotografías como máximo.'),
        ),
      );
      return;
    }

    final photos = await _picker.pickMultiImage(
      imageQuality: 80,
      limit: remaining,
    );

    if (!mounted || photos.isEmpty) return;

    setState(() {
      _selectedPhotos = [
        ..._selectedPhotos,
        ...photos,
      ].take(3).toList();
    });
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron seleccionar las fotografías: $error'),
        ),
      );
    }
  }
}

Future<void> _pickCameraPhoto() async {
  try {
    if (_selectedPhotos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solo puedes agregar 3 fotografías como máximo.'),
        ),
      );
      return;
    }

    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (!mounted || photo == null) return;

    setState(() {
      _selectedPhotos = [..._selectedPhotos, photo];
    });
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo tomar la fotografía: $error'),
        ),
      );
    }
  }
}

  static const _categories = [
    'Calles y vías', 'Alumbrado público', 'Basura y limpieza',
    'Agua potable y fugas', 'Alcantarillado', 'Espacios públicos', 'Otro',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _gettingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Activa los servicios de ubicación de tu dispositivo.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception('No se concedió permiso para acceder a la ubicación.');
      if (permission == LocationPermission.deniedForever) throw Exception('El permiso de ubicación está bloqueado. Habilítalo en la configuración del navegador o dispositivo.');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 25)),
      );
      if (!mounted) return;
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _accuracyMeters = position.accuracy;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ubicación capturada (precisión aproximada: ${position.accuracy.toStringAsFixed(0)} m). Confirma el punto en el mapa.')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final start = _selectedLocation ?? _puertoQuijarro;
    final chosen = await showDialog<LatLng>(
      context: context,
      builder: (dialogContext) {
        LatLng temporary = start;
        return StatefulBuilder(builder: (context, setDialogState) => AlertDialog(
          title: const Text('Confirma la ubicación'),
          content: SizedBox(width: 560, height: 390, child: Column(children: [
            const Text('Toca el mapa para colocar el marcador en el lugar del problema.'),
            const SizedBox(height: 10),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: FlutterMap(
              options: MapOptions(initialCenter: start, initialZoom: 15, onTap: (tapPosition, point) => setDialogState(() => temporary = point)),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'bo.appciudadana.reportes'),
                MarkerLayer(markers: [Marker(point: temporary, width: 44, height: 44, child: const Icon(Icons.location_pin, color: Colors.red, size: 44))]),
              ],
            ))),
            const SizedBox(height: 8),
            Text('${temporary.latitude.toStringAsFixed(6)}, ${temporary.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12)),
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, temporary), child: const Text('Confirmar punto'))],
        ));
      },
    );
    if (chosen != null && mounted) setState(() { _selectedLocation = chosen; _accuracyMeters = null; });
  }
   Future<void> _uploadPhotos(String reportId, String userId) async {
  for (int i = 0; i < _selectedPhotos.length; i++) {
    final photo = _selectedPhotos[i];

    final extension = photo.name.contains('.')
        ? photo.name.split('.').last.toLowerCase()
        : 'jpg';

    final fileName =
        '${DateTime.now().microsecondsSinceEpoch}_$i.$extension';

    final storagePath = '$userId/$reportId/$fileName';

    final contentType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    final bytes = await photo.readAsBytes();

    await Supabase.instance.client.storage
        .from('report-photos')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: false,
          ),
        );

    await Supabase.instance.client.from('report_photos').insert({
      'report_id': reportId,
      'user_id': userId,
      'storage_path': storagePath,
    });
  }
}
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Primero captura tu GPS o selecciona el punto del problema en el mapa.')));
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final report = await Supabase.instance.client
          .from('reports')
          .insert({
            'user_id': user.id,
            'title': _title.text.trim(),
            'category': _category,
            'description': _description.text.trim(),
            'status': 'pending',
            'latitude': _selectedLocation!.latitude,
            'longitude': _selectedLocation!.longitude,
            'location_accuracy_m': _accuracyMeters,
            'location_captured_at':
                DateTime.now().toUtc().toIso8601String(),
          })
          .select('id')
          .single();

      final reportId = report['id'].toString();

      await _uploadPhotos(reportId, user.id);

      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo guardar: ${error.message}')));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocurrió un error al guardar el reporte.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) => Scaffold(

    appBar: AppBar(title: const Text('Nuevo reporte')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text('Cuéntanos qué está pasando', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Describe el problema y señala su ubicación exacta para que el municipio pueda localizarlo.', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 22),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category_outlined),
               ),
  items: _categories
      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
      .toList(),
  onChanged: (value) => setState(() => _category = value ?? _category),
),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _title,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Título del problema', hintText: 'Ej. Poste de luz apagado', prefixIcon: Icon(Icons.title)),
                  validator: (value) => value == null || value.trim().length < 5 ? 'Escribe un título de al menos 5 caracteres' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _description,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 1500,
                  decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true, hintText: 'Indica dónde ocurre y por qué es un problema...'),
                  validator: (value) => value == null || value.trim().length < 15 ? 'Describe el problema con al menos 15 caracteres' : null,
                ),
               const Text(
  'Fotografías del problema',
  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
),

const SizedBox(height: 8),

OutlinedButton.icon(
  onPressed: _selectedPhotos.length >= 3
      ? null
      : _pickCameraPhoto,
  icon: const Icon(Icons.camera_alt_outlined),
  label: const Text('Tomar fotografía con la cámara'),
),
const SizedBox(height: 8),

OutlinedButton.icon(
  onPressed: _selectedPhotos.length >= 3
      ? null
      : _pickPhotos,
  icon: const Icon(Icons.photo_library_outlined),
  label: const Text('Seleccionar de la galería'),
),

if (_selectedPhotos.isNotEmpty) ...[
      const SizedBox(height: 12),
     Wrap(
      spacing: 10,
     runSpacing: 10,
     children: _selectedPhotos.map((photo) {
      return Stack(
        children: [
          FutureBuilder(
            future: photo.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  width: 100,
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  snapshot.data!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedPhotos.remove(photo);
                });
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
          ),
        ],
      );

        }).toList(),
      ),
    ],

const SizedBox(height: 18),
                const SizedBox(height: 18),
                const Text('Ubicación del problema', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _gettingLocation ? null : _captureLocation,
                  icon: _gettingLocation ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
                  label: Text(_gettingLocation ? 'Obteniendo GPS...' : 'Usar mi ubicación actual'),
                ),
                OutlinedButton.icon(
                  onPressed: _chooseOnMap,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Elegir o ajustar punto en el mapa'),
                ),
                if (_selectedLocation != null) Container(
                  margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFE8F7EF), borderRadius: BorderRadius.circular(12)),
                  child: Text('Punto seleccionado: ${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}${_accuracyMeters == null ? ' · Marcador manual' : ' · Precisión GPS aproximada: ${_accuracyMeters!.toStringAsFixed(0)} m'}', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_outlined),
                  label: Text(_saving ? 'Enviando...' : 'Enviar reporte'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
