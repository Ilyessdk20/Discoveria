import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/ville.dart';

class VilleService {
  final dbHelper = DatabaseHelper.instance;

  // CREATE - Ajouter une ville
  Future<int> ajouterVille(Ville ville) async {
    final db = await dbHelper.database;
    return await db.insert('ville', ville.toMap());
  }

  // READ - Récupérer toutes les villes
  Future<List<Ville>> obtenirToutesVilles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('ville');
    
    return List.generate(maps.length, (i) {
      return Ville.fromMap(maps[i]);
    });
  }

  // READ - Récupérer une ville par ID
  Future<Ville?> obtenirVilleParId(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ville',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Ville.fromMap(maps.first);
    }
    return null;
  }

  // READ - Récupérer la ville favorite
  Future<Ville?> obtenirVilleFavorite() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ville',
      where: 'est_favorite = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Ville.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE - Mettre à jour une ville
  Future<int> mettreAJourVille(Ville ville) async {
    final db = await dbHelper.database;
    return await db.update(
      'ville',
      ville.toMap(),
      where: 'id = ?',
      whereArgs: [ville.id],
    );
  }

  // UPDATE - Définir comme ville favorite
  Future<void> definirVilleFavorite(int villeId) async {
    final db = await dbHelper.database;
    
    // D'abord, retirer le statut favori de toutes les villes
    await db.update(
      'ville',
      {'est_favorite': 0},
    );
    
    // Puis définir la ville choisie comme favorite
    await db.update(
      'ville',
      {'est_favorite': 1},
      where: 'id = ?',
      whereArgs: [villeId],
    );
  }

  // DELETE - Supprimer une ville
  Future<int> supprimerVille(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'ville',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Rechercher une ville par nom
  Future<List<Ville>> rechercherVilleParNom(String nom) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ville',
      where: 'nom LIKE ?',
      whereArgs: ['%$nom%'],
    );
    
    return List.generate(maps.length, (i) {
      return Ville.fromMap(maps[i]);
    });
  }
}