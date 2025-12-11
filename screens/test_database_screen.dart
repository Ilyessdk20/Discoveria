// lib/screens/test_database_screen.dart

import 'package:flutter/material.dart';
import '../services/ville_service.dart';
import '../services/lieu_service.dart';
import '../services/commentaire_service.dart';
import '../models/ville.dart';
import '../models/lieu.dart';
import '../models/commentaire.dart';

class TestDatabaseScreen extends StatefulWidget {
  @override
  State<TestDatabaseScreen> createState() => _TestDatabaseScreenState();
}

class _TestDatabaseScreenState extends State<TestDatabaseScreen> {
  final villeService = VilleService();
  final lieuService = LieuService();
  final commentaireService = CommentaireService();

  String _resultat = 'Appuyez sur un bouton pour tester';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Base de Données'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Zone d'affichage des résultats
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Text(
                        _resultat,
                        style: TextStyle(fontSize: 14),
                      ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Boutons de test
            _buildTestButton(
              'Test 1 : Ajouter une ville',
              Colors.green,
              _test1AjouterVille,
            ),
            
            _buildTestButton(
              'Test 2 : Récupérer toutes les villes',
              Colors.blue,
              _test2RecupererVilles,
            ),
            
            _buildTestButton(
              'Test 3 : Ajouter des lieux',
              Colors.orange,
              _test3AjouterLieux,
            ),
            
            _buildTestButton(
              'Test 4 : Récupérer lieux par ville',
              Colors.purple,
              _test4RecupererLieux,
            ),
            
            _buildTestButton(
              'Test 5 : Ajouter un commentaire',
              Colors.teal,
              _test5AjouterCommentaire,
            ),
            
            _buildTestButton(
              'Test 6 : Test complet',
              Colors.indigo,
              _test6Complet,
            ),
            
            SizedBox(height: 20),
            
            _buildTestButton(
              '🗑️ Supprimer toutes les données',
              Colors.red,
              _supprimerTout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(String text, Color color, Function() onPressed) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        onPressed: () async {
          setState(() {
            _isLoading = true;
            _resultat = 'Chargement...';
          });
          await onPressed();
          setState(() {
            _isLoading = false;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.all(16),
        ),
        child: Text(text, style: TextStyle(fontSize: 16)),
      ),
    );
  }

  // TEST 1 : Ajouter une ville
  Future<void> _test1AjouterVille() async {
    try {
      final ville = Ville(
        nom: 'Paris',
        pays: 'France',
        latitude: 48.8566,
        longitude: 2.3522,
        temperatureActuelle: 15.0,
        temperatureMin: 12.0,
        temperatureMax: 18.0,
        etatTemps: 'Ensoleillé',
        estFavorite: true,
      );

      final id = await villeService.ajouterVille(ville);
      
      setState(() {
        _resultat = '✅ SUCCÈS !\n\n'
            'Ville ajoutée avec succès !\n'
            'ID: $id\n'
            'Nom: ${ville.nom}\n'
            'Pays: ${ville.pays}\n'
            'Température: ${ville.temperatureActuelle}°C';
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR !\n\n$e';
      });
    }
  }

  // TEST 2 : Récupérer toutes les villes
  Future<void> _test2RecupererVilles() async {
    try {
      final villes = await villeService.obtenirToutesVilles();
      
      if (villes.isEmpty) {
        setState(() {
          _resultat = '⚠️ Aucune ville trouvée.\n\n'
              'Ajoutez d\'abord une ville (Test 1)';
        });
        return;
      }

      String resultat = '✅ SUCCÈS !\n\n';
      resultat += 'Nombre de villes: ${villes.length}\n\n';
      
      for (var ville in villes) {
        resultat += '📍 ${ville.nom} (${ville.pays})\n';
        resultat += '   ID: ${ville.id}\n';
        resultat += '   Temp: ${ville.temperatureActuelle}°C\n';
        resultat += '   Favorite: ${ville.estFavorite ? "Oui" : "Non"}\n\n';
      }

      setState(() {
        _resultat = resultat;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR !\n\n$e';
      });
    }
  }

  // TEST 3 : Ajouter des lieux
  Future<void> _test3AjouterLieux() async {
    try {
      // D'abord, vérifier qu'on a au moins une ville
      final villes = await villeService.obtenirToutesVilles();
      
      if (villes.isEmpty) {
        setState(() {
          _resultat = '⚠️ Aucune ville trouvée.\n\n'
              'Ajoutez d\'abord une ville (Test 1)';
        });
        return;
      }

      final villeId = villes.first.id!;

      // Ajouter des lieux
      final lieu1 = Lieu(
        villeId: villeId,
        nom: 'Tour Eiffel',
        description: 'Monument emblématique de Paris',
        categorie: 'Monument',
        latitude: 48.8584,
        longitude: 2.2945,
        estFavori: true,
      );

      final lieu2 = Lieu(
        villeId: villeId,
        nom: 'Musée du Louvre',
        description: 'Le plus grand musée d\'art du monde',
        categorie: 'Musée',
        latitude: 48.8606,
        longitude: 2.3376,
      );

      final id1 = await lieuService.ajouterLieu(lieu1);
      final id2 = await lieuService.ajouterLieu(lieu2);

      setState(() {
        _resultat = '✅ SUCCÈS !\n\n'
            'Lieux ajoutés avec succès !\n\n'
            '📍 ${lieu1.nom} (ID: $id1)\n'
            '   Catégorie: ${lieu1.categorie}\n'
            '   Favori: ${lieu1.estFavori ? "Oui" : "Non"}\n\n'
            '📍 ${lieu2.nom} (ID: $id2)\n'
            '   Catégorie: ${lieu2.categorie}\n'
            '   Favori: ${lieu2.estFavori ? "Oui" : "Non"}';
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR !\n\n$e';
      });
    }
  }

  // TEST 4 : Récupérer lieux par ville
  Future<void> _test4RecupererLieux() async {
    try {
      final villes = await villeService.obtenirToutesVilles();
      
      if (villes.isEmpty) {
        setState(() {
          _resultat = '⚠️ Aucune ville trouvée.';
        });
        return;
      }

      final villeId = villes.first.id!;
      final lieux = await lieuService.obtenirLieuxParVille(villeId);

      if (lieux.isEmpty) {
        setState(() {
          _resultat = '⚠️ Aucun lieu trouvé pour ${villes.first.nom}.\n\n'
              'Ajoutez d\'abord des lieux (Test 3)';
        });
        return;
      }

      String resultat = '✅ SUCCÈS !\n\n';
      resultat += 'Ville: ${villes.first.nom}\n';
      resultat += 'Nombre de lieux: ${lieux.length}\n\n';

      for (var lieu in lieux) {
        resultat += '📍 ${lieu.nom}\n';
        resultat += '   Catégorie: ${lieu.categorie}\n';
        resultat += '   Note: ${lieu.noteMoyenne.toStringAsFixed(1)}⭐\n';
        resultat += '   Favori: ${lieu.estFavori ? "❤️" : "🤍"}\n\n';
      }

      setState(() {
        _resultat = resultat;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR !\n\n$e';
      });
    }
  }

  // TEST 5 : Ajouter un commentaire
  Future<void> _test5AjouterCommentaire() async {
    try {
      final villes = await villeService.obtenirToutesVilles();
      if (villes.isEmpty) {
        setState(() {
          _resultat = '⚠️ Ajoutez d\'abord une ville';
        });
        return;
      }

      final lieux = await lieuService.obtenirLieuxParVille(villes.first.id!);
      if (lieux.isEmpty) {
        setState(() {
          _resultat = '⚠️ Ajoutez d\'abord des lieux';
        });
        return;
      }

      final commentaire = Commentaire(
        lieuId: lieux.first.id!,
        texte: 'Magnifique endroit ! Je recommande vivement.',
        note: 5,
      );

      final id = await commentaireService.ajouterCommentaire(commentaire);

      // Récupérer le lieu mis à jour (avec la nouvelle note moyenne)
      final lieuMisAJour = await lieuService.obtenirLieuParId(lieux.first.id!);

      setState(() {
        _resultat = '✅ SUCCÈS !\n\n'
            'Commentaire ajouté (ID: $id)\n\n'
            'Lieu: ${lieux.first.nom}\n'
            'Note: ${commentaire.note}⭐\n'
            'Commentaire: "${commentaire.texte}"\n\n'
            'Note moyenne du lieu: ${lieuMisAJour?.noteMoyenne.toStringAsFixed(1)}⭐';
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR !\n\n$e';
      });
    }
  }

  // TEST 6 : Test complet
  Future<void> _test6Complet() async {
    try {
      String log = '🚀 DÉMARRAGE TEST COMPLET\n\n';

      // 1. Ajouter une ville
      log += '1️⃣ Ajout d\'une ville...\n';
      final ville = Ville(
        nom: 'Lyon',
        pays: 'France',
        latitude: 45.7640,
        longitude: 4.8357,
        temperatureActuelle: 14.0,
        etatTemps: 'Nuageux',
      );
      final villeId = await villeService.ajouterVille(ville);
      log += '   ✅ Ville ajoutée (ID: $villeId)\n\n';

      // 2. Ajouter un lieu
      log += '2️⃣ Ajout d\'un lieu...\n';
      final lieu = Lieu(
        villeId: villeId,
        nom: 'Parc de la Tête d\'Or',
        description: 'Grand parc urbain',
        categorie: 'Parc',
        latitude: 45.7772,
        longitude: 4.8542,
      );
      final lieuId = await lieuService.ajouterLieu(lieu);
      log += '   ✅ Lieu ajouté (ID: $lieuId)\n\n';

      // 3. Ajouter des commentaires
      log += '3️⃣ Ajout de commentaires...\n';
      await commentaireService.ajouterCommentaire(
        Commentaire(lieuId: lieuId, texte: 'Super parc !', note: 5),
      );
      await commentaireService.ajouterCommentaire(
        Commentaire(lieuId: lieuId, texte: 'Très agréable', note: 4),
      );
      log += '   ✅ Commentaires ajoutés\n\n';

      // 4. Vérifications
      log += '4️⃣ Vérifications...\n';
      final villesCount = (await villeService.obtenirToutesVilles()).length;
      final lieuxCount = (await lieuService.obtenirLieuxParVille(villeId)).length;
      final commentairesCount = (await commentaireService.obtenirCommentairesParLieu(lieuId)).length;
      final lieuMisAJour = await lieuService.obtenirLieuParId(lieuId);

      log += '   ✅ Villes: $villesCount\n';
      log += '   ✅ Lieux: $lieuxCount\n';
      log += '   ✅ Commentaires: $commentairesCount\n';
      log += '   ✅ Note moyenne: ${lieuMisAJour?.noteMoyenne.toStringAsFixed(1)}⭐\n\n';

      log += '🎉 TEST COMPLET RÉUSSI !';

      setState(() {
        _resultat = log;
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR DANS LE TEST COMPLET !\n\n$e';
      });
    }
  }

  // Supprimer toutes les données
  Future<void> _supprimerTout() async {
    try {
      final villes = await villeService.obtenirToutesVilles();
      
      for (var ville in villes) {
        await villeService.supprimerVille(ville.id!);
      }

      setState(() {
        _resultat = '✅ Toutes les données ont été supprimées !\n\n'
            '${villes.length} ville(s) supprimée(s)';
      });
    } catch (e) {
      setState(() {
        _resultat = '❌ ERREUR lors de la suppression !\n\n$e';
      });
    }
  }
}