import 'package:flutter/material.dart';
import 'package:mylib/database/database_helper.dart';
import 'ajouterArticle.dart';
import 'modifierArticle.dart';
import 'supprimerArticle.dart';
import 'StockBas.dart';
import 'MouvementStock.dart';
import 'package:mylib/dao/article_dao.dart';

class Gerant extends StatelessWidget {
  final ArticleDao articleDao = ArticleDao(DatabaseHelper());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Gérant'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMenuItem(
              context: context,
              icon: Icons.add,
              color: Colors.green,
              text: 'Ajouter un article',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AjouterArticle()),
              ),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.edit,
              color: Colors.blue,
              text: 'Modifier un article',
              onTap: () async {
                final articles = await articleDao.getAllArticles();
                if (articles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModifierArticle(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun article à modifier')),
                  );
                }
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.delete,
              color: Colors.red,
              text: 'Supprimer un article',
              onTap: () async {
                final articles = await articleDao.getAllArticles();
                if (articles.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SupprimerArticle(),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun article à supprimer')),
                  );
                }
              },
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.warning,
              color: Colors.orange,
              text: 'Stock bas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StockBas()),
              ),
            ),
            _buildMenuItem(
              context: context,
              icon: Icons.compare_arrows,
              color: Colors.purple,
              text: 'Mouvements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MouvementStock()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          text,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}