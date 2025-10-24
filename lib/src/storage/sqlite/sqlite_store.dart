part of '../storage_datasource.dart';

/// {@template store}
/// Persistent storage for events using SQLite
/// {@endtemplate}
final class SqliteStore extends StorageDatasource<Event> {
  /// {@macro store}
  /// Singleton factory constructor for SqliteStore instances
  /// Uses [dbFile] as the database file name
  /// If [enableUuid] is true, events will be stored with UUIDs
  /// Otherwise, events will be stored without UUIDs
  /// Multiple instances can be created with different [dbFile] names
  factory SqliteStore({
    String dbFile = _defaultDbName,
    bool enableUuid = true,
  }) =>
      _instances.putIfAbsent(dbFile, () => SqliteStore._(dbFile, enableUuid));

  SqliteStore._(this.dbFile, this.enableUuid) {
    _dbFuture = _init();
  }

  bool enableUuid;
  static final Map<String, SqliteStore> _instances = {};
  Database? _db;
  final String dbFile;
  @override
  int length = 0;

  static const _eventsTable = 'events';
  static const _colId = 'id';
  static const _colEventType = 'event_type';
  static const _colTimestamp = 'timestamp';
  static const _colSessionId = 'session_id';
  static const _colProps = 'props_json';
  static const _defaultDbName = 'amp.db';

  /// Cached Future for database initialization to avoid multiple awaits
  late final Future<Database?> _dbFuture;

  /// Adds a raw event hash to the store
  @override
  Future<int> add(Event event) async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return 0;
    }
    try {
      final result = await db.insert(_eventsTable, _serialize(event));
      length++;
      return result;
    } catch (ex) {
      return 0;
    }
  }

  /// Adds multiple events to the store
  @override
  Future<List<Event?>> addAll(List<Event> events) async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return [];
    }
    try {
      final batch = db.batch();
      for (final event in events) {
        batch.insert(_eventsTable, _serialize(event));
        length++;
      }
      await batch.commit(noResult: true);
      return events;
    } catch (ex) {
      return [];
    }
  }

  /// Empties the store
  @override
  Future<void> empty() async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return;
    }
    try {
      await db.rawDelete('DELETE FROM $_eventsTable; VACUUM;');
      length = 0;
    } catch (ex) {
      return;
    }
  }

  /// Counts the number of events in the store
  @override
  Future<int?> count() async {
    final db = _db ?? await _getDb();
    return _count(db);
  }

  /// Drops a specified number of events from the store
  @override
  Future<void> drop(int count) async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return;
    }
    try {
      final resultCount = await db.rawDelete(
          'DELETE FROM $_eventsTable WHERE ROWID IN (SELECT ROWID FROM $_eventsTable LIMIT ?)',
          [count]);
      length -= resultCount;
    } catch (ex) {
      return;
    }
  }

  /// Deletes events with specified IDs from the store
  @override
  Future<void> delete(List<int?> eventIds) async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return;
    }
    try {
      final placeholders = List.filled(eventIds.length, '?').join(',');
      final count = await db.rawDelete(
          'DELETE FROM $_eventsTable WHERE id IN ($placeholders)', eventIds);
      length -= count;
    } catch (ex) {
      return;
    }
  }

  /// Fetches a specified number of oldest events from the store
  @override
  Future<List<Event>> fetch(int count) async {
    final db = _db ?? await _getDb();
    if (db == null) {
      return [];
    }
    try {
      final records =
          await db.query(_eventsTable, limit: count, orderBy: _colId);
      return records.map((m) => _deserialize(m)).toList();
    } catch (ex) {
      return [];
    }
  }

  Future<Database?> _init() async {
    final db = await _openDb();
    length = await _count(db);
    _db = db;
    return _db;
  }

  /// Returns cached database instance or waits for initialization
  /// After first call, _db is always non-null, so this becomes synchronous
  Future<Database?> _getDb() async {
    if (_db != null) {
      return _db;
    }
    return await _dbFuture;
  }

  Future<Database?> _openDb() async {
    try {
      final String dir = await getDatabasesPath();
      final String dbPath = path.join(dir, dbFile);

      final createDb = (Database db, int version) async {
        await db.execute('''
          create table $_eventsTable (
            $_colId integer primary key autoincrement,
            $_colEventType text not null,
            $_colSessionId text,
            $_colTimestamp integer,
            $_colProps text
          )
        ''');
      };
      return await openDatabase(dbPath, version: 1, onCreate: createDb);
    } catch (e) {
      return Future.value(null);
    }
  }

  Future<int> _count(Database? db) async {
    if (db == null) {
      return 0;
    }
    try {
      final List<Map<String, dynamic>> rows =
          await db.rawQuery('SELECT COUNT(*) as count FROM $_eventsTable');
      return rows.single['count'];
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> _serialize(Event e) => {
        _colEventType: e.name,
        _colProps: json.encode(e.props),
      };

  Event _deserialize(Map<String, dynamic> map) =>
      Event(map[_colEventType], properties: json.decode(map[_colProps]));
}
