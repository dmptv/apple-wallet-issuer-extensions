import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and the schema.
///
/// Kept as a plain class rather than a code-generated ORM so that every query
/// in this project is visible SQL. The trade-off is real and worth stating out
/// loud: `drift` would give compile-time-checked queries and typed row classes,
/// at the cost of a generated layer you have to trust. For a codebase whose
/// point is to be read, visible SQL wins; for a large team shipping daily,
/// drift's type safety usually wins.
class AppDatabase {
  AppDatabase({this._databaseName = 'bank_app.db'});

  final String _databaseName;
  Database? _db;

  /// Opened lazily and memoised.
  ///
  /// Note the single-flight problem this *would* have if `openDatabase` were
  /// awaited without storing the Future first: two concurrent callers could
  /// both see `_db == null` and open the database twice. Storing the in-flight
  /// Future (not the result) is what makes this safe — the same pattern as the
  /// refresh dedup in `AuthInterceptor`.
  Future<Database>? _opening;

  Future<Database> get database async {
    final ready = _db;
    if (ready != null) return ready;

    final inFlight = _opening;
    if (inFlight != null) return inFlight;

    final future = _open();
    _opening = future;
    try {
      final db = await future;
      _db = db;
      return db;
    } finally {
      _opening = null;
    }
  }

  Future<Database> _open() async {
    final directory = await getDatabasesPath();
    return openDatabase(
      p.join(directory, _databaseName),
      version: _schemaVersion,
      onCreate: (db, version) async => _createSchema(db),
      onUpgrade: _migrate,
      // Foreign keys are OFF by default in SQLite and must be enabled per
      // connection — a classic source of "my cascade delete does nothing".
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  static const _schemaVersion = 1;

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE cards (
        id                TEXT PRIMARY KEY,
        display_name      TEXT NOT NULL,
        last_digits       TEXT NOT NULL,
        expiry            TEXT NOT NULL,
        payment_network   TEXT NOT NULL,
        state             TEXT NOT NULL,
        balance_minor     INTEGER NOT NULL,
        currency          TEXT NOT NULL,
        cached_at         INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id             TEXT PRIMARY KEY,
        card_id        TEXT NOT NULL,
        title          TEXT NOT NULL,
        amount_minor   INTEGER NOT NULL,
        currency       TEXT NOT NULL,
        occurred_at    INTEGER NOT NULL,
        category       TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
      )
    ''');

    // The transaction list is always read as "this card, newest first".
    // Without this index that query degrades to a full scan plus a sort as
    // soon as the table grows — the kind of thing that only shows up on a
    // real user's device, months in.
    await db.execute(
      'CREATE INDEX idx_tx_card_date ON transactions (card_id, occurred_at DESC)',
    );
  }

  /// Migrations are additive and versioned. Each `if` block moves the schema
  /// forward exactly one version, so a user upgrading from v1 to v4 replays
  /// every step in order.
  Future<void> _migrate(Database db, int oldVersion, int newVersion) async {
    // Example of the shape future migrations take:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE cards ADD COLUMN nickname TEXT');
    // }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
