import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lieu.dart';
import '../models/commentaire.dart';
import '../providers/lieu_provider.dart';
import '../providers/commentaire_provider.dart';

class LieuDetailScreen extends StatefulWidget {
  final Lieu lieu;

  const LieuDetailScreen({super.key, required this.lieu});

  @override
  State<LieuDetailScreen> createState() => _LieuDetailScreenState();
}

class _LieuDetailScreenState extends State<LieuDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentaireController = TextEditingController();

  late Lieu lieu;
  int noteSelectionnee = 5;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    lieu = widget.lieu;

    // Animation d'apparition
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Charger les commentaires
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerDonnees();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    final lieuProvider = Provider.of<LieuProvider>(context, listen: false);
    final commentaireProvider = Provider.of<CommentaireProvider>(context, listen: false);

    try {
      final lieuMisAJour = await lieuProvider.obtenirLieuParId(lieu.id!);
      if (lieuMisAJour != null) {
        setState(() {
          lieu = lieuMisAJour;
        });
      }

      await commentaireProvider.chargerCommentairesParLieu(lieu.id!);
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
  }

  Future<void> _ajouterCommentaire() async {
    if (_commentaireController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un commentaire')),
      );
      return;
    }

    try {
      final commentaire = Commentaire(
        lieuId: lieu.id!,
        texte: _commentaireController.text.trim(),
        note: noteSelectionnee,
      );

      await Provider.of<CommentaireProvider>(context, listen: false)
          .ajouterCommentaire(commentaire);

      _commentaireController.clear();
      setState(() {
        noteSelectionnee = 5;
      });

      await _chargerDonnees();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire ajouté !')),
        );
      }
    } catch (e) {
      debugPrint('Erreur ajout commentaire: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentaireProvider = Provider.of<CommentaireProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lieu.nom),
        actions: [
          IconButton(
            icon: Icon(
              lieu.estFavori ? Icons.favorite : Icons.favorite_border,
              color: lieu.estFavori ? Colors.red : Colors.white,
            ),
            onPressed: () async {
              await Provider.of<LieuProvider>(context, listen: false)
                  .basculerFavori(lieu.id!, !lieu.estFavori);
              await _chargerDonnees();
            },
          ),
        ],
      ),
      body: commentaireProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.blue,
                      child: const Icon(
                        Icons.place,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),

                    // Informations
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lieu.nom,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lieu.categorie,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < lieu.noteMoyenne.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 24,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${lieu.noteMoyenne.toStringAsFixed(1)} (${commentaireProvider.commentaires.length} avis)',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (lieu.description != null && lieu.description!.isNotEmpty)
                            Text(
                              lieu.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Carte
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Localisation',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                'Carte\n${lieu.latitude.toStringAsFixed(4)}, ${lieu.longitude.toStringAsFixed(4)}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Commentaires
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commentaires (${commentaireProvider.commentaires.length})',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Formulaire
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ajouter un avis',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text('Note : '),
                                      ...List.generate(5, (index) {
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              noteSelectionnee = index + 1;
                                            });
                                          },
                                          child: Icon(
                                            index < noteSelectionnee
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 28,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _commentaireController,
                                    decoration: const InputDecoration(
                                      hintText: 'Votre commentaire...',
                                      border: OutlineInputBorder(),
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: _ajouterCommentaire,
                                    child: const Text('Publier'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Liste des commentaires
                          if (commentaireProvider.commentaires.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text('Aucun commentaire'),
                              ),
                            )
                          else
                            ...commentaireProvider.commentaires.map((commentaire) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Row(
                                    children: [
                                      ...List.generate(5, (index) {
                                        return Icon(
                                          index < commentaire.note
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: 16,
                                        );
                                      }),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(commentaire.texte),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}