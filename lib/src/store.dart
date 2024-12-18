import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'event.dart';

const String EVENTS_TABLE = 'events';
const String COL_ID = 'id';
const String COL_EVENT_TYPE = 'event_type';
const String COL_TIMESTAMP = 'timestamp';
const String COL_SESSION_ID = 'session_id';
const String COL_PROPS = 'props_json';
const String DEFAULT_DB_NAME = 'amp.db';

class Store {
  factory Store({String dbFile = DEFAULT_DB_NAME}) =>
      _instances.putIfAbsent(dbFile, () => Store._(dbFile));

  Store._(this.dbFile) {
    _init();
  }

  static final Map<String, Store> _instances = {};
  Database? _db;
  final String dbFile;
  int length = 0;

  Future<int> add(Event event) async {
    final db = await _getDb();
    if (db == null) {
      return 0;
    }

    try {
      final result = await db.insert(EVENTS_TABLE, _serialize(event));
      length++;
      return result;
    } catch (ex) {
      return 0;
    }
  }

  Future<List<Object?>> addAll(List<Event> events) async {
    final db = await _getDb();
    if (db == null) {
      return [];
    }

    try {
      final batch = db.batch();
      for (final event in events) {
        batch.insert(EVENTS_TABLE, _serialize(event));
        length++;
      }
      return await batch.commit(noResult: true);
    } catch (ex) {
      return [];
    }
  }

  Future<void> empty() async {
    final db = await _getDb();
    if (db == null) {
      return;
    }

    try {
      await db.rawDelete('DELETE FROM $EVENTS_TABLE; VACUUM;');
      length = 0;
    } catch (ex) {
      return;
    }
  }

  Future<int?> count() async {
    final db = await _getDb();
    return _count(db);
  }

  Future<void> drop(int count) async {
    final db = await _getDb();
    if (db == null) {
      return;
    }

    try {
      final resultCount = await db.rawDelete(
          'DELETE FROM $EVENTS_TABLE WHERE $COL_ID IN (SELECT T2.$COL_ID FROM $EVENTS_TABLE T2 ORDER BY T2.$COL_ID LIMIT $count)');
      length -= resultCount;
    } catch (ex) {
      return;
    }
  }

  Future<void> delete(List<int?> eventIds) async {
    final db = await _getDb();
    if (db == null) {
      return;
    }

    try {
      final count = await db.rawDelete(
          'DELETE FROM $EVENTS_TABLE WHERE id IN (${eventIds.join(',')})');
      length -= count;
    } catch (ex) {
      return;
    }
  }

  Future<List<Event>> fetch(int count) async {
    final db = await _getDb();
    if (db == null) {
      return [];
    }

    try {
      final records =
          await db.query(EVENTS_TABLE, limit: count, orderBy: COL_ID);
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
          create table $EVENTS_TABLE (
            $COL_ID integer primary key autoincrement,
            $COL_EVENT_TYPE text not null,
            $COL_SESSION_ID text,
            $COL_TIMESTAMP integer,
            $COL_PROPS text
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
          await db.rawQuery('SELECT COUNT(*) as count FROM $EVENTS_TABLE');
      return rows.single['count'];
    } catch (e) {
      return 0;
    }
  }

  Map<String, dynamic> _serialize(Event e) {
    return <String, dynamic>{}
      ..[COL_EVENT_TYPE] = e.name
      ..[COL_SESSION_ID] = e.sessionId
      ..[COL_TIMESTAMP] = e.timestamp
      ..[COL_PROPS] = json.encode(e.props);
  }

  Event _deserialize(Map<String, dynamic> map) => Event(map[COL_EVENT_TYPE],
      sessionId: map[COL_SESSION_ID],
      timestamp: map[COL_TIMESTAMP],
      id: map[COL_ID],
      props: json.decode(map[COL_PROPS]));
}
