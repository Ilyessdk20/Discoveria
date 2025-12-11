import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  bool _modeSombre = false;
  String? _derniereRecherche;
  List<String> _dernieresRecherches = [];

  bool get modeSombre => _modeSombre;
  String? get derniereRecherche => _derniereRecherche;
  List<String> get dernieresRecherches => _dernieresRecherches;

  // Charger les préférences
  Future<void> chargerPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _modeSombre = prefs.getBool('mode_sombre') ?? false;
      _derniereRecherche = prefs.getString('derniere_recherche');
      _dernieresRecherches = prefs.getStringList('dernieres_recherches') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement préférences: $e');
    }
  }

  // Basculer mode sombre
  Future<void> basculerModeSombre() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _modeSombre = !_modeSombre;
      await prefs.setBool('mode_sombre', _modeSombre);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  // Enregistrer dernière recherche
  Future<void> enregistrerRecherche(String recherche) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _derniereRecherche = recherche;
      await prefs.setString('derniere_recherche', recherche);

      // Ajouter aux dernières recherches
      if (!_dernieresRecherches.contains(recherche)) {
        _dernieresRecherches.insert(0, recherche);
        if (_dernieresRecherches.length > 5) {
          _dernieresRecherches.removeLast();
        }
        await prefs.setStringList('dernieres_recherches', _dernieresRecherches);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  // Effacer les dernières recherches
  Future<void> effacerRecherches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dernieresRecherches.clear();
      await prefs.remove('dernieres_recherches');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }
}