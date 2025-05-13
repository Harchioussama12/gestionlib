class Transaction {
  final int? id;
  final DateTime date;
  final double montantTotal;
  final List<TransactionItem> items;

  Transaction({
    this.id,
    required this.date,
    required this.montantTotal,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'montantTotal': montantTotal,
    };
  }
}

class TransactionItem {
  final int? id;
  final int transactionId;
  final int articleId;
  final String designation;
  final double prixUnitaire;
  final int quantite;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.articleId,
    required this.designation,
    required this.prixUnitaire,
    required this.quantite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transactionId': transactionId,
      'articleId': articleId,
      'designation': designation,
      'prixUnitaire': prixUnitaire,
      'quantite': quantite,
    };
  }
}