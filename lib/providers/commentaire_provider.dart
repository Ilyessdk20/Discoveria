import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/commentaire.dart';

class CommentaireProvider extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  
  List<Commentaire> _commentaires = [];
  bool _isLoading = false;

  List<Commentaire> get commentaires => _commentaires;
  bool get isLoading => _isLoading;

  // Ajouter un commentaire
  Future<int> ajouterCommentaire(Commentaire commentaire) async {
    try {
      final db = await dbHelper.database;
      final commentaireId = await db.insert('commentaire', commentaire.toMap());

      // Recalculer la note moyenne du lieu
      await _recalculerNoteMoyenne(commentaire.lieuId);

      // ✅ MAINTENANT copyWith() FONCTIONNE
      final nouveauCommentaire = commentaire.copyWith(id: commentaireId);
      _commentaires.add(nouveauCommentaire);
      notifyListeners();

      return commentaireId;
    } catch (e) {
      debugPrint('Erreur ajout commentaire: $e');
      rethrow;
    }
  }

  // Charger les commentaires d'un lieu
  Future<void> chargerCommentairesParLieu(int lieuId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'commentaire',
        where: 'lieu_id = ?',
        whereArgs: [lieuId],
        orderBy: 'date_creation DESC',
      );

      _commentaires = List.generate(maps.length, (i) => Commentaire.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Erreur chargement commentaires: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Mettre à jour un commentaire
  Future<void> mettreAJourCommentaire(Commentaire commentaire) async {
    try {
      final db = await dbHelper.database;
      await db.update(
        'commentaire',
        commentaire.toMap(),
        where: 'id = ?',
        whereArgs: [commentaire.id],
      );

      await _recalculerNoteMoyenne(commentaire.lieuId);

      final index = _commentaires.indexWhere((c) => c.id == commentaire.id);
      if (index != -1) {
        _commentaires[index] = commentaire;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur mise à jour commentaire: $e');
    }
  }

  // Supprimer un commentaire
  Future<void> supprimerCommentaire(int commentaireId, int lieuId) async {
    try {
      final db = await dbHelper.database;
      await db.delete(
        'commentaire',
        where: 'id = ?',
        whereArgs: [commentaireId],
      );

      await _recalculerNoteMoyenne(lieuId);

      _commentaires.removeWhere((c) => c.id == commentaireId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur suppression commentaire: $e');
    }
  }

  // Recalculer la note moyenne d'un lieu
  Future<void> _recalculerNoteMoyenne(int lieuId) async {
    try {
      final db = await dbHelper.database;

      final result = await db.rawQuery(
        'SELECT AVG(note) as moyenne FROM commentaire WHERE lieu_id = ?',
        [lieuId],
      );

      final moyenne = result.first['moyenne'] as double? ?? 0;

      await db.update(
        'lieu',
        {'note_moyenne': moyenne},
        where: 'id = ?',
        whereArgs: [lieuId],
      );
    } catch (e) {
      debugPrint('Erreur recalcul note moyenne: $e');
    }
  }

  // Compter le nombre de commentaires d'un lieu
  Future<int> compterCommentaires(int lieuId) async {
    try {
      final db = await dbHelper.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM commentaire WHERE lieu_id = ?',
        [lieuId],
      );
      return result.first['count'] as int? ?? 0;
    } catch (e) {
      debugPrint('Erreur comptage commentaires: $e');
      return 0;
    }
  }
}