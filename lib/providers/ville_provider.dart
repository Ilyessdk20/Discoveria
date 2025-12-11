import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/database_helper.dart';
import 'web_storage_service.dart';
import '../models/ville.dart';

class VilleProvider extends ChangeNotifier {
  final dbHelper = DatabaseHelper.instance;
  
  Ville? _villeFavorite;
  List<Ville> _villes = [];
  bool _isLoading = false;

  Ville? get villeFavorite => _villeFavorite;
  List<Ville> get villes => _villes;
  bool get isLoading => _isLoading;


  Future<int> ajouterVille(Ville ville) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.ajouterVille(ville);
        final id = ville.id ?? DateTime.now().millisecondsSinceEpoch;
        final nouvelleVille = ville.copyWith(id: id);
        _villes.add(nouvelleVille);
        notifyListeners();
        return id;
      }

      final db = await dbHelper.database;
      final villeId = await db.insert('ville', ville.toMap());

      final nouvelleVille = ville.copyWith(id: villeId);
      _villes.add(nouvelleVille);
      notifyListeners();

      return villeId;
    } catch (e) {
      debugPrint('Erreur ajout ville: $e');
      rethrow;
    }
  }

  Future<void> chargerVilleFavorite() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final fav = await web.obtenirVilleFavorite();
        if (fav != null) {
          _villeFavorite = fav;
        } else {
          _villes = await web.obtenirVilles();
          if (_villes.isNotEmpty) _villeFavorite = _villes.first;
        }
      } else {
        final db = await dbHelper.database;
        final List<Map<String, dynamic>> maps = await db.query(
          'ville',
          where: 'est_favorite = ?',
          whereArgs: [1],
          limit: 1,
        );

        if (maps.isNotEmpty) {
          _villeFavorite = Ville.fromMap(maps.first);
        } else {
          // Charger toutes les villes
          final allMaps = await db.query('ville');
          _villes = List.generate(allMaps.length, (i) => Ville.fromMap(allMaps[i]));

          if (_villes.isNotEmpty) {
            _villeFavorite = _villes.first;
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement ville: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Ville>> obtenirToutesVilles() async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        _villes = await web.obtenirVilles();
        notifyListeners();
        return _villes;
      }

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('ville');
      _villes = List.generate(maps.length, (i) => Ville.fromMap(maps[i]));
      notifyListeners();
      return _villes;
    } catch (e) {
      debugPrint('Erreur: $e');
      return [];
    }
  }

  Future<void> definirVilleFavorite(int villeId) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final v = _villes.firstWhere((v) => v.id == villeId, orElse: () => _villes.first);
        await web.definirVilleFavorite(v);
        _villeFavorite = v;
        notifyListeners();
        return;
      }

      final db = await dbHelper.database;

      // Désactiver toutes les favorites
      await db.update('ville', {'est_favorite': 0});

      // Activer la nouvelle favorite
      await db.update(
        'ville',
        {'est_favorite': 1},
        where: 'id = ?',
        whereArgs: [villeId],
      );

      _villeFavorite = _villes.firstWhere((v) => v.id == villeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<List<Ville>> rechercherVilleParNom(String nom) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final all = await web.obtenirVilles();
        return all.where((v) => v.nom.toLowerCase().contains(nom.toLowerCase())).toList();
      }

      final db = await dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'ville',
        where: 'nom LIKE ?',
        whereArgs: ['%$nom%'],
      );
      return List.generate(maps.length, (i) => Ville.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Erreur: $e');
      return [];
    }
  }

  Future<void> mettreAJourVille(Ville ville) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        await web.ajouterVille(ville);
        final index = _villes.indexWhere((v) => v.id == ville.id);
        if (index != -1) _villes[index] = ville;
        if (_villeFavorite?.id == ville.id) _villeFavorite = ville;
        notifyListeners();
        return;
      }

      final db = await dbHelper.database;
      await db.update(
        'ville',
        ville.toMap(),
        where: 'id = ?',
        whereArgs: [ville.id],
      );

      final index = _villes.indexWhere((v) => v.id == ville.id);
      if (index != -1) {
        _villes[index] = ville;
      }
      
      if (_villeFavorite?.id == ville.id) {
        _villeFavorite = ville;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  Future<void> supprimerVille(int villeId) async {
    try {
      if (kIsWeb) {
        final web = WebStorageService();
        final villes = await web.obtenirVilles();
        villes.removeWhere((v) => v.id == villeId);
        // save back
        for (var v in villes) {
          await web.ajouterVille(v);
        }
        _villes.removeWhere((v) => v.id == villeId);
        if (_villeFavorite?.id == villeId) {
          _villeFavorite = _villes.isNotEmpty ? _villes.first : null;
        }
        notifyListeners();
        return;
      }

      final db = await dbHelper.database;
      await db.delete(
        'ville',
        where: 'id = ?',
        whereArgs: [villeId],
      );

      _villes.removeWhere((v) => v.id == villeId);
      
      if (_villeFavorite?.id == villeId) {
        _villeFavorite = _villes.isNotEmpty ? _villes.first : null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }
}