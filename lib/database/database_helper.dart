import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE articles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codeBarre TEXT UNIQUE,
        designation TEXT NOT NULL,
        prix REAL NOT NULL,
        quantite INTEGER NOT NULL,
        dateCreation TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        montantTotal REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        articleId INTEGER NOT NULL,
        designation TEXT NOT NULL,
        prixUnitaire REAL NOT NULL,
        quantite INTEGER NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions(id),
        FOREIGN KEY (articleId) REFERENCES articles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE achats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        articleId INTEGER NOT NULL,
        quantite INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (articleId) REFERENCES articles(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ventes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        articleId INTEGER NOT NULL,
        quantite INTEGER NOT NULL,
        date TEXT NOT NULL,
        transactionId INTEGER,
        FOREIGN KEY (articleId) REFERENCES articles(id),
        FOREIGN KEY (transactionId) REFERENCES transactions(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE achats (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          articleId INTEGER NOT NULL,
          quantite INTEGER NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY (articleId) REFERENCES articles(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE ventes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          articleId INTEGER NOT NULL,
          quantite INTEGER NOT NULL,
          date TEXT NOT NULL,
          transactionId INTEGER,
          FOREIGN KEY (articleId) REFERENCES articles(id),
          FOREIGN KEY (transactionId) REFERENCES transactions(id)
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transactionId INTEGER NOT NULL,
          articleId INTEGER NOT NULL,
          designation TEXT NOT NULL,
          prixUnitaire REAL NOT NULL,
          quantite INTEGER NOT NULL,
          FOREIGN KEY (transactionId) REFERENCES transactions(id),
          FOREIGN KEY (articleId) REFERENCES articles(id)
        )
      ''');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}