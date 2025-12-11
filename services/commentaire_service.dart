import '../database/database.dart';
import '../models/commentaire.dart';

class CommentaireService {
  final dbHelper = DatabaseHelper.instance;

  // CREATE - Ajouter un commentaire
  Future<int> ajouterCommentaire(Commentaire commentaire) async {
    final db = await dbHelper.database;
    
    // Insérer le commentaire
    final id = await db.insert('commentaire', commentaire.toMap());
    
    // Recalculer la note moyenne du lieu
    await _recalculerNoteMoyenne(commentaire.lieuId);
    
    return id;
  }

  // READ - Récupérer tous les commentaires d'un lieu
  Future<List<Commentaire>> obtenirCommentairesParLieu(int lieuId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'commentaire',
      where: 'lieu_id = ?',
      whereArgs: [lieuId],
      orderBy: 'date_creation DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Commentaire.fromMap(maps[i]);
    });
  }

  // UPDATE - Mettre à jour un commentaire
  Future<int> mettreAJourCommentaire(Commentaire commentaire) async {
    final db = await dbHelper.database;
    
    final result = await db.update(
      'commentaire',
      commentaire.toMap(),
      where: 'id = ?',
      whereArgs: [commentaire.id],
    );
    
    // Recalculer la note moyenne
    await _recalculerNoteMoyenne(commentaire.lieuId);
    
    return result;
  }

  // DELETE - Supprimer un commentaire
  Future<int> supprimerCommentaire(int id, int lieuId) async {
    final db = await dbHelper.database;
    
    final result = await db.delete(
      'commentaire',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    // Recalculer la note moyenne
    await _recalculerNoteMoyenne(lieuId);
    
    return result;
  }

  // Recalculer la note moyenne d'un lieu
  Future<void> _recalculerNoteMoyenne(int lieuId) async {
    final db = await dbHelper.database;
    
    // Calculer la moyenne des notes
    final result = await db.rawQuery(
      'SELECT AVG(note) as moyenne FROM commentaire WHERE lieu_id = ?',
      [lieuId],
    );
    
    final moyenne = result.first['moyenne'] as double? ?? 0;
    
    // Mettre à jour la note moyenne du lieu
    await db.update(
      'lieu',
      {'note_moyenne': moyenne},
      where: 'id = ?',
      whereArgs: [lieuId],
    );
  }

  // Compter les commentaires d'un lieu
  Future<int> compterCommentaires(int lieuId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM commentaire WHERE lieu_id = ?',
      [lieuId],
    );
    return result.first['count'] as int? ?? 0;
  }
}