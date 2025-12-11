import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/lieu.dart';
import 'web_storage_service.dart';

class LieuProvider extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  
  List<Lieu> _lieux = [];
  bool _isLoading = false;

  List<Lieu> get lieux => _lieux;
  bool get isLoading => _isLoading;

  // ========== MÉTHODES BASE DE DONNÉES (ex-Service) ==========

  Future<int> ajouterLieu(Lieu lieu) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.ajouterLieu(lieu);
        // reload local list
        _lieux = await web.obtenirLieux();
        notifyListeners();
        // return generated id if available
        final added = _lieux.isNotEmpty ? _lieux.last : null;
        return added?.id ?? 0;
      }

      final db = await dbHelper.database;
      final lieuId = await db.insert('lieu', lieu.toMap());

      final nouveauLieu = lieu.copyWith(id: lieuId);
      _lieux.add(nouveauLieu);
      notifyListeners();

      return lieuId;
    } catch (e) {
      debugPrint('Erreur ajout lieu: $e');
      rethrow;
    }
  }

  Future<void> chargerLieuxParVille(int villeId) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        final web = WebStorageService();
        _lieux = await web.obtenirLieuxParVille(villeId);
      } else {
        final db = await dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'lieu',
          where: 'ville_id = ?',
          whereArgs: [villeId],
          orderBy: 'date_ajout DESC',
        );

        _lieux = List.generate(maps.length, (i) => Lieu.fromMap(maps[i]));
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Lieu?> obtenirLieuParId(int lieuId) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final lieux = await web.obtenirLieux();
        final matches = lieux.where((l) => l.id == lieuId).toList();
        return matches.isNotEmpty ? matches.first : null;
      }

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'lieu',
        where: 'id = ?',
        whereArgs: [lieuId],
      );

      if (maps.isNotEmpty) {
        return Lieu.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      debugPrint('Erreur: $e');
      return null;
    }
  }

  Future<List<Lieu>> obtenirLieuxFavoris() async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final lieux = await web.obtenirLieux();
        return lieux.where((l) => l.estFavori == true).toList();
      }

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'lieu',
        where: 'est_favori = ?',
        whereArgs: [1],
      );

      return List.generate(maps.length, (i) => Lieu.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Erreur: $e');
      return [];
    }
  }

  Future<void> mettreAJourLieu(Lieu lieu) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.mettreAJourLieu(lieu);
        final index = _lieux.indexWhere((l) => l.id == lieu.id);
        if (index != -1) {
          _lieux[index] = lieu;
          notifyListeners();
        }
        return;
      }

      final db = await dbHelper.database;
      await db.update(
        'lieu',
        lieu.toMap(),
        where: 'id = ?',
        whereArgs: [lieu.id],
      );

      final index = _lieux.indexWhere((l) => l.id == lieu.id);
      if (index != -1) {
        _lieux[index] = lieu;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> basculerFavori(int lieuId, bool estFavori) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.basculerFavori(lieuId, estFavori);
        final index = _lieux.indexWhere((l) => l.id == lieuId);
        if (index != -1) {
          _lieux[index] = _lieux[index].copyWith(estFavori: estFavori);
          notifyListeners();
        }
        return;
      }

      final db = await dbHelper.database;
      await db.update(
        'lieu',
        {'est_favori': estFavori ? 1 : 0},
        where: 'id = ?',
        whereArgs: [lieuId],
      );

      final index = _lieux.indexWhere((l) => l.id == lieuId);
      if (index != -1) {
        _lieux[index] = _lieux[index].copyWith(estFavori: estFavori);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> supprimerLieu(int lieuId) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.supprimerLieu(lieuId);
        _lieux.removeWhere((l) => l.id == lieuId);
        notifyListeners();
        return;
      }

      final db = await dbHelper.database;
      await db.delete(
        'lieu',
        where: 'id = ?',
        whereArgs: [lieuId],
      );

      _lieux.removeWhere((l) => l.id == lieuId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<List<Lieu>> obtenirLieuxParCategorie(String categorie) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final lieux = await web.obtenirLieux();
        return lieux.where((l) => l.categorie == categorie).toList();
      }

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'lieu',
        where: 'categorie = ?',
        whereArgs: [categorie],
      );

      return List.generate(maps.length, (i) => Lieu.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Erreur: $e');
      return [];
    }
  }
}