import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'event.dart';

const String eventsTable = 'events';
const String colId = 'id';
const String colEventType = 'event_type';
const String colTimestamp = 'timestamp';
const String colSessionId = 'session_id';
const String colProps = 'props_json';
const String defaultDbName = 'amp.db';

/// {@template store}
/// Persistent storage for events using SQLite
/// {@endtemplate}
class Store {
  /// {@macro store}
  /// Singleton factory constructor for Store instances
  /// Uses [dbFile] as the database file name
  /// If [enableUuid] is true, events will be stored with UUIDs
  /// Otherwise, events will be stored without UUIDs
  /// Multiple instances can be created with different [dbFile] names
  factory Store({
    String dbFile = defaultDbName,
    bool enableUuid = true,
  }) =>
      _instances.putIfAbsent(dbFile, () => Store._(dbFile, enableUuid));

  Store._(this.dbFile, this.enableUuid) {
    _init();
  }

  bool enableUuid;
  static final Map<String, Store> _instances = {};
  Database? _db;
  final String dbFile;
  int length = 0;

  /// Adds a raw event hash to the store
  Future<int> add(Event event) async {
    final db = await _getDb();
    if (db == null) {
      return 0;
    }
    try {
      final result = await db.insert(eventsTable, _serialize(event));
      length++;
      return result;
    } catch (ex) {
      return 0;
    }
  }

  /// Adds multiple events to the store
  Future<List<Object?>> addAll(List<Event> events) async {
    final db = await _getDb();
    if (db == null) {
      return [];
    }
    try {
      final batch = db.batch();
      for (final event in events) {
        batch.insert(eventsTable, _serialize(event));
        length++;
      }
      return await batch.commit(noResult: true);
    } catch (ex) {
      return [];
    }
  }

  /// Empties the store
  Future<void> empty() async {
    final db = await _getDb();
    if (db == null) {
      return;
    }
    try {
      await db.rawDelete('DELETE FROM $eventsTable; VACUUM;');
      length = 0;
    } catch (ex) {
      return;
    }
  }

  /// Counts the number of events in the store
  Future<int?> count() async {
    final db = await _getDb();
    return _count(db);
  }

  /// Drops a specified number of events from the store
  Future<void> drop(int count) async {
    final db = await _getDb();
    if (db == null) {
      return;
    }
    try {
      final resultCount = await db.rawDelete(
          'DELETE FROM $eventsTable WHERE ROWID IN (SELECT ROWID FROM $eventsTable LIMIT ?)',
          [count]);
      length -= resultCount;
    } catch (ex) {
      return;
    }
  }

  /// Deletes events with specified IDs from the store
  Future<void> delete(List<int?> eventIds) async {
    final db = await _getDb();
    if (db == null) {
      return;
    }
    try {
      final placeholders = List.filled(eventIds.length, '?').join(',');
      final count = await db.rawDelete(
          'DELETE FROM $eventsTable WHERE id IN ($placeholders)', eventIds);
      length -= count;
    } catch (ex) {
      return;
    }
  }

  /// Fetches a specified number of oldest events from the store
  Future<List<Event>> fetch(int count) async {
    final db = await _getDb();
    if (db == null) {
      return [];
    }
    try {
      final records = await db.query(eventsTable, limit: count, orderBy: colId);
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

  Future<Database?> _getDb() async {
    if (_db != null) {
      return _db;
    }
    return await _init();
  }

  Future<Database?> _openDb() async {
    try {
      final String dir = await getDatabasesPath();
      final String dbPath = path.join(dir, dbFile);

      final createDb = (Database db, int version) async {
        await db.execute('''
          create table $eventsTable (
            $colId integer primary key autoincrement,
            $colEventType text not null,
            $colSessionId text,
            $colTimestamp integer,
            $colProps text
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
          await db.rawQuery('SELECT COUNT(*) as count FROM $eventsTable');
      return rows.single['count'];
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> _serialize(Event e) => {
        colEventType: e.name,
        colSessionId: e.sessionId,
        colTimestamp: e.timestamp,
        colProps: json.encode(e.props),
      };

  Event _deserialize(Map<String, dynamic> map) => enableUuid
      ? Event.uuid(map[colEventType],
          sessionId: map[colSessionId],
          timestamp: map[colTimestamp],
          id: map[colId],
          props: json.decode(map[colProps]))
      : Event.noUuid(map[colEventType],
          sessionId: map[colSessionId],
          timestamp: map[colTimestamp],
          id: map[colId],
          props: json.decode(map[colProps]));
}
