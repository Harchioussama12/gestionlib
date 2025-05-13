import 'package:flutter/material.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SupprimerArticle extends StatefulWidget {
  const SupprimerArticle({super.key});

  @override
  State<SupprimerArticle> createState() => _SupprimerArticleState();
}

class _SupprimerArticleState extends State<SupprimerArticle> {
  final ArticleDao _articleDao = ArticleDao(DatabaseHelper());
  final TextEditingController _codeBarreController = TextEditingController();
  final TextEditingController _designationController = TextEditingController();
  Article? _articleToDelete;
  bool _isLoading = false;
  bool _isScanning = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      formats: [BarcodeFormat.all],
      autoStart: false,
    );
  }

  Future<void> _chercherArticle() async {
    final codeBarre = _codeBarreController.text.trim();
    if (codeBarre.isEmpty) {
      _showMessage('Veuillez saisir un code-barres');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _articleToDelete = null;
      _designationController.clear();
    });

    try {
      final articles = await _articleDao.getAllArticles();
      final articleTrouve = articles.firstWhere(
              (a) => a.codeBarre == codeBarre,
          orElse: () => Article(
            id: -1,
            codeBarre: '',
            designation: 'Non trouvé',
            prix: 0.0,
            quantite: 0,
            dateCreation: DateTime(0),
             ), // تم إغلاق القوس هنا
             );
          if (!mounted) return;
      setState(() {
        _articleToDelete = articleTrouve.id != -1 ? articleTrouve : null;
        if (_articleToDelete != null) {
          _designationController.text = _articleToDelete!.designation;
        }
      });
    } on StateError catch (_) {
      _showMessage('Aucun article trouvé avec ce code-barres');
    } catch (e) {
      _showMessage('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteArticle() async {
    if (_articleToDelete == null || _articleToDelete?.id == null) {
      _showMessage('Aucun article sélectionné');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final rowsDeleted = await _articleDao.deleteArticle(_articleToDelete!.id!);

      if (!mounted) return;
      if (rowsDeleted > 0) {
        _showMessage('Article supprimé avec succès');
        Navigator.pop(context, true);
      } else {
        _showMessage('Échec de la suppression');
      }
    } catch (e) {
      _showMessage('Erreur critique: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;

      if (_isScanning) {
        _codeBarreController.clear();
        _designationController.clear();
        _articleToDelete = null;
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
      });
      _chercherArticle();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _codeBarreController.dispose();
    _designationController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supprimer Article'),
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
              child: const Text('Annuler le scan'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeBarreController,
                  decoration: const InputDecoration(
                    labelText: 'Code-Barre',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _chercherArticle(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _chercherArticle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _designationController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Désignation',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ANNULER'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _articleToDelete != null ? _deleteArticle : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('SUPPRIMER'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}