import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/athlete.dart';
import '../models/subscription.dart';
import '../models/body_measurement.dart';

class DatabaseService {
  static const int dbVersion = 3;
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static String? _externalDbPath;

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  /// Get the external Documents/powergym/ path
  Future<String> _getExternalDbPath() async {
    if (_externalDbPath != null) return _externalDbPath!;

    // Primary: /storage/emulated/0/Documents/powergym/powergymapp.db
    final docsDir = Directory('/storage/emulated/0/Documents/powergym');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    _externalDbPath = join(docsDir.path, 'powergymapp.db');
    return _externalDbPath!;
  }

  /// Get the internal fallback path (app-private)
  Future<String> _getInternalDbPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return join(dir.path, 'powergymapp.db');
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;

    try {
      // Try to use external storage path
      dbPath = await _getExternalDbPath();
    } catch (e) {
      // Fallback to internal storage
      dbPath = await _getInternalDbPath();
    }

    // Check if external file exists (data from previous install / sync)
    final externalFile = File(dbPath);
    final internalPath = await _getInternalDbPath();
    final internalFile = File(internalPath);

    if (await externalFile.exists() && !await internalFile.exists()) {
      // External DB exists but internal doesn't â†’ copy from external (restore)
      await internalFile.writeAsBytes(await externalFile.readAsBytes());
    }

    // Open from internal (safer for sqflite), then sync externally on changes
    return await openDatabase(
      internalPath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Sync database file to external Documents/powergym/ for backup
  Future<void> syncToExternal() async {
    try {
      final internalPath = await _getInternalDbPath();
      final externalPath = await _getExternalDbPath();
      final internalFile = File(internalPath);
      final externalFile = File(externalPath);

      if (await internalFile.exists()) {
        // Close DB briefly to copy safely
        await internalFile.copy(externalPath);
      }
    } catch (e) {
      // Silently fail â€” external sync is best-effort
    }
  }

  /// Load database from external path (on app launch restore)
  Future<void> restoreFromExternal() async {
    try {
      final internalPath = await _getInternalDbPath();
      final externalPath = await _getExternalDbPath();
      final internalFile = File(internalPath);
      final externalFile = File(externalPath);

      if (await externalFile.exists()) {
        // Copy external â†’ temp file first to validate
        final tempPath = '$internalPath.tmp';
        final tempFile = File(tempPath);
        await externalFile.copy(tempPath);

        // Try opening the temp file to validate it's a real DB
        Database? tempDb;
        try {
          tempDb = await openDatabase(tempPath, version: dbVersion, readOnly: true);
          await tempDb.close();
        } catch (e) {
          // Temp file is corrupt â€” delete it, keep existing internal DB
          await tempFile.delete();
          return;
        }

        // Valid â€” close current DB, replace internal with temp
        final db = _database;
        if (db != null) await db.close();
        _database = null;

        // Delete old internal, rename temp to internal
        if (await internalFile.exists()) await internalFile.delete();
        await tempFile.rename(internalPath);

        // Re-open
        _database = await openDatabase(
          internalPath,
          version: dbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
      }
    } catch (e) {
      // Silently fail â€” keep existing internal DB or create fresh
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE athletes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        first_name TEXT,
        phone TEXT NOT NULL,
        email TEXT,
        photo_path TEXT,
        start_date TEXT NOT NULL,
        birth_date TEXT,
        notes TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        gender TEXT NOT NULL DEFAULT 'male'
      )
    ''');

    await db.execute('''
      CREATE TABLE subscriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        athlete_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        price REAL NOT NULL,
        is_paid INTEGER NOT NULL DEFAULT 0,
        payment_date TEXT,
        notes TEXT,
        FOREIGN KEY (athlete_id) REFERENCES athletes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE body_measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        athlete_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        weight REAL,
        height REAL,
        chest REAL,
        abdomen REAL,
        thigh REAL,
        arm REAL,
        notes TEXT,
        FOREIGN KEY (athlete_id) REFERENCES athletes(id) ON DELETE CASCADE
      )
    ''');

    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE athletes ADD COLUMN gender TEXT NOT NULL DEFAULT 'male'");
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE athletes ADD COLUMN first_name TEXT');
      await db.execute('ALTER TABLE athletes ADD COLUMN birth_date TEXT');
      await db.execute('ALTER TABLE subscriptions ADD COLUMN payment_date TEXT');
      await db.execute('''
        CREATE TABLE body_measurements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          athlete_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          weight REAL,
          height REAL,
          chest REAL,
          abdomen REAL,
          thigh REAL,
          arm REAL,
          notes TEXT,
          FOREIGN KEY (athlete_id) REFERENCES athletes(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_body_measurements_athlete_id ON body_measurements(athlete_id)');
    }
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX idx_subscriptions_athlete_id ON subscriptions(athlete_id)');
    await db.execute('CREATE INDEX idx_subscriptions_end_date ON subscriptions(end_date)');
    await db.execute('CREATE INDEX idx_subscriptions_is_paid ON subscriptions(is_paid)');
    await db.execute('CREATE INDEX idx_athletes_is_active ON athletes(is_active)');
  }

  // â”€â”€â”€ Athlete CRUD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<int> insertAthlete(Athlete athlete) async {
    final db = await database;
    final id = await db.insert('athletes', athlete.toMap());
    await syncToExternal();
    return id;
  }

  Future<List<Athlete>> getAllAthletes() async {
    final db = await database;
    final maps = await db.query('athletes', orderBy: 'name ASC');
    return maps.map((m) => Athlete.fromMap(m)).toList();
  }

