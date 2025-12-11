class Commentaire {
  final int? id;
  final int lieuId;
  final String texte;
  final int note;
  final DateTime dateCreation;

  Commentaire({
    this.id,
    required this.lieuId,
    required this.texte,
    required this.note,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

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

  // ⬇️ AJOUTE CETTE MÉTHODE
  Commentaire copyWith({
    int? id,
    int? lieuId,
    String? texte,
    int? note,
    DateTime? dateCreation,
  }) {
    return Commentaire(
      id: id ?? this.id,
      lieuId: lieuId ?? this.lieuId,
      texte: texte ?? this.texte,
      note: note ?? this.note,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }

  @override
  String toString() {
    return 'Commentaire{id: $id, note: $note, texte: $texte}';
  }
}