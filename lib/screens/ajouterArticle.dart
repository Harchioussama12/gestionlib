import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';

class AjouterArticle extends StatefulWidget {
  @override
  _AjouterArticleState createState() => _AjouterArticleState();
}

class _AjouterArticleState extends State<AjouterArticle> {
  final _formKey = GlobalKey<FormState>();
  final _codeBarreController = TextEditingController();
  final _designationController = TextEditingController();
  final _prixController = TextEditingController();
  final _quantiteController = TextEditingController();

  late ArticleDao articleDao;
  bool _isLoading = false;
  bool _isScanning = false;
  MobileScannerController? _scannerController;
  bool _shouldRestartScan = false;

  @override
  void initState() {
    super.initState();
    articleDao = ArticleDao(DatabaseHelper());
    _initScanner();
  }

  void _initScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.all],
      autoStart: false,
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

  Future<void> _ajouterArticle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final article = Article(
          codeBarre: _codeBarreController.text,
          designation: _designationController.text,
          prix: double.tryParse(_prixController.text) ?? 0.0,
          quantite: int.tryParse(_quantiteController.text) ?? 0,
          dateCreation: DateTime.now(),
        );

        // Validation supplémentaire pour la quantité
        if (article.quantite < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('La quantité doit être supérieure ou egale zéro')),
          );
          return;
        }

        final id = await articleDao.insertArticle(article);

        if (id > 0) {
          await articleDao.enregistrerAchat(id, article.quantite);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Article ajouté avec succès')),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _chercherArticle() async {
    final codeBarre = _codeBarreController.text.trim();
    if (codeBarre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez entrer un code barre')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final articles = await articleDao.getAllArticles();
      final article = articles.firstWhere(
            (a) => a.codeBarre == codeBarre,
        orElse: () => Article(
            id: -1,
            codeBarre: '',
            designation: '',
            prix: 0,
            quantite: 0,
            dateCreation: DateTime.now()
        ),
      );

      if (article.id == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Article non trouvé')),
        );
      } else {
        _designationController.text = article.designation;
        _prixController.text = article.prix.toString();
        _quantiteController.text = article.quantite.toString();

        final totalAchats = await articleDao.getTotalAchats(article.id!);
        final totalVentes = await articleDao.getTotalVentes(article.id!);
        final stock =  totalAchats - totalVentes;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock actuel: $stock')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;

      if (_isScanning) {
        _clearFields();
        _initScanner();
        _startScannerWithDelay();
      } else {
        _scannerController?.stop();
      }
    });
  }

  void _clearFields() {
    _codeBarreController.clear();
    _designationController.clear();
    _prixController.clear();
    _quantiteController.clear();
  }

  void _startScannerWithDelay() {
    Future.delayed(Duration(milliseconds: 300), () {
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
      });
      _chercherArticle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ajouter un article'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _codeBarreController,
              decoration: InputDecoration(
                labelText: 'Code Barre',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _chercherArticle,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un code barre';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _designationController,
              decoration: InputDecoration(
                labelText: 'Désignation',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une désignation';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _prixController,
              decoration: InputDecoration(
                labelText: 'Prix',
                border: OutlineInputBorder(),
                suffixText: 'Dh',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un prix';
                }
                if (double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Veuillez entrer un prix valide (> 0)';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantiteController,
              decoration: InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une quantité';
                }
                if (int.tryParse(value) == null || int.parse(value) < 0) {
                  return 'La quantité doit être >= 0';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _ajouterArticle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                'AJOUTER',
                style: TextStyle(fontSize: 18, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}