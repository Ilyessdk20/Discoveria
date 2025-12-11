class Commentaire {
  final int? id;
  final int lieuId;
  final String texte;
  final int note; // Entre 1 et 5
  final DateTime dateCreation;

  Commentaire({
    this.id,
    required this.lieuId,
    required this.texte,
    required this.note,
    DateTime? dateCreation,
  }) : this.dateCreation = dateCreation ?? DateTime.now();

  // Convertir en Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lieu_id': lieuId,
      'texte': texte,
      'note': note,
      'date_creation': dateCreation.toIso8601String(),
    };
  }

  // Créer depuis Map
  factory Commentaire.fromMap(Map<String, dynamic> map) {
    return Commentaire(
      id: map['id'],
      lieuId: map['lieu_id'],
      texte: map['texte'],
      note: map['note'],
      dateCreation: DateTime.parse(map['date_creation']),
    );
  }

  @override
  String toString() {
    return 'Commentaire{id: $id, note: $note, texte: $texte}';
  }
}