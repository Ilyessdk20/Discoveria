import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/lieu.dart';
import '../models/ville.dart';

class WebStorageService {
  static const String _lieuxKey = 'lieux';

  Future<List<Lieu>> obtenirLieux() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lieuxJson = prefs.getString(_lieuxKey);
      
      if (lieuxJson == null) {
        return [];
      }
      
      final List<dynamic> decoded = jsonDecode(lieuxJson);
      return decoded.map((lieu) => Lieu.fromMap(lieu as Map<String, dynamic>)).toList();
    } catch (ex) {
      print('Erreur lecture lieux: $ex');
      return [];
    }
  }

  Future<List<Lieu>> obtenirLieuxParVille(int villeId) async {
    final lieux = await obtenirLieux();
    return lieux.where((lieu) => lieu.villeId == villeId).toList();
  }

  Future<void> ajouterLieu(Lieu lieu) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lieux = await obtenirLieux();
      
      final newLieu = Lieu(
        id: lieu.id ?? DateTime.now().millisecondsSinceEpoch,
        villeId: lieu.villeId,
        nom: lieu.nom,
        description: lieu.description,
        categorie: lieu.categorie,
        latitude: lieu.latitude,
        longitude: lieu.longitude,
        imageUrl: lieu.imageUrl,
        noteMoyenne: lieu.noteMoyenne,
        estFavori: lieu.estFavori,
        dateAjout: lieu.dateAjout,
      );
      
      lieux.add(newLieu);
      
      final encoded = jsonEncode(lieux.map((l) => l.toMap()).toList());
      await prefs.setString(_lieuxKey, encoded);
    } catch (ex) {
      print('Erreur ajout lieu: $ex');
    }
  }

  Future<void> basculerFavori(int lieuId, bool favori) async {
    try {
      final lieux = await obtenirLieux();
      final index = lieux.indexWhere((l) => l.id == lieuId);
      if (index != -1) {
        final ancien = lieux[index];
        lieux[index] = Lieu(
          id: ancien.id,
          villeId: ancien.villeId,
          nom: ancien.nom,
          description: ancien.description,
          categorie: ancien.categorie,
          latitude: ancien.latitude,
          longitude: ancien.longitude,
          imageUrl: ancien.imageUrl,
          noteMoyenne: ancien.noteMoyenne,
          estFavori: favori,
          dateAjout: ancien.dateAjout,
        );
        
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(lieux.map((l) => l.toMap()).toList());
        await prefs.setString(_lieuxKey, encoded);
      }
    } catch (ex) {
      print('Erreur basculer favori: $ex');
    }
  }

  Future<void> mettreAJourLieu(Lieu lieu) async {
    try {
      final lieux = await obtenirLieux();
      final index = lieux.indexWhere((l) => l.id == lieu.id);
      if (index != -1) {
        lieux[index] = lieu;
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(lieux.map((l) => l.toMap()).toList());
        await prefs.setString(_lieuxKey, encoded);
      }
    } catch (ex) {
      print('Erreur mettre à jour lieu: $ex');
    }
  }

  Future<void> supprimerLieu(int lieuId) async {
    try {
      final lieux = await obtenirLieux();
      lieux.removeWhere((l) => l.id == lieuId);
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(lieux.map((l) => l.toMap()).toList());
      await prefs.setString(_lieuxKey, encoded);
    } catch (ex) {
      print('Erreur supprimer lieu: $ex');
    }
  }

  // ----- Villes -----
  static const String _villesKey = 'villes';
  static const String _villeFavoriteKey = 'ville_favorite';

  Future<List<Ville>> obtenirVilles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final villesJson = prefs.getString(_villesKey);
      if (villesJson == null) return [];
      final List<dynamic> decoded = jsonDecode(villesJson);
      return decoded.map((v) => Ville.fromMap(v as Map<String, dynamic>)).toList();
    } catch (ex) {
      print('Erreur lecture villes: $ex');
      return [];
    }
  }

  Future<void> ajouterVille(Ville ville) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final villes = await obtenirVilles();
      final newVille = Ville(
        id: ville.id ?? DateTime.now().millisecondsSinceEpoch,
        nom: ville.nom,
        pays: ville.pays,
        latitude: ville.latitude,
        longitude: ville.longitude,
        temperatureActuelle: ville.temperatureActuelle,
        temperatureMin: ville.temperatureMin,
        temperatureMax: ville.temperatureMax,
        etatTemps: ville.etatTemps,
        estFavorite: ville.estFavorite,
      );
      villes.add(newVille);
      final encoded = jsonEncode(villes.map((v) => v.toMap()).toList());
      await prefs.setString(_villesKey, encoded);
    } catch (ex) {
      print('Erreur ajout ville: $ex');
    }
  }

  Future<void> definirVilleFavorite(Ville ville) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(ville.toMap());
      await prefs.setString(_villeFavoriteKey, encoded);
    } catch (ex) {
      print('Erreur définir ville favorite: $ex');
    }
  }

  Future<Ville?> obtenirVilleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_villeFavoriteKey);
      if (s == null) return null;
      return Ville.fromMap(jsonDecode(s) as Map<String, dynamic>);
    } catch (ex) {
      print('Erreur lecture ville favorite: $ex');
      return null;
    }
  }
}
