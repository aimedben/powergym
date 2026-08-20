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

  DatabaseService._internal();

  factory DatabaseService() => _instance;

  /// Always use sqflite's internal databases path — no permission needed
  Future<String> _getDbPath() async {
    return await getDatabasesPath();
  }

  /// External Documents/powergym/ path (optional, for backup only)
  Future<String?> _getExternalDbPath() async {
    try {
      final docsDir = Directory('/storage/emulated/0/Documents/powergym');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      return join(docsDir.path, 'powergymapp.db');
    } catch (e) {
      return null; // No external storage access
    }
  }

  /// Check if external storage is writable
  Future<bool> get hasExternalStorage async {
    final extPath = await _getExternalDbPath();
    if (extPath == null) return false;
    try {
      final testFile = File('$extPath.test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbDir = await _getDbPath();
    final dbPath = join(dbDir, 'powergymapp.db');

    // On first launch: check if an external DB exists from a previous install
    try {
      final extPath = await _getExternalDbPath();
      if (extPath != null) {
        final externalFile = File(extPath);
        final internalFile = File(dbPath);

        if (await externalFile.exists() && !await internalFile.exists()) {
          // Copy external → temp to validate
          final tempPath = '$dbPath.tmp';
          final tempFile = File(tempPath);
          await externalFile.copy(tempPath);

          Database? tempDb;
          try {
            tempDb = await openDatabase(tempPath, version: dbVersion, readOnly: true);
            await tempDb.close();
          } catch (e) {
            await tempFile.delete();
            // Corrupt — start fresh
            return await openDatabase(
              dbPath,
              version: dbVersion,
              onCreate: _onCreate,
              onUpgrade: _onUpgrade,
            );
          }

          // Valid — replace internal
          if (await internalFile.exists()) await internalFile.delete();
          await tempFile.rename(dbPath);
        }
      }
    } catch (e) {
      // Restore failed — continue with fresh DB
    }

    // Always open from internal storage (no permission issues)
    return await openDatabase(
      dbPath,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Sync database file to external Documents/powergym/ for backup (best-effort)
  Future<void> syncToExternal() async {
    try {
      final extPath = await _getExternalDbPath();
      if (extPath == null) return; // No external access

      final db = _database;
      if (db == null) return;

      // Use sqflite's built-in path
      final internalPath = join(await _getDbPath(), 'powergymapp.db');
      final internalFile = File(internalPath);

      if (await internalFile.exists()) {
        await internalFile.copy(extPath);
      }
    } catch (e) {
      // External sync is best-effort — never block
    }
  }

  /// Restore database from external path (best-effort)
  Future<void> restoreFromExternal() async {
    try {
      final extPath = await _getExternalDbPath();
      if (extPath == null) return;

      final internalPath = join(await _getDbPath(), 'powergymapp.db');
      final internalFile = File(internalPath);
      final externalFile = File(extPath);

      if (await externalFile.exists()) {
        final tempPath = '$internalPath.tmp';
        final tempFile = File(tempPath);
        await externalFile.copy(tempPath);

        Database? tempDb;
        try {
          tempDb = await openDatabase(tempPath, version: dbVersion, readOnly: true);
          await tempDb.close();
        } catch (e) {
          await tempFile.delete();
          return;
        }

        final db = _database;
        if (db != null) await db.close();
        _database = null;

        if (await internalFile.exists()) await internalFile.delete();
        await tempFile.rename(internalPath);
      }
    } catch (e) {
      // Restore failed — keep existing DB
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

  // ─── Athlete CRUD ───────────────────

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
    await db.update('athletes', {'photo_path': photoPath}, where: 'id = ?', whereArgs: [athleteId]);
  }

  Future<void> deleteAthlete(int id) async {
    final db = await database;
    await db.delete('athletes', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
  }

  // ─── Subscription CRUD ───────────────────

  Future<int> insertSubscription(Subscription sub) async {
    final db = await database;
    final id = await db.insert('subscriptions', sub.toMap());
    await syncToExternal();
    return id;
  }

  Future<List<Subscription>> getSubscriptionsForAthlete(int athleteId) async {
    final db = await database;
    final maps = await db.query('subscriptions', where: 'athlete_id = ?', whereArgs: [athleteId], orderBy: 'end_date DESC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  /// Alias used by athlete_service
  Future<List<Subscription>> getSubscriptionsByAthleteId(int athleteId) async {
    return getSubscriptionsForAthlete(athleteId);
  }

  Future<Subscription?> getLatestSubscription(int athleteId) async {
    final db = await database;
    final maps = await db.query('subscriptions', where: 'athlete_id = ?', whereArgs: [athleteId], orderBy: 'end_date DESC', limit: 1);
    if (maps.isEmpty) return null;
    return Subscription.fromMap(maps.first);
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final db = await database;
    final maps = await db.query('subscriptions', orderBy: 'end_date DESC');
    return maps.map((m) => Subscription.fromMap(m)).toList();
  }

  Future<int> updateSubscription(Subscription sub) async {
    final db = await database;
    final result = await db.update('subscriptions', sub.toMap(), where: 'id = ?', whereArgs: [sub.id]);
    await syncToExternal();
    return result;
  }

  Future<void> deleteSubscription(int id) async {
    final db = await database;
    await db.delete('subscriptions', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
  }

  // ─── Body Measurements CRUD ───────────────────

  Future<int> insertBodyMeasurement(BodyMeasurement m) async {
    final db = await database;
    final id = await db.insert('body_measurements', m.toMap());
    await syncToExternal();
    return id;
  }

  Future<List<BodyMeasurement>> getMeasurementsForAthlete(int athleteId) async {
    final db = await database;
    final maps = await db.query('body_measurements', where: 'athlete_id = ?', whereArgs: [athleteId], orderBy: 'date DESC');
    return maps.map((m) => BodyMeasurement.fromMap(m)).toList();
  }

  /// Alias used by athlete_service / notification_service
  Future<List<BodyMeasurement>> getBodyMeasurementsByAthleteId(int athleteId) async {
    return getMeasurementsForAthlete(athleteId);
  }

  /// Update an existing body measurement
  Future<void> updateBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    await db.update('body_measurements', measurement.toMap(), where: 'id = ?', whereArgs: [measurement.id]);
    await syncToExternal();
  }

  /// Get all athletes with their latest subscription
  Future<List<Map<String, dynamic>>> getAllAthletesWithSubscriptions() async {
    final db = await database;
    final athletes = await getAllAthletes();
    final result = <Map<String, dynamic>>[];
    for (final athlete in athletes) {
      final latestSub = athlete.id != null ? await getLatestSubscription(athlete.id!) : null;
      result.add({
        'athlete': athlete,
        'latestSubscription': latestSub,
      });
    }
    return result;
  }

  Future<void> deleteBodyMeasurement(int id) async {
    final db = await database;
    await db.delete('body_measurements', where: 'id = ?', whereArgs: [id]);
    await syncToExternal();
  }

  // ─── Stats ───────────────────

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final total = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM athletes')) ?? 0;
    final active = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(DISTINCT a.id) FROM athletes a JOIN subscriptions s ON a.id = s.athlete_id WHERE s.end_date >= ? AND a.is_active = 1',
      [now],
    )) ?? 0;
    final expired = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(DISTINCT a.id) FROM athletes a JOIN subscriptions s ON a.id = s.athlete_id WHERE s.end_date < ? AND a.is_active = 1',
      [now],
    )) ?? 0;
    return {'total': total, 'active': active, 'expired': expired, 'expiring': 0};
  }

  Future<double> getTotalRevenue() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COALESCE(SUM(price), 0) as total FROM subscriptions WHERE is_paid = 1');
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMonthlyRevenue() async {
    final db = await database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(price), 0) as total FROM subscriptions WHERE is_paid = 1 AND payment_date >= ? AND payment_date <= ?',
      [monthStart, monthEnd],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ─── Price Fix ───────────────────

  Future<void> fixPrices3000To1500() async {
    final db = await database;
    await db.rawUpdate('UPDATE subscriptions SET price = 1500.0 WHERE price = 3000.0');
    await syncToExternal();
  }
}
