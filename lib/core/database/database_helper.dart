import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../constants/db_constants.dart';
import '../utils/app_logger.dart';

/// SQLite Database Singleton managing connection lifecycle, schema initialization,
/// migrations, and transaction execution.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Returns the singleton database instance, initializing it if not already open.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Facilitates dependency injection for automated testing with in-memory SQLite.
  static void setDatabaseForTesting(Database? testDb) {
    _database = testDb;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, DbConstants.databaseName);

      AppLogger.info(
        'Initializing SQLite database at: $path',
        'DatabaseHelper',
      );

      return await openDatabase(
        path,
        version: DbConstants.databaseVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to open database', e, stack, 'DatabaseHelper');
      rethrow;
    }
  }

  /// Enforce SQLite foreign key constraints.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    AppLogger.info('SQLite foreign keys enabled', 'DatabaseHelper');
  }

  /// Create database tables and indexes on first initialization.
  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info(
      'Creating database tables for version $version',
      'DatabaseHelper',
    );
    await createSchema(db);
  }

  /// Public schema creation method used for production and in-memory testing.
  static Future<void> createSchema(Database db) async {
    final batch = db.batch();

    // 1. Table: tasks
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableTasks} (
        ${DbConstants.colTaskId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colTaskTitle} TEXT NOT NULL,
        ${DbConstants.colTaskDescription} TEXT,
        ${DbConstants.colTaskPriority} TEXT NOT NULL DEFAULT 'medium',
        ${DbConstants.colTaskCategory} TEXT DEFAULT 'Personal',
        ${DbConstants.colTaskDueDate} TEXT,
        ${DbConstants.colTaskDueTime} TEXT,
        ${DbConstants.colTaskIsRecurring} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colTaskRecurrenceType} TEXT DEFAULT 'none',
        ${DbConstants.colTaskIsCompleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colTaskReminderTime} TEXT,
        ${DbConstants.colTaskCreatedAt} TEXT NOT NULL,
        ${DbConstants.colTaskUpdatedAt} TEXT NOT NULL
      );
    ''');

    // 2. Table: task_occurrences
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableTaskOccurrences} (
        ${DbConstants.colOccId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colOccTaskId} INTEGER NOT NULL,
        ${DbConstants.colOccDate} TEXT NOT NULL,
        ${DbConstants.colOccIsCompleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colOccCompletedAt} TEXT,
        ${DbConstants.colOccNotes} TEXT,
        ${DbConstants.colOccCreatedAt} TEXT NOT NULL,
        ${DbConstants.colOccUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colOccTaskId}) REFERENCES ${DbConstants.tableTasks} (${DbConstants.colTaskId}) ON DELETE CASCADE,
        UNIQUE(${DbConstants.colOccTaskId}, ${DbConstants.colOccDate})
      );
    ''');

    // 3. Table: activities
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableActivities} (
        ${DbConstants.colActId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colActTitle} TEXT NOT NULL,
        ${DbConstants.colActDescription} TEXT,
        ${DbConstants.colActCategory} TEXT DEFAULT 'Personal',
        ${DbConstants.colActScheduledTime} TEXT,
        ${DbConstants.colActReminderEnabled} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colActIcon} TEXT,
        ${DbConstants.colActColor} TEXT,
        ${DbConstants.colActTargetFrequency} TEXT NOT NULL DEFAULT 'daily',
        ${DbConstants.colActTargetValue} INTEGER NOT NULL DEFAULT 1,
        ${DbConstants.colActUnit} TEXT DEFAULT 'times',
        ${DbConstants.colActIsActive} INTEGER NOT NULL DEFAULT 1,
        ${DbConstants.colActCreatedAt} TEXT NOT NULL,
        ${DbConstants.colActUpdatedAt} TEXT NOT NULL
      );
    ''');

    // 4. Table: activity_occurrences
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableActivityOccurrences} (
        ${DbConstants.colActOccId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbConstants.colActOccActivityId} INTEGER NOT NULL,
        ${DbConstants.colActOccDate} TEXT NOT NULL,
        ${DbConstants.colActOccStatus} TEXT NOT NULL DEFAULT 'pending',
        ${DbConstants.colActOccIsCompleted} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colActOccActualValue} INTEGER NOT NULL DEFAULT 0,
        ${DbConstants.colActOccCompletedAt} TEXT,
        ${DbConstants.colActOccNotes} TEXT,
        ${DbConstants.colActOccCreatedAt} TEXT NOT NULL,
        ${DbConstants.colActOccUpdatedAt} TEXT NOT NULL,
        FOREIGN KEY (${DbConstants.colActOccActivityId}) REFERENCES ${DbConstants.tableActivities} (${DbConstants.colActId}) ON DELETE CASCADE,
        UNIQUE(${DbConstants.colActOccActivityId}, ${DbConstants.colActOccDate})
      );
    ''');

    // 5. Table: app_settings
    batch.execute('''
      CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
        ${DbConstants.colSettingKey} TEXT PRIMARY KEY,
        ${DbConstants.colSettingValue} TEXT NOT NULL
      );
    ''');

    // Indexes for high-performance date-based queries
    batch.execute('''
      CREATE INDEX IF NOT EXISTS ${DbConstants.idxTasksDueDate} 
      ON ${DbConstants.tableTasks} (${DbConstants.colTaskDueDate});
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS ${DbConstants.idxTaskOccDate} 
      ON ${DbConstants.tableTaskOccurrences} (${DbConstants.colOccDate});
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS ${DbConstants.idxTaskOccTaskId} 
      ON ${DbConstants.tableTaskOccurrences} (${DbConstants.colOccTaskId});
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS ${DbConstants.idxActOccDate} 
      ON ${DbConstants.tableActivityOccurrences} (${DbConstants.colActOccDate});
    ''');

    batch.execute('''
      CREATE INDEX IF NOT EXISTS ${DbConstants.idxActOccActId} 
      ON ${DbConstants.tableActivityOccurrences} (${DbConstants.colActOccActivityId});
    ''');

    await batch.commit(noResult: true);
    AppLogger.info(
      'Database schema and indexes created successfully',
      'DatabaseHelper',
    );
  }

  /// Incremental database migration handler.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info(
      'Migrating database from version $oldVersion to $newVersion',
      'DatabaseHelper',
    );
    for (int v = oldVersion + 1; v <= newVersion; v++) {
      final migration = _migrations[v];
      if (migration != null) {
        await migration(db);
        AppLogger.info('Executed migration to version $v', 'DatabaseHelper');
      }
    }
  }

  /// Version migration registry.
  static final Map<int, Future<void> Function(Database db)> _migrations = {
    2: (db) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DbConstants.tableAppSettings} (
          ${DbConstants.colSettingKey} TEXT PRIMARY KEY,
          ${DbConstants.colSettingValue} TEXT NOT NULL
        );
      ''');
    },
    3: (db) async {
      await db.execute('''
        ALTER TABLE ${DbConstants.tableActivities} 
        ADD COLUMN ${DbConstants.colActScheduledTime} TEXT;
      ''');
      await db.execute('''
        ALTER TABLE ${DbConstants.tableActivities} 
        ADD COLUMN ${DbConstants.colActReminderEnabled} INTEGER NOT NULL DEFAULT 0;
      ''');
      await db.execute('''
        ALTER TABLE ${DbConstants.tableActivityOccurrences} 
        ADD COLUMN ${DbConstants.colActOccStatus} TEXT NOT NULL DEFAULT 'pending';
      ''');
      await db.execute('''
        UPDATE ${DbConstants.tableActivityOccurrences} 
        SET ${DbConstants.colActOccStatus} = 'completed' 
        WHERE ${DbConstants.colActOccIsCompleted} = 1;
      ''');
      await db.execute('''
        UPDATE ${DbConstants.tableActivityOccurrences} 
        SET ${DbConstants.colActOccStatus} = 'skipped' 
        WHERE ${DbConstants.colActOccNotes} = 'Skipped';
      ''');
    },
  };

  /// Helper to run an atomic transaction block.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return await db.transaction<T>(action);
  }

  /// Closes database connection cleanly.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      AppLogger.info('Database connection closed', 'DatabaseHelper');
    }
  }
}
