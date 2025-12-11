import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ville.dart';
import '../models/lieu.dart';
import '../providers/ville_provider.dart';
import '../providers/lieu_provider.dart';
import '../providers/preferences_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Animation pour la liste
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final villeProvider = Provider.of<VilleProvider>(context, listen: false);
      villeProvider.chargerVilleFavorite().then((_) {
        if (villeProvider.villeFavorite != null) {
          Provider.of<LieuProvider>(context, listen: false)
              .chargerLieuxParVille(villeProvider.villeFavorite!.id!);
        }
      });
    });

    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCoordonnees(double? lat, double? lon) {
    if (lat == null || lon == null) {
      return 'Coordonnées inconnues';
    }
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  Future<void> _rechercherVille() async {
    if (_searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrez un nom de ville')),
      );
      return;
    }

    // Enregistrer dans SharedPreferences
    await Provider.of<PreferencesProvider>(context, listen: false)
        .enregistrerRecherche(_searchController.text);

    setState(() {
      isSearching = true;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${_searchController.text}&format=json&limit=5',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'ExplorezVotreVille/1.0'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Aucune ville trouvée')),
            );
          }
          return;
        }

        if (data.length == 1) {
          await _ajouterVille(data[0]);
        } else {
          if (mounted) {
            _afficherChoixVilles(data);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      setState(() {
        isSearching = false;
      });
    }
  }

  void _afficherChoixVilles(List<dynamic> villes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisissez une ville'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: villes.length,
            itemBuilder: (context, index) {
              final ville = villes[index];
              return ListTile(
                title: Text(ville['display_name'] ?? 'Ville inconnue'),
                onTap: () {
                  Navigator.pop(context);
                  _ajouterVille(ville);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _ajouterVille(Map<String, dynamic> villeData) async {
    try {
      final nomVille = villeData['display_name']?.split(',')[0] ?? 'Ville';
      final lat = double.parse(villeData['lat']);
      final lon = double.parse(villeData['lon']);

      final villeProvider = Provider.of<VilleProvider>(context, listen: false);
      final villesExistantes = await villeProvider.rechercherVilleParNom(nomVille);

      Ville ville;
      if (villesExistantes.isNotEmpty) {
        ville = villesExistantes.first;
      } else {
        final nouvelleVille = Ville(
          nom: nomVille,
          pays: 'France',
          latitude: lat,
          longitude: lon,
          temperatureActuelle: 15.0,
          temperatureMin: 12.0,
          temperatureMax: 18.0,
          etatTemps: 'Ensoleillé',
          estFavorite: false,
        );

        await villeProvider.ajouterVille(nouvelleVille);
        ville = nouvelleVille.copyWith(id: villeProvider.villes.last.id);
      }

      await villeProvider.definirVilleFavorite(ville.id!);
      await Provider.of<LieuProvider>(context, listen: false)
          .chargerLieuxParVille(ville.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ville changée : ${ville.nom}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _afficherFormulaireAjout() {
    final villeProvider = Provider.of<VilleProvider>(context, listen: false);
    if (villeProvider.villeFavorite == null) return;

    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();
    final latController = TextEditingController(text: '48.8566');
    final lonController = TextEditingController(text: '2.3522');
    String categorieSelectionnee = 'Restaurant';

    final categories = [
      'Restaurant',
      'Musée',
      'Parc',
      'Café',
      'Monument',
      'Cinéma',
      'Théâtre',
      'Stade',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un lieu'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du lieu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Le nom est obligatoire';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categorieSelectionnee,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        categorieSelectionnee = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latController,
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: lonController,
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final lieu = Lieu(
                    villeId: villeProvider.villeFavorite!.id!,
                    nom: nomController.text.trim(),
                    description: descriptionController.text.trim(),
                    categorie: categorieSelectionnee,
                    latitude: double.parse(latController.text),
                    longitude: double.parse(lonController.text),
                    noteMoyenne: 0,
                    estFavori: false,
                  );

                  await Provider.of<LieuProvider>(context, listen: false)
                      .ajouterLieu(lieu);
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lieu ajouté !')),
                  );
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser Provider.of au lieu de Consumer
    final villeProvider = Provider.of<VilleProvider>(context);
    final lieuProvider = Provider.of<LieuProvider>(context);

    if (villeProvider.isLoading || lieuProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExplorezVotreVille'),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<PreferencesProvider>(context, listen: false)
                  .basculerModeSombre();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une ville...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _rechercherVille,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onSubmitted: (_) => _rechercherVille(),
              ),
            ),

            // Carte ville avec météo
            if (villeProvider.villeFavorite != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      villeProvider.villeFavorite!.nom,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      villeProvider.villeFavorite!.pays ?? 'France',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text('Min',
                                style: TextStyle(color: Colors.white)),
                            Text(
                              '${(villeProvider.villeFavorite!.temperatureMin ?? 0).toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Actuelle',
                                style: TextStyle(color: Colors.white)),
                            Text(
                              '${(villeProvider.villeFavorite!.temperatureActuelle ?? 0).toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Max',
                                style: TextStyle(color: Colors.white)),
                            Text(
                              '${(villeProvider.villeFavorite!.temperatureMax ?? 0).toStringAsFixed(0)}°',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        villeProvider.villeFavorite!.etatTemps ?? 'Ensoleillé',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Carte interactive
            if (villeProvider.villeFavorite != null)
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/map',
                    arguments: {
                      'ville': villeProvider.villeFavorite,
                      'lieux': lieuProvider.lieux,
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.map, size: 50, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              'Carte interactive - ${lieuProvider.lieux.length} lieu(x)',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Appuyez pour voir la carte',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatCoordonnees(
                              villeProvider.villeFavorite!.latitude,
                              villeProvider.villeFavorite!.longitude,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Liste des lieux avec animation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Lieux',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (lieuProvider.lieux.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'Aucun lieu enregistré',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    AnimatedBuilder(
                      animation: _listAnimationController,
                      builder: (context, child) {
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: lieuProvider.lieux.length,
                          itemBuilder: (context, index) {
                            final lieu = lieuProvider.lieux[index];
                            final animation = Tween<double>(
                              begin: 0.0,
                              end: 1.0,
                            ).animate(
                              CurvedAnimation(
                                parent: _listAnimationController,
                                curve: Interval(
                                  index * 0.1,
                                  1.0,
                                  curve: Curves.easeOut,
                                ),
                              ),
                            );

                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.place,
                                        color: Colors.white,
                                      ),
                                    ),
                                    title: Text(lieu.nom),
                                    subtitle: Text(lieu.categorie),
                                    trailing: Icon(
                                      lieu.estFavori
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: lieu.estFavori
                                          ? Colors.red
                                          : Colors.grey,
                                    ),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/lieu-detail',
                                        arguments: lieu,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listAnimationController,
            curve: Curves.elasticOut,
          ),
        ),
        child: FloatingActionButton(
          onPressed: _afficherFormulaireAjout,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}