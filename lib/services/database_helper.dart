import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'money_tracker.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT NOT NULL,
            amount REAL NOT NULL,
            dateTime TEXT NOT NULL,
            type TEXT NOT NULL,
            paidVia TEXT,
            category TEXT
          )
        ''');
      },
    );
  }
}
