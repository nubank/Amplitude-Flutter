part of '../storage_datasource.dart';

/// {@template object_store}
/// Persistent storage for events using ObjectBox
/// {@endtemplate}
final class ObjectStore extends StorageDatasource<EventEntity> {
  /// {@macro object_store}
  /// Singleton factory constructor for ObjectStore instances
  /// Uses [storeName] as the ObjectBox store directory name
  /// Multiple instances can be created with different [storeName] values
  factory ObjectStore({
    String storeName = _defaultStoreName,
  }) =>
      _instances.putIfAbsent(storeName, () => ObjectStore._(storeName));

  /// Private constructor for ObjectStore
  ObjectStore._(this.storeName) {
    _storeFuture = _init();
  }

  static final Map<String, ObjectStore> _instances = {};
  Store? _store;
  Box<EventEntity>? _eventBox;
  final String storeName;

  @override
  int length = 0;

  static const _defaultStoreName = 'nubank_obx';

  /// Cached Future for store initialization to avoid multiple awaits
  late final Future<Store?> _storeFuture;

  @override
  Future<int> add(EventEntity event) async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return 0;
    }
    try {
      final id = box.put(event);
      length++;
      return id;
    } catch (ex) {
      return 0;
    }
  }

  @override
  Future<List<EventEntity?>> addAll(List<EventEntity> events) async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return [];
    }
    try {
      box.putMany(events);
      length += events.length;
      return events;
    } catch (ex) {
      return [];
    }
  }

  @override
  Future<void> empty() async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return;
    }
    try {
      box.removeAll();
      length = 0;
    } catch (ex) {
      return;
    }
  }

  @override
  Future<int?> count() async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return null;
    }
    try {
      return length = box.count();
    } catch (ex) {
      return null;
    }
  }

  @override
  Future<void> drop(int count) async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return;
    }
    try {
      final query = box.query().order(EventEntity_.id).build();
      final oldestEvents = query.find();
      query.close();
      final idsToRemove = oldestEvents.take(count).map((e) => e.id).toList();
      if (idsToRemove.isNotEmpty) {
        final removedCount = box.removeMany(idsToRemove);
        length -= removedCount;
      }
    } catch (ex) {
      return;
    }
  }

  @override
  Future<void> delete(List<int?> eventIds) async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return;
    }
    try {
      final validIds = eventIds.whereType<int>().toList();
      if (validIds.isNotEmpty) {
        final removedCount = box.removeMany(validIds);
        length -= removedCount;
      }
    } catch (ex) {
      return;
    }
  }

  @override
  Future<List<EventEntity>> fetch(int count) async {
    final box = _eventBox ?? await _getBox();
    if (box == null) {
      return [];
    }
    try {
      final query = box.query().order(EventEntity_.id).build();
      query.limit = count;
      final entities = query.find();
      query.close();
      return entities;
    } catch (ex) {
      return [];
    }
  }

  Future<Store?> _init() async {
    final store = await _openStore();
    if (store != null) {
      _eventBox = store.box<EventEntity>();
      length = _eventBox!.count();
    }
    _store = store;
    return _store;
  }

  /// Returns cached box instance or waits for initialization
  /// After first call, _eventBox is always non-null, so this becomes synchronous
  Future<Box<EventEntity>?> _getBox() async {
    if (_eventBox != null) {
      return _eventBox;
    }
    await _storeFuture;
    return _eventBox;
  }

  Future<Store?> _openStore() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storePath = path.join(dir.path, storeName);
      return await openStore(directory: storePath);
    } catch (e) {
      return Future.value(null);
    }
  }

  void close() {
    _store?.close();
  }
}
