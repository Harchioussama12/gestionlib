import 'package:flutter/material.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ModifierArticle extends StatefulWidget {
  final Article? articleInitial;

  const ModifierArticle({super.key, this.articleInitial});

  @override
  State<ModifierArticle> createState() => _ModifierArticleState();
}

class _ModifierArticleState extends State<ModifierArticle> {
  final _formKey = GlobalKey<FormState>();
  final _codeBarreController = TextEditingController();
  final _designationController = TextEditingController();
  final _prixController = TextEditingController();
  final _quantiteController = TextEditingController();

  final ArticleDao articleDao = ArticleDao(DatabaseHelper());
  Article? _articleCourant;
  bool _chargementEnCours = false;
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _initialiserDonnees();
    _initScanner();
  }

  void _initScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.all],
      autoStart: false,
    );
  }

  void _initialiserDonnees() {
    if (widget.articleInitial != null) {
      _articleCourant = widget.articleInitial;
      _remplirChamps(widget.articleInitial!);
    }
  }

  void _remplirChamps(Article article) {
    _codeBarreController.text = article.codeBarre;
    _designationController.text = article.designation;
    _prixController.text = article.prix.toString();
    _quantiteController.text = article.quantite.toString();
  }

  void _viderChampsSaufCodeBarre() {
    _designationController.clear();
    _prixController.clear();
    _quantiteController.clear();
    _articleCourant = null;
  }

  Future<void> _chercherArticle() async {
    if (_codeBarreController.text.isEmpty) {
      _afficherMessage('Veuillez entrer un code barre');
      return;
    }

    setState(() => _chargementEnCours = true);

    try {
      final articles = await articleDao.getAllArticles();
      final articleTrouve = articles.firstWhere(
            (a) => a.codeBarre == _codeBarreController.text,
      );

      setState(() {
        _articleCourant = articleTrouve;
        _remplirChamps(articleTrouve);
      });
    } on StateError {
      _afficherMessage('Aucun article trouvé avec ce code barre');
      _viderChampsSaufCodeBarre();
    } catch (e) {
      _afficherMessage('Erreur lors de la recherche: ${e.toString()}');
      _viderChampsSaufCodeBarre();
    } finally {
      setState(() => _chargementEnCours = false);
    }
  }

  Future<void> _sauvegarderArticle() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation supplémentaire pour la quantité
    final quantite = int.tryParse(_quantiteController.text) ?? 0;
    if (quantite < 0) {
      _afficherMessage('La quantité doit être supérieure ou egale zéro');
      return;
    }

    // Validation supplémentaire pour le prix
    final prix = double.tryParse(_prixController.text) ?? 0;
    if (prix <= 0) {
      _afficherMessage('Le prix doit être supérieur à zéro');
      return;
    }

    setState(() => _chargementEnCours = true);

    try {
      final article = Article(
        id: _articleCourant?.id,
        codeBarre: _codeBarreController.text,
        designation: _designationController.text,
        prix: prix,
        quantite: quantite,
        dateCreation: _articleCourant?.dateCreation ?? DateTime.now(),
      );

      if (_articleCourant?.id != null) {
        await articleDao.updateArticle(article);
        _afficherMessage('Article modifié avec succès');
      } else {
        await articleDao.insertArticle(article);
        _afficherMessage('Nouvel article enregistré');
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FormatException {
      _afficherMessage('Format des données invalide');
    } catch (e) {
      _afficherMessage('Erreur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _chargementEnCours = false);
      }
    }
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;

      if (_isScanning) {
        _codeBarreController.clear();
        _viderChampsSaufCodeBarre();
        _initScanner();
        _startScannerWithDelay();
      } else {
        _scannerController?.stop();
      }
    });
  }

  void _startScannerWithDelay() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_isScanning && mounted) {
        _scannerController?.start();
      }
    });
  }

  void _handleScan(Barcode barcode) {
    if (barcode.rawValue != null && _isScanning && mounted) {
      setState(() {
        _codeBarreController.text = barcode.rawValue!;
        _isScanning = false;
        _viderChampsSaufCodeBarre();
      });
      _chercherArticle();
    }
  }

  void _afficherMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _codeBarreController.dispose();
    _designationController.dispose();
    _prixController.dispose();
    _quantiteController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier Article'),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: _isScanning ? _buildScanner() : _buildForm(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              _handleScan(barcode);
              break;
            }
          },
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: _toggleScan,
              child: Text('Annuler le scan'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return _chargementEnCours
        ? const Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _codeBarreController,
              decoration: InputDecoration(
                labelText: 'Code Barre',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _chercherArticle,
                ),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Champ obligatoire'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty ?? true
                  ? 'Champ obligatoire'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _prixController,
              decoration: const InputDecoration(
                labelText: 'Prix (DH)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Champ obligatoire';
                final prix = double.tryParse(value!);
                return prix == null || prix <= 0
                    ? 'Prix valide (> 0) requis'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantiteController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Champ obligatoire';
                final quantite = int.tryParse(value!);
                return quantite == null || quantite < 0
                    ? 'Quantité valide (>= 0) requise'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('RECHERCHE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(0, 50),
                    ),
                    onPressed: _chercherArticle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('SAUVEGARDE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 50),
                    ),
                    onPressed: _sauvegarderArticle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}