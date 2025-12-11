class Lieu {
  final int? id;
  final int villeId;
  final String nom;
  final String? description;
  final String categorie; // Restaurant, Musée, Parc, etc.
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final double noteMoyenne;
  final bool estFavori;
  final DateTime dateAjout;

  Lieu({
    this.id,
    required this.villeId,
    required this.nom,
    this.description,
    required this.categorie,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.noteMoyenne = 0,
    this.estFavori = false,
    DateTime? dateAjout,
  }) : this.dateAjout = dateAjout ?? DateTime.now();

  // Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ville_id': villeId,
      'nom': nom,
      'description': description,
      'categorie': categorie,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'note_moyenne': noteMoyenne,
      'est_favori': estFavori ? 1 : 0,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  // Créer depuis Map
  factory Lieu.fromMap(Map<String, dynamic> map) {
    return Lieu(
      id: map['id'],
      villeId: map['ville_id'],
      nom: map['nom'],
      description: map['description'],
      categorie: map['categorie'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      imageUrl: map['image_url'],
      noteMoyenne: map['note_moyenne'] ?? 0,
      estFavori: map['est_favori'] == 1,
      dateAjout: DateTime.parse(map['date_ajout']),
    );
  }

  // Copier avec modifications
  Lieu copyWith({
    int? id,
    int? villeId,
    String? nom,
    String? description,
    String? categorie,
    double? latitude,
    double? longitude,
    String? imageUrl,
    double? noteMoyenne,
    bool? estFavori,
    DateTime? dateAjout,
  }) {
    return Lieu(
      id: id ?? this.id,
      villeId: villeId ?? this.villeId,
      nom: nom ?? this.nom,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      noteMoyenne: noteMoyenne ?? this.noteMoyenne,
      estFavori: estFavori ?? this.estFavori,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }

  @override
  String toString() {
    return 'Lieu{id: $id, nom: $nom, categorie: $categorie, ville: $villeId}';
  }
}