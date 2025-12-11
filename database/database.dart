import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Getter pour obtenir la base de données
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('explorez_ville.db');
    return _database!;
  }

  // Initialisation de la base de données
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Création des tables
  Future _createDB(Database db, int version) async {
    // Table Ville
    await db.execute('''
      CREATE TABLE ville(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        pays TEXT,
        latitude REAL,
        longitude REAL,
        temperature_min REAL,
        temperature_max REAL,
        temperature_actuelle REAL,
        etat_temps TEXT,
        est_favorite INTEGER DEFAULT 0,
        date_ajout TEXT
      )
    ''');

    // Table Lieu
    await db.execute('''
      CREATE TABLE lieu(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ville_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        description TEXT,
        categorie TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        image_url TEXT,
        note_moyenne REAL DEFAULT 0,
        est_favori INTEGER DEFAULT 0,
        date_ajout TEXT,
        FOREIGN KEY (ville_id) REFERENCES ville(id) ON DELETE CASCADE
      )
    ''');

    // Table Commentaire
    await db.execute('''
      CREATE TABLE commentaire(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lieu_id INTEGER NOT NULL,
        texte TEXT NOT NULL,
        note INTEGER NOT NULL,
        date_creation TEXT,
        FOREIGN KEY (lieu_id) REFERENCES lieu(id) ON DELETE CASCADE
      )
    ''');
  }

  // Fermer la base de données
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}