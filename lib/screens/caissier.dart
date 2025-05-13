import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/dao/transaction_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';
import 'package:mylib/models/transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Caissier extends StatefulWidget {
  const Caissier({Key? key}) : super(key: key);

  @override
  State<Caissier> createState() => _CaissierState();
}

class _CaissierState extends State<Caissier> {
  final ArticleDao _articleDao = ArticleDao(DatabaseHelper());
  final TransactionDao _transactionDao = TransactionDao(DatabaseHelper());
  final TextEditingController _codeBarreController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController(text: '1');

  List<Map<String, dynamic>> _panier = [];
  double _total = 0.0;
  Article? _articleCourant;
  int? _selectedIndex;
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

  String _formatPrix(num prix) {
    if (prix % 1 == 0) {
      return '${prix.toInt()} DH';
    }
    final str = prix.toString();
    if (str.split('.').last.length == 1) {
      return '${prix.toStringAsFixed(1)} DH';
    }
    return '${prix.toStringAsFixed(2)} DH';
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
      if (_isScanning) {
        _codeBarreController.clear();
        _articleCourant = null;
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
      _chercherEtAjouterArticle();
    }
  }

  Future<void> _chercherEtAjouterArticle() async {
    final codeBarre = _codeBarreController.text.trim();
    if (codeBarre.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final articles = await _articleDao.getAllArticles();
      final article = articles.firstWhere(
            (a) => a.codeBarre == codeBarre,
        orElse: () => Article(
          id: -1,
          codeBarre: '',
          designation: '',
          prix: 0,
          quantite: 0,
          dateCreation: DateTime.now(),
        ),
      );

      if (!mounted) return;

      if (article.id != -1) {
        await _ajouterArticleDirectement(article);
      } else {
        _showMessage('Article non trouvé');
      }
    } catch (e) {
      _showMessage('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterArticleDirectement(Article article) async {
    const quantite = 1;

    if (article.quantite <= 0) {
      _showMessage('Stock épuisé');
      return;
    }

    final quantiteDansPanier = _panier
        .where((item) => item['articleId'] == article.id)
        .fold<int>(0, (sum, item) => sum + (item['quantite'] as int));

    if (quantiteDansPanier >= article.quantite) {
      _showMessage('Stock insuffisant');
      return;
    }

    setState(() {
      _panier.add({
        'articleId': article.id!,
        'designation': article.designation,
        'prix': article.prix,
        'quantite': quantite,
        'total': article.prix * quantite,
      });
      _total += article.prix * quantite;
      _codeBarreController.clear();
    });
  }

  Future<void> _chercherArticle() async {
    final codeBarre = _codeBarreController.text.trim();
    if (codeBarre.isEmpty) {
      _showMessage('Veuillez entrer un code barre');
      return;
    }

    setState(() {
      _isLoading = true;
      _articleCourant = null;
    });

    try {
      final articles = await _articleDao.getAllArticles();
      final article = articles.firstWhere(
            (a) => a.codeBarre == codeBarre,
        orElse: () => Article(
          id: -1,
          codeBarre: '',
          designation: '',
          prix: 0,
          quantite: 0,
          dateCreation: DateTime.now(),
        ),
      );

      if (!mounted) return;
      setState(() {
        if (article.id == -1) {
          _showMessage('Article non trouvé');
        } else {
          _articleCourant = article;
        }
      });
    } catch (e) {
      _showMessage('Erreur: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _ajouterArticle() async {
    if (_articleCourant == null) {
      await _chercherArticle();
      if (_articleCourant == null) return;
    }

    final quantite = int.tryParse(_quantiteController.text) ?? 1;
    if (quantite <= 0) {
      _showMessage('Quantité doit être > 0');
      return;
    }

    if (_articleCourant!.quantite <= 0) {
      _showMessage('Stock épuisé');
      return;
    }

    final quantiteDansPanier = _panier
        .where((item) => item['articleId'] == _articleCourant!.id)
        .fold<int>(0, (sum, item) => sum + (item['quantite'] as int));

    final quantiteTotale = quantiteDansPanier + quantite;

    if (quantiteTotale > _articleCourant!.quantite) {
      final quantiteRestante = _articleCourant!.quantite - quantiteDansPanier;
      _showMessage('Quantité disponible: $quantiteRestante');
      return;
    }

    setState(() {
      _panier.add({
        'articleId': _articleCourant!.id!,
        'designation': _articleCourant!.designation,
        'prix': _articleCourant!.prix,
        'quantite': quantite,
        'total': _articleCourant!.prix * quantite,
      });
      _total += _articleCourant!.prix * quantite;
      _codeBarreController.clear();
      _quantiteController.text = '1';
      _articleCourant = null;
    });
  }

  Future<void> _modifierQuantite() async {
    if (_selectedIndex == null) {
      _showMessage('Veuillez sélectionner un article');
      return;
    }

    final newQuantite = int.tryParse(_quantiteController.text) ?? 1;
    if (newQuantite <= 0) {
      _showMessage('Quantité doit être > 0');
      return;
    }

    final selectedItem = _panier[_selectedIndex!];
    final article = await _articleDao.getArticleById(selectedItem['articleId']);
    if (article == null || article.quantite <= 0) {
      _showMessage('Article indisponible');
      return;
    }

    final quantiteDispo = article.quantite;
    final ancienneQuantite = selectedItem['quantite'] as int;

    final quantiteDansPanier = _panier
        .where((item) => item['articleId'] == article.id && item != selectedItem)
        .fold<int>(0, (sum, item) => sum + (item['quantite'] as int));

    if (newQuantite + quantiteDansPanier > quantiteDispo) {
      final quantiteRestante = quantiteDispo - quantiteDansPanier;
      _showMessage('Quantité maximale: $quantiteRestante');
      return;
    }

    setState(() {
      _total -= selectedItem['prix'] * ancienneQuantite;
      selectedItem['quantite'] = newQuantite;
      selectedItem['total'] = selectedItem['prix'] * newQuantite;
      _total += selectedItem['total'];
      _selectedIndex = null;
      _quantiteController.text = '1';
    });
  }

  Future<void> _supprimerArticle() async {
    if (_panier.isEmpty) {
      return;
    }

    setState(() {
      if (_selectedIndex != null) {
        final removedItem = _panier.removeAt(_selectedIndex!);
        _total -= removedItem['total'];
        _selectedIndex = null;
      } else {
        final removedItem = _panier.removeLast();
        _total -= removedItem['total'];
      }
      _quantiteController.text = '1';
    });
  }

  Future<void> _encaisser() async {
    if (_panier.isEmpty) {
      _showMessage('Panier vide');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final transactionItems = _panier.map((item) => TransactionItem(
        transactionId: 0,
        articleId: item['articleId'],
        designation: item['designation'],
        prixUnitaire: item['prix'],
        quantite: item['quantite'],
      )).toList();

      final transaction = Transaction(
        date: DateTime.now(),
        montantTotal: _total,
        items: transactionItems,
      );

      final transactionId = await _transactionDao.insertTransaction(transaction);

      for (final item in _panier) {
        await _articleDao.enregistrerVente(
          item['articleId'],
          item['quantite'],
          transactionId,
        );

        final article = await _articleDao.getArticleById(item['articleId']);
        if (article != null) {
          await _articleDao.updateArticle(
              article.copyWith(quantite: article.quantite - (item['quantite'] as int),
              ),
              );
          }
          }

              await _generateAndPrintPDF();

          setState(() {
            _panier.clear();
            _total = 0.0;
            _selectedIndex = null;
          });

          _showMessage('Paiement effectué avec succès', isError: false);
        } catch (e) {
      _showMessage('Erreur lors du paiement: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateAndPrintPDF() async {
    if (_panier.isEmpty) {
      _showMessage('Le panier est vide', isError: true);
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Column(
                  children: [
                    pw.Text('Facture',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 10),
                    pw.Text('Date: ${DateTime.now().toString()}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1),
                  3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Article',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Prix',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Qté',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text('Mnt',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ..._panier.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(item['designation'])),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                              _formatPrix(item['prix']).replaceAll(' DH', ''))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(item['quantite'].toString())),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                              _formatPrix(item['prix'] * item['quantite']).replaceAll(' DH', ''))),
                    ],
                  )).toList(),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Total: ${_formatPrix(_total)}',
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedIndex = null;
      _quantiteController.text = '1';
    });
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

  Widget _buildCodeBarreField() {
    return TextField(
      controller: _codeBarreController,
      decoration: InputDecoration(
        labelText: 'Code barre',
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _toggleScan,
            ),
          ],
        ),
      ),
      onSubmitted: (_) => _chercherEtAjouterArticle(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.close : Icons.qr_code_scanner),
            onPressed: _toggleScan,
          ),
        ],
      ),
      body: _isScanning ? _buildScanner() : GestureDetector(
        onTap: _clearSelection,
        behavior: HitTestBehavior.opaque,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(1.5),
                  3: FlexColumnWidth(2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: const [
                  TableRow(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 16.0),
                        child: Text(
                          'Article',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text(
                          'Prix',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Text(
                          'Qté',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Text(
                          'Mnt',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _panier.isEmpty
                  ? const Center(child: Text('Aucun article dans le panier'))
                  : ListView.builder(
                itemCount: _panier.length,
                itemBuilder: (context, index) {
                  final item = _panier[index];
                  final total = (item['prix'] as num) * (item['quantite'] as int);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                        _quantiteController.text = item['quantite'].toString();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index ? Colors.blue[50] : null,
                        border: const Border(bottom: BorderSide(color: Colors.grey)),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1),
                          2: FlexColumnWidth(1),
                          3: FlexColumnWidth(1),
                        },
                        children: [
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  item['designation']?.toString() ?? 'N/A',
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  _formatPrix(item['prix'] as num),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  item['quantite'].toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  _formatPrix(total),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildCodeBarreField(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _quantiteController,
                      decoration: const InputDecoration(
                        labelText: 'Qté',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 18)),
                      Text(
                        _formatPrix(_total),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton('Ajouter', _ajouterArticle, Colors.purple),
                        const SizedBox(width: 6),
                        _buildActionButton('Qte', _modifierQuantite, Colors.blue),
                        const SizedBox(width: 6),
                        _buildActionButton('Supprimer', _supprimerArticle, Colors.red),
                        const SizedBox(width: 4),
                        _buildActionButton('Encaisser', _encaisser, Colors.green),
                        const SizedBox(width: 6),
                        _buildActionButton('Imprimer', _generateAndPrintPDF, Colors.orange),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeBarreController.dispose();
    _quantiteController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }
}