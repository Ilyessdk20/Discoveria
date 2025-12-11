import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ville.dart';
import '../models/lieu.dart';
import 'lieu_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final Ville ville;
  final List<Lieu> lieux;
  final List<Map<String, dynamic>> lieuxProches;

  const MapScreen({
    super.key, 
    required this.ville, 
    required this.lieux,
    this.lieuxProches = const [],
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  late LatLng _center;
  LatLng? _selectedPoint;
  List<Map<String, dynamic>> _lieuxProche = [];

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.ville.latitude ?? 48.8566,
      widget.ville.longitude ?? 2.3522,
    );
    // Initialiser avec les lieux proches passés du widget
    _lieuxProche = widget.lieuxProches;
  }

  Future<void> _rechercherLieuAProximite(LatLng point) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ExplorezVotreVille/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Chercher les POI (lieux d'intérêt) à proximité
        await _rechercherPOI(point.latitude, point.longitude);
        
        if (mounted) {
          setState(() {
            _selectedPoint = point;
          });
          
          _afficherInfoLieu(data);
        }
      }
    } catch (e) {
      debugPrint('Erreur recherche lieu: $e');
    }
  }

  Future<void> _rechercherPOI(double lat, double lon) async {
    try {
      // Utiliser Overpass API pour trouver les POI à proximité
      final url = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=[bbox=${lat - 0.01},${lon - 0.01},${lat + 0.01},${lon + 0.01}];(node[amenity];node[leisure];node[tourism];node[shop];);out center;',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            _lieuxProche = [];
            if (data['elements'] != null) {
              for (var element in data['elements']) {
                if (element['center'] != null) {
                  _lieuxProche.add(element);
                } else if (element['lat'] != null && element['lon'] != null) {
                  _lieuxProche.add(element);
                }
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur recherche POI: $e');
      // Si Overpass API échoue, on continue quand même
    }
  }

  void _afficherInfoLieu(Map<String, dynamic> data) {
    final lat = double.tryParse(data['lat'].toString()) ?? 0;
    final lon = double.tryParse(data['lon'].toString()) ?? 0;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['address']?['name'] ?? data['name'] ?? 'Lieu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['address'] != null) ...[
                Text('Rue: ${data['address']['road'] ?? 'N/A'}'),
                Text('Ville: ${data['address']['city'] ?? data['address']['town'] ?? 'N/A'}'),
                Text('Code postal: ${data['address']['postcode'] ?? 'N/A'}'),
              ],
              const SizedBox(height: 8),
              Text('Latitude: $lat'),
              Text('Longitude: $lon'),
              const SizedBox(height: 8),
              Text(
                'Type: ${data['type'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _afficherFormulaireAjout(lat, lon, data);
            },
            child: const Text('Ajouter ce lieu'),
          ),
        ],
      ),
    );
  }

  void _afficherFormulaireAjout(double lat, double lon, Map<String, dynamic> data) {
    final nomController = TextEditingController(
      text: data['address']?['name'] ?? data['name'] ?? 'Nouveau lieu',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un lieu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom du lieu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Latitude: $lat'),
              Text('Longitude: $lon'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              final lieu = Lieu(
                villeId: widget.ville.id!,
                nom: nomController.text.trim(),
                categorie: 'Autre',
                latitude: lat,
                longitude: lon,
                noteMoyenne: 0,
                estFavori: false,
              );
              Navigator.pop(context);
              Navigator.pop(context, lieu);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carte - ${widget.ville.nom}'),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _center,
          initialZoom: 12.0,
          onTap: (tapPosition, point) {
            _rechercherLieuAProximite(point);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              // Marker de la ville
              Marker(
                point: _center,
                width: 80,
                height: 80,
                child: GestureDetector(
                  onTap: () {
                    _afficherInfoVille();
                  },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_city,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              ),
              // Marker du point sélectionné
              if (_selectedPoint != null)
                Marker(
                  point: _selectedPoint!,
                  width: 80,
                  height: 80,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ],
                  ),
                ),
              // Markers des lieux
              ...widget.lieux.map((lieu) {
                return Marker(
                  point: LatLng(lieu.latitude, lieu.longitude),
                  width: 80,
                  height: 80,
                  child: GestureDetector(
                    onTap: () {
                      _afficherInfoLieuObjet(lieu);
                    },
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              // Markers des lieux proches trouvés
              ...(_lieuxProche.isNotEmpty
                  ? _lieuxProche
                      .map((poiData) {
                        try {
                          final lat = (poiData['center'] != null
                              ? poiData['center']['lat']
                              : poiData['lat']) as num?;
                          final lon = (poiData['center'] != null
                              ? poiData['center']['lon']
                              : poiData['lon']) as num?;
                          
                          if (lat == null || lon == null) return null;
                          
                          final tags = poiData['tags'] as Map<String, dynamic>? ?? {};
                          final nom = tags['name'] ?? tags['amenity'] ?? tags['leisure'] ?? 'POI';
                          
                          return Marker(
                            point: LatLng(lat.toDouble(), lon.toDouble()),
                            width: 60,
                            height: 60,
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(nom.toString()),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Lat: $lat, Lon: $lon'),
                                        if (tags['amenity'] != null)
                                          Text('Type: ${tags['amenity']}'),
                                        if (tags['leisure'] != null)
                                          Text('Type: ${tags['leisure']}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Fermer'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pin_drop,
                                    color: Colors.orange,
                                    size: 30,
                                  ),
                                ],
                              ),
                            ),
                          );
                        } catch (e) {
                          debugPrint('Erreur affichage POI: $e');
                          return null;
                        }
                      })
                      .whereType<Marker>()
                      .toList()
                  : []),
            ],
          ),
        ],
      ),
    );
  }

  void _afficherInfoVille() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.ville.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pays: ${widget.ville.pays ?? "France"}'),
            Text('Température: ${widget.ville.temperatureActuelle}°C'),
            Text('État: ${widget.ville.etatTemps ?? "Ensoleillé"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _afficherInfoLieuObjet(Lieu lieu) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lieu.nom),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catégorie: ${lieu.categorie}'),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text('${lieu.noteMoyenne.toStringAsFixed(1)}'),
              ],
            ),
            if (lieu.description != null) ...[
              const SizedBox(height: 8),
              Text(
                lieu.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LieuDetailScreen(lieu: lieu),
                ),
              );
            },
            child: const Text('Voir détails'),
          ),
        ],
      ),
    );
  }
}