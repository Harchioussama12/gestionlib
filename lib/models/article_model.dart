class Article {
  final int? id;
  final String codeBarre;
  final String designation;
  final double prix;
  final int quantite;
  final DateTime dateCreation;

  Article({
    this.id,
    required this.codeBarre,
    required this.designation,
    required this.prix,
    required this.quantite,
    required this.dateCreation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codeBarre': codeBarre,
      'designation': designation,
      'prix': prix,
      'quantite': quantite,
      'dateCreation': dateCreation.toIso8601String(),
    };
  }

  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      id: map['id'],
      codeBarre: map['codeBarre'],
      designation: map['designation'],
      prix: map['prix'],
      quantite: map['quantite'],
      dateCreation: DateTime.parse(map['dateCreation']),
    );
  }

  Article copyWith({
    int? id,
    String? codeBarre,
    String? designation,
    double? prix,
    int? quantite,
    DateTime? dateCreation,
  }) {
    return Article(
      id: id ?? this.id,
      codeBarre: codeBarre ?? this.codeBarre,
      designation: designation ?? this.designation,
      prix: prix ?? this.prix,
      quantite: quantite ?? this.quantite,
      dateCreation: dateCreation ?? this.dateCreation,
    );
  }
}