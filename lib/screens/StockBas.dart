import 'package:flutter/material.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';

class StockBas extends StatefulWidget {
  @override
  _StockBasState createState() => _StockBasState();
}

class _StockBasState extends State<StockBas> {
  final ArticleDao _articleDao = ArticleDao(DatabaseHelper());
  List<Article> _articles = [];
  bool _isLoading = true;
  final int _seuilStockBas = 10;

  @override
  void initState() {
    super.initState();
    _loadLowStockArticles();
  }

  Future<void> _loadLowStockArticles() async {
    try {
      final allArticles = await _articleDao.getAllArticles();
      setState(() {
        _articles = allArticles.where((a) => a.quantite < _seuilStockBas).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Bas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLowStockArticles,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _articles.isEmpty
          ? Center(child: Text('Aucun article en stock bas'))
          : ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return ListTile(
            title: Text(article.designation),
            subtitle: Text('Quantité: ${article.quantite}'),
            trailing: Icon(Icons.warning, color: Colors.red),
          );
        },
      ),
    );
  }
}