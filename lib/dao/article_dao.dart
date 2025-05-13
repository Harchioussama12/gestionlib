import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';

class ArticleDao {
  final DatabaseHelper dbHelper;

  ArticleDao(this.dbHelper);

  Future<int> insertArticle(Article article) async {
    final db = await dbHelper.database;
    return await db.insert('articles', article.toMap());
  }

  Future<List<Article>> getAllArticles() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('articles');
    return List.generate(maps.length, (i) => Article.fromMap(maps[i]));
  }

  Future<Article?> getArticleById(int id) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Article.fromMap(maps.first);
    return null;
  }

  Future<int> updateArticle(Article article) async {
    final db = await dbHelper.database;
    return await db.update(
      'articles',
      article.toMap(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<int> deleteArticle(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'articles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> enregistrerAchat(int articleId, int quantite) async {
    final db = await dbHelper.database;
    return await db.insert('achats', {
      'articleId': articleId,
      'quantite': quantite,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<int> enregistrerVente(int articleId, int quantite, int? transactionId) async {
    final db = await dbHelper.database;
    return await db.insert('ventes', {
      'articleId': articleId,
      'quantite': quantite,
      'date': DateTime.now().toIso8601String(),
      'transactionId': transactionId,
    });
  }

  Future<List<Map<String, dynamic>>> getMouvementsArticle(int articleId) async {
    final db = await dbHelper.database;

    final achats = await db.query(
      'achats',
      where: 'articleId = ?',
      whereArgs: [articleId],
    );

    final ventes = await db.query(
      'ventes',
      where: 'articleId = ?',
      whereArgs: [articleId],
    );

    final mouvements = [
    ...achats.map((a) => {...a, 'type': 'achat'}),
    ...ventes.map((v) => {...v, 'type': 'vente'},
    )];

    mouvements.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));

    return mouvements;
  }

  Future<int> getTotalAchats(int articleId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantite) as total FROM achats WHERE articleId = ?',
      [articleId],
    );
    return result.first['total'] as int? ?? 0;
  }

  Future<int> getTotalVentes(int articleId) async {
    final db = await dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(quantite) as total FROM ventes WHERE articleId = ?',
      [articleId],
    );
    return result.first['total'] as int? ?? 0;
  }
}