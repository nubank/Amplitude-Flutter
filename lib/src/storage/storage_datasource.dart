import 'dart:convert';

import 'package:amplitude_flutter/amplitude_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

part './objectbox/object_store.dart';
part 'sqlite/sqlite_store.dart';

/// {@template StorageDatasource}
/// Abstract class defining the interface for storage datasources used to
/// persist events locally before they are sent to the Amplitude servers.
/// Implementations can vary, such as using ObjectBox or SQLite.
/// {@endtemplate}
sealed class StorageDatasource<T> {
  /// getter for the number of stored items
  int get length;

  /// Adds a raw item to the store
  Future<int> add(T item);

  /// Adds multiple items to the store
  Future<List<T?>> addAll(List<T> items);

  /// Empties the store
  Future<void> empty();

  /// Counts the number of items in the store
  Future<int?> count();

  /// Fetches a specified number of items from the store
  Future<List<T>> fetch(int count);

  /// Drops a specified number of items from the store
  Future<void> drop(int count);

  /// Deletes items from the store by their event IDs
  Future<void> delete(List<int?> eventIds);
}
