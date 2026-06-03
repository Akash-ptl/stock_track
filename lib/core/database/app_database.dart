import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock_track_v2.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create stock_items table with user segment isolation
        await db.execute('''
          CREATE TABLE stock_items (
            user_uid TEXT,
            business_id TEXT,
            location_id TEXT,
            id TEXT,
            name TEXT,
            sku TEXT,
            unit TEXT,
            quantity REAL,
            imageUrl TEXT,
            isSynced INTEGER,
            cartons REAL,
            pieces REAL,
            packSizeMultiplier INTEGER,
            parentUnit TEXT,
            notes TEXT,
            countType TEXT,
            countDate TEXT,
            countedBy TEXT,
            PRIMARY KEY (user_uid, business_id, location_id, id)
          )
        ''');

        // Create businesses table
        await db.execute('''
          CREATE TABLE businesses (
            user_uid TEXT,
            id TEXT,
            name TEXT,
            PRIMARY KEY (user_uid, id)
          )
        ''');

        // Create locations table
        await db.execute('''
          CREATE TABLE locations (
            user_uid TEXT,
            business_id TEXT,
            id TEXT,
            name TEXT,
            PRIMARY KEY (user_uid, business_id, id)
          )
        ''');

        // Create sync_outbox table
        await db.execute('''
          CREATE TABLE sync_outbox (
            id TEXT PRIMARY KEY,
            user_uid TEXT,
            business_id TEXT,
            location_id TEXT,
            item_id TEXT,
            cartons REAL,
            pieces REAL,
            notes TEXT,
            countType TEXT,
            countDate TEXT,
            countedBy TEXT
          )
        ''');
      },
    );
  }
}