  Future<Athlete?> getAthleteById(int id) async {
    final db = await database;
    final maps = await db.query('athletes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Athlete.fromMap(maps.first);
  }

  Future<List<Athlete>> searchAthletes(String query) async {
    final db = await database;
    final maps = await db.query(
      'athletes',
      where: 'name LIKE ? OR phone LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Athlete.fromMap(m)).toList();
  }

  Future<int> updateAthlete(Athlete athlete) async {
    final db = await database;
    final result = await db.update('athletes', athlete.toMap(), where: 'id = ?', whereArgs: [athlete.id]);
    await syncToExternal();
    return result;
  }

  Future<void> updateAthletePhoto(int athleteId, String photoPath) async {
    final db = await database;
    await db.update(
      'athletes',
      {'photo_path': photoPath},
      where: 'id = ?',
      whereArgs: [athleteId],
    );
    await syncToExternal();
  }

  Future<int> deleteAthlete(int id) async {
    final db = await database;
    final result = await db.delete('athletes', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
    return result;
  }

  // â”€â”€â”€ Subscription CRUD â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<int> insertSubscription(Subscription subscription) async {
    final db = await database;
    final id = await db.insert('subscriptions', subscription.toMap());
    await syncToExternal();
    return id;
  }

  Future<List<Subscription>> getSubscriptionsByAthleteId(int athleteId) async {
    final db = await database;
    final maps = await db.query('subscriptions', where: 'athlete_id = ?', whereArgs: [athleteId], orderBy: 'start_date DESC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<List<Subscription>> getActiveSubscriptions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query('subscriptions', where: 'end_date >= ?', whereArgs: [now], orderBy: 'end_date ASC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<List<Subscription>> getExpiredSubscriptions() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query('subscriptions', where: 'end_date < ?', whereArgs: [now], orderBy: 'end_date DESC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<List<Subscription>> getExpiringWithinDays(int days) async {
    final db = await database;
    final now = DateTime.now();
    final deadline = now.add(Duration(days: days)).toIso8601String();
    final nowStr = now.toIso8601String();
    final maps = await db.query('subscriptions', where: 'end_date >= ? AND end_date <= ?', whereArgs: [nowStr, deadline], orderBy: 'end_date ASC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<List<Subscription>> getUnpaidSubscriptions() async {
    final db = await database;
    final maps = await db.query('subscriptions', where: 'is_paid = 0', orderBy: 'end_date ASC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await database;
    final maps = await db.query('subscriptions', orderBy: 'start_date DESC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<int> updateSubscription(Subscription subscription) async {
    final db = await database;
    final result = await db.update('subscriptions', subscription.toMap(), where: 'id = ?', whereArgs: [subscription.id]);
    await syncToExternal();
    return result;
  }

  Future<int> deleteSubscription(int id) async {
    final db = await database;
    final result = await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
    return result;
  }

  // â”€â”€â”€ Combined Queries â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>?> getAthleteWithSubscription(int athleteId) async {
    final athlete = await getAthleteById(athleteId);
    if (athlete == null) return null;
    final subscriptions = await getSubscriptionsByAthleteId(athleteId);
    final activeSubscription = subscriptions.isNotEmpty
        ? subscriptions.firstWhere((s) => s.isActive || s.isExpiringSoon, orElse: () => subscriptions.first)
        : null;
    return {'athlete': athlete, 'subscriptions': subscriptions, 'activeSubscription': activeSubscription};
  }

  Future<List<Map<String, dynamic>>> getAllAthletesWithSubscriptions() async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT a.*, s.id as sub_id, s.athlete_id as sub_athlete_id, s.type as sub_type,
        s.start_date as sub_start_date, s.end_date as sub_end_date, s.price as sub_price,
        s.is_paid as sub_is_paid, s.payment_date as sub_payment_date, s.notes as sub_notes
      FROM athletes a
      LEFT JOIN (SELECT *, ROW_NUMBER() OVER (PARTITION BY athlete_id ORDER BY end_date DESC) as rn FROM subscriptions) s
        ON a.id = s.athlete_id AND s.rn = 1
      ORDER BY a.name ASC
    ''');
    return results.map((row) {
      final athlete = Athlete.fromMap(row);
      Subscription? latestSubscription;
      if (row['sub_id'] != null) {
        latestSubscription = Subscription.fromMap({
          'id': row['sub_id'], 'athlete_id': row['sub_athlete_id'], 'type': row['sub_type'],
          'start_date': row['sub_start_date'], 'end_date': row['sub_end_date'],
          'price': row['sub_price'], 'is_paid': row['sub_is_paid'],
          'payment_date': row['sub_payment_date'], 'notes': row['sub_notes'],
        });
      }
      return {'athlete': athlete, 'latestSubscription': latestSubscription};
    }).toList();
  }

  // ─── Body Measurements CRUD ────────────────────────────────────

  Future<int> insertBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    final id = await db.insert('body_measurements', measurement.toMap());
    await syncToExternal();
    return id;
  }

  Future<List<BodyMeasurement>> getBodyMeasurementsByAthleteId(int athleteId) async {
    final db = await database;
    final maps = await db.query(
      'body_measurements',
      where: 'athlete_id = ?',
      whereArgs: [athleteId],
      orderBy: 'date DESC',
    );
    return maps.map((m) => BodyMeasurement.fromMap(m)).toList();
  }

  Future<int> updateBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    final result = await db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
    await syncToExternal();
    return result;
  }

  Future<int> deleteBodyMeasurement(int id) async {
    final db = await database;
    final result = await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
    return result;
  }

  Future<void> fixPrices3000To1500() async {
    final db = await database;
    final count = await db.rawUpdate(
      "UPDATE subscriptions SET price = 1500 WHERE price = 3000",
    );
    if (count > 0) await syncToExternal();
  }

  Future<void> close() async {
    final db = await database;
    await syncToExternal();
    await db.close();
    _database = null;
  }
}
