class Ville {
  final int? id;
  final String nom;
  final String? pays;
  final double? latitude;
  final double? longitude;
  final double? temperatureMin;
  final double? temperatureMax;
  final double? temperatureActuelle;
  final String? etatTemps;
  final bool estFavorite;
  final DateTime dateAjout;

  Ville({
    this.id,
    required this.nom,
    this.pays,
    this.latitude,
    this.longitude,
    this.temperatureMin,
    this.temperatureMax,
    this.temperatureActuelle,
    this.etatTemps,
    this.estFavorite = false,
    DateTime? dateAjout,
  }) : this.dateAjout = dateAjout ?? DateTime.now();

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'pays': pays,
      'latitude': latitude,
      'longitude': longitude,
      'temperature_min': temperatureMin,
      'temperature_max': temperatureMax,
      'temperature_actuelle': temperatureActuelle,
      'etat_temps': etatTemps,
      'est_favorite': estFavorite ? 1 : 0,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  // Créer depuis Map (depuis SQLite)
  factory Ville.fromMap(Map<String, dynamic> map) {
    return Ville(
      id: map['id'],
      nom: map['nom'],
      pays: map['pays'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      temperatureMin: map['temperature_min'],
      temperatureMax: map['temperature_max'],
      temperatureActuelle: map['temperature_actuelle'],
      etatTemps: map['etat_temps'],
      estFavorite: map['est_favorite'] == 1,
      dateAjout: DateTime.parse(map['date_ajout']),
    );
  }

  // Créer une copie avec modifications
  Ville copyWith({
    int? id,
    String? nom,
    String? pays,
    double? latitude,
    double? longitude,
    double? temperatureMin,
    double? temperatureMax,
    double? temperatureActuelle,
    String? etatTemps,
    bool? estFavorite,
    DateTime? dateAjout,
  }) {
    return Ville(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      pays: pays ?? this.pays,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      temperatureActuelle: temperatureActuelle ?? this.temperatureActuelle,
      etatTemps: etatTemps ?? this.etatTemps,
      estFavorite: estFavorite ?? this.estFavorite,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  @override
  String toString() {
    return 'Ville{id: $id, nom: $nom, pays: $pays, estFavorite: $estFavorite}';
  }
}