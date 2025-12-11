import 'package:sqflite/sqflite.dart';
import '../database/database.dart';
import '../models/lieu.dart';

class LieuService {
  final dbHelper = DatabaseHelper.instance;

  // CREATE - Ajouter un lieu
  Future<int> ajouterLieu(Lieu lieu) async {
    final db = await dbHelper.database;
    return await db.insert('lieu', lieu.toMap());
  }

  // READ - Récupérer tous les lieux d'une ville
  Future<List<Lieu>> obtenirLieuxParVille(int villeId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lieu',
      where: 'ville_id = ?',
      whereArgs: [villeId],
      orderBy: 'date_ajout DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Lieu.fromMap(maps[i]);
    });
  }

  // READ - Récupérer un lieu par ID
  Future<Lieu?> obtenirLieuParId(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lieu',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Lieu.fromMap(maps.first);
    }
    return null;
  }

  // READ - Récupérer les lieux favoris
  Future<List<Lieu>> obtenirLieuxFavoris() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lieu',
      where: 'est_favori = ?',
      whereArgs: [1],
    );
    
    return List.generate(maps.length, (i) {
      return Lieu.fromMap(maps[i]);
    });
  }

  // READ - Récupérer les lieux par catégorie
  Future<List<Lieu>> obtenirLieuxParCategorie(int villeId, String categorie) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'lieu',
      where: 'ville_id = ? AND categorie = ?',
      whereArgs: [villeId, categorie],
    );
    
    return List.generate(maps.length, (i) {
      return Lieu.fromMap(maps[i]);
    });
  }

  // UPDATE - Mettre à jour un lieu
  Future<int> mettreAJourLieu(Lieu lieu) async {
    final db = await dbHelper.database;
    return await db.update(
      'lieu',
      lieu.toMap(),
      where: 'id = ?',
      whereArgs: [lieu.id],
    );
  }

  // UPDATE - Basculer le statut favori
  Future<void> basculerFavori(int lieuId, bool estFavori) async {
    final db = await dbHelper.database;
    await db.update(
      'lieu',
      {'est_favori': estFavori ? 1 : 0},
      where: 'id = ?',
      whereArgs: [lieuId],
    );
  }

  // DELETE - Supprimer un lieu
  Future<int> supprimerLieu(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'lieu',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Compter les lieux d'une ville
  Future<int> compterLieuxParVille(int villeId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM lieu WHERE ville_id = ?',
      [villeId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}