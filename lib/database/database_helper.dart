import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Initialiser databaseFactory si besoin (Linux/Windows/macOS)
    if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      databaseFactory = databaseFactoryFfi;
    }
    
    _database = await _initDB('explorez_ville.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      debugPrint('📂 Chemin de la base de données : $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de la DB : $e');
      rethrow;
    }
  }

  Future _createDB(Database db, int version) async {
    debugPrint('🔧 Création des tables de la base de données...');
    
    // Table ville
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

    // Table lieu
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

    // Table commentaire
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

    debugPrint('✅ Tables créées avec succès');
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}