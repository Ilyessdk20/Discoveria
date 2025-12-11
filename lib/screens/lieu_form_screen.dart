import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/lieu.dart';
import '../providers/lieu_provider.dart';

class LieuFormScreen extends StatefulWidget {
  final int villeId;
  final Lieu? lieu;

  const LieuFormScreen({super.key, required this.villeId, this.lieu});

  @override
  State<LieuFormScreen> createState() => _LieuFormScreenState();
}

class _LieuFormScreenState extends State<LieuFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomController;
  late TextEditingController _descriptionController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String categorieSelectionnee = 'Restaurant';
  final List<String> categories = [
    'Restaurant',
    'Musée',
    'Parc',
    'Café',
    'Monument',
    'Cinéma',
    'Théâtre',
    'Stade',
  ];

  @override
  void initState() {
    super.initState();

    if (widget.lieu != null) {
      _nomController = TextEditingController(text: widget.lieu!.nom);
      _descriptionController =
          TextEditingController(text: widget.lieu!.description ?? '');
      _latitudeController =
          TextEditingController(text: widget.lieu!.latitude.toString());
      _longitudeController =
          TextEditingController(text: widget.lieu!.longitude.toString());
      categorieSelectionnee = widget.lieu!.categorie;
    } else {
      _nomController = TextEditingController();
      _descriptionController = TextEditingController();
      _latitudeController = TextEditingController(text: '48.8566');
      _longitudeController = TextEditingController(text: '2.3522');
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final lieu = Lieu(
        id: widget.lieu?.id,
        villeId: widget.villeId,
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categorie: categorieSelectionnee,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        noteMoyenne: widget.lieu?.noteMoyenne ?? 0,
        estFavori: widget.lieu?.estFavori ?? false,
      );

      final lieuProvider = Provider.of<LieuProvider>(context, listen: false);

      if (widget.lieu == null) {
        await lieuProvider.ajouterLieu(lieu);
      } else {
        await lieuProvider.mettreAJourLieu(lieu);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.lieu == null ? 'Lieu ajouté !' : 'Lieu modifié !',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _choisirSurCarte() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLat: double.tryParse(_latitudeController.text) ?? 48.8566,
          initialLon: double.tryParse(_longitudeController.text) ?? 2.3522,
          onLocationSelected: (lat, lon) {
            setState(() {
              _latitudeController.text = lat.toStringAsFixed(6);
              _longitudeController.text = lon.toStringAsFixed(6);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lieu == null ? 'Ajouter un lieu' : 'Modifier le lieu'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '1. Nom du lieu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du lieu',
                hintText: 'Ex: Le Louvre',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Catégorie',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: categorieSelectionnee,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
                border: OutlineInputBorder(),
              ),
              items: categories.map((categorie) {
                return DropdownMenuItem(
                  value: categorie,
                  child: Text(categorie),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  categorieSelectionnee = value!;
                });
              },
            ),
            const SizedBox(height: 24),
            const Text(
              '3. Localisation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _choisirSurCarte,
              icon: const Icon(Icons.map),
              label: const Text('Choisir sur la carte'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Requis';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '4. Description (optionnelle)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sauvegarder,
                    child: Text(widget.lieu == null ? 'Ajouter' : 'Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Écran de sélection sur carte
class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;
  final Function(double, double) onLocationSelected;

  const MapPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLon,
    required this.onLocationSelected,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _selectedPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedPosition = LatLng(widget.initialLat, widget.initialLon);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la position'),
        actions: [
          TextButton(
            onPressed: () {
              widget.onLocationSelected(
                _selectedPosition.latitude,
                _selectedPosition.longitude,
              );
              Navigator.pop(context);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.blue[50],
            child: Text(
              'Lat: ${_selectedPosition.latitude.toStringAsFixed(6)}, Lon: ${_selectedPosition.longitude.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedPosition,
                initialZoom: 13.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _selectedPosition = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPosition,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Appuyez sur la carte pour choisir une position',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}