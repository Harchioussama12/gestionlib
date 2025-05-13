import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/transaction_model.dart';

class TransactionDao {
  final DatabaseHelper dbHelper;

  TransactionDao(this.dbHelper);

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await dbHelper.database;
    return await db.transaction((txn) async {
      final transactionId = await txn.insert('transactions', {
        'date': transaction.date.toIso8601String(),
        'montantTotal': transaction.montantTotal,
      });

      for (final item in transaction.items) {
        await txn.insert('transaction_items', {
          'transactionId': transactionId,
          'articleId': item.articleId,
          'designation': item.designation,
          'prixUnitaire': item.prixUnitaire,
          'quantite': item.quantite,
        });
      }

      return transactionId;
    });
  }

  Future<List<Transaction>> getAllTransactions() async {
    final db = await dbHelper.database;
    final transactions = await db.query('transactions');
    final List<Transaction> results = [];

    for (final trans in transactions) {
      final items = await db.query(
        'transaction_items',
        where: 'transactionId = ?',
        whereArgs: [trans['id']],
      );

      results.add(Transaction(
        id: trans['id'] as int,
        date: DateTime.parse(trans['date'] as String),
        montantTotal: trans['montantTotal'] as double,
        items: items.map((item) => TransactionItem(
          id: item['id'] as int,
          transactionId: item['transactionId'] as int,
          articleId: item['articleId'] as int,
          designation: item['designation'] as String,
          prixUnitaire: item['prixUnitaire'] as double,
          quantite: item['quantite'] as int,
        )).toList(),
      ));
    }

    return results;
  }
}