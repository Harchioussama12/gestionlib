import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mylib/dao/article_dao.dart';
import 'package:mylib/database/database_helper.dart';
import 'package:mylib/models/article_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class MouvementStock extends StatefulWidget {
  @override
  _MouvementStockState createState() => _MouvementStockState();
}

class _MouvementStockState extends State<MouvementStock> {
  final ArticleDao _articleDao = ArticleDao(DatabaseHelper());
  List<ArticleStockData> _stockData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStockData();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await Permission.storage.request();
    }
  }

  Future<void> _loadStockData() async {
    try {
      final articles = await _articleDao.getAllArticles();
      final stockData = await Future.wait(
        articles.map((article) async {
          final ventes = await _articleDao.getTotalVentes(article.id!);
          return ArticleStockData(
            article: article,
            quantiteInitiale: article.quantite + ventes,
            ventes: ventes,
            stock: article.quantite,
          );
        }),
      );

      setState(() {
        _stockData = stockData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur: ${e.toString()}');
    }
  }

  Future<void> genererPDF() async {
    setState(() => _isLoading = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Header(
                  level: 0,
                  child: pw.Text('Rapport de Stock',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  context: context,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  headers: ['Article', 'Achats', 'Ventes', 'Stock'],
                  data: _stockData.map((data) => [
                    data.article.designation,
                    data.quantiteInitiale.toString(),
                    data.ventes.toString(),
                    data.stock.toString(),
                  ]).toList(),
                ),
              ],
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) => pdfBytes,
      );
    } catch (e) {
      _showError('Erreur lors de la génération du PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth / 4;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mouvements de Stock'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadStockData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.blue[800],
            child: Row(
              children: [
                _buildHeaderCell('Article', columnWidth),
                _buildHeaderCell('Achats', columnWidth),
                _buildHeaderCell('Ventes', columnWidth),
                _buildHeaderCell('Stock', columnWidth),
              ],
            ),
          ),
          Expanded(
              child: ListView.builder(
                itemCount: _stockData.length,
                itemBuilder: (context, index) {
                  final data = _stockData[index];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        _buildDataCell(data.article.designation, columnWidth),
                        _buildDataCell(data.quantiteInitiale.toString(), columnWidth),
                        _buildDataCell(data.ventes.toString(), columnWidth),
                        _buildDataCell(data.stock.toString(), columnWidth),
                      ],
                    ),
                  );
                },
              )
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.picture_as_pdf),
              label: Text('Générer PDF'),
              onPressed: genererPDF,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class ArticleStockData {
  final Article article;
  final int quantiteInitiale;
  final int ventes;
  final int stock;

  ArticleStockData({
    required this.article,
    required this.quantiteInitiale,
    required this.ventes,
    required this.stock,
  });
}