import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/file_item.dart';
import '../services/storage_service.dart';

class BrowserController extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  String _currentPath = '';
  List<FileItem> _items = [];
  List<FileItem> _visible = [];
  final Set<String> _selected = {};
  bool _loading = true;
  String? _error;
  bool _grid = true;
  String _query = '';
  SortBy _sortBy = SortBy.name;
  bool _ascending = true;
  FileKind? _filterKind;
  Map<String, String> _quick = {};
  bool _selectMode = false;

  String get currentPath => _currentPath;
  List<FileItem> get items => _visible;
  Set<String> get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;
  bool get grid => _grid;
  String get query => _query;
  SortBy get sortBy => _sortBy;
  bool get ascending => _ascending;
  FileKind? get filterKind => _filterKind;
  Map<String, String> get quick => _quick;
  bool get selectMode => _selectMode;
  int get selectedCount => _selected.length;

  List<String> get breadcrumbs {
    if (_currentPath.isEmpty) return [];
    final parts = p.split(_currentPath).where((e) => e.isNotEmpty).toList();
    return parts;
  }

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _quick = await _storage.quickPaths();
      _currentPath = await _storage.primaryRoot;
      await refresh();
    } catch (e) {
      _error = 'Depolama acilamadi: $e';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _storage.listDirectory(
        _currentPath,
        sortBy: _sortBy,
        ascending: _ascending,
        query: _query,
        filterKind: _filterKind,
      );
      _visible = List.of(_items);
      _selected.removeWhere((id) => !_items.any((i) => i.id == id));
      _loading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Klasor okunamadi';
      _items = [];
      _visible = [];
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> openPath(String path) async {
    _currentPath = path;
    _query = '';
    _selectMode = false;
    _selected.clear();
    await refresh();
  }

  Future<void> openItem(FileItem item) async {
    if (item.isFolder) {
      await openPath(item.path);
      return;
    }
    await _storage.open(item);
  }

  void setQuery(String q) {
    _query = q;
    // local filter for snappy search
    if (q.isEmpty) {
      _visible = List.of(_items);
    } else {
      final lower = q.toLowerCase();
      _visible =
          _items.where((i) => i.name.toLowerCase().contains(lower)).toList();
    }
    notifyListeners();
  }

  void setSort(SortBy by) {
    if (_sortBy == by) {
      _ascending = !_ascending;
    } else {
      _sortBy = by;
      _ascending = true;
    }
    refresh();
  }

  void setFilter(FileKind? kind) {
    _filterKind = kind;
    refresh();
  }

  void toggleGrid() {
    _grid = !_grid;
    notifyListeners();
  }

  void toggleSelectMode([bool? value]) {
    _selectMode = value ?? !_selectMode;
    if (!_selectMode) _selected.clear();
    notifyListeners();
  }

  void toggleSelect(FileItem item) {
    if (_selected.contains(item.id)) {
      _selected.remove(item.id);
    } else {
      _selected.add(item.id);
    }
    if (_selected.isEmpty) {
      _selectMode = false;
    } else {
      _selectMode = true;
    }
    notifyListeners();
  }

  void selectAll() {
    _selected
      ..clear()
      ..addAll(_visible.map((e) => e.id));
    _selectMode = true;
    notifyListeners();
  }

  List<FileItem> get selectedItems =>
      _visible.where((i) => _selected.contains(i.id)).toList();

  Future<void> deleteSelected() async {
    for (final item in selectedItems) {
      await _storage.delete(item);
    }
    _selected.clear();
    _selectMode = false;
    await refresh();
  }

  Future<void> shareSelected() async {
    final files = selectedItems.where((i) => !i.isFolder).toList();
    for (final f in files) {
      await _storage.share(f);
    }
  }

  Future<bool> renameItem(FileItem item, String newName) async {
    final ok = await _storage.rename(item, newName);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> createFolder(String name) async {
    final ok = await _storage.createFolder(_currentPath, name);
    if (ok) await refresh();
    return ok;
  }

  Future<void> goUp() async {
    final root = await _storage.primaryRoot;
    if (_currentPath == root) return;
    final parent = p.dirname(_currentPath);
    if (parent.isEmpty || parent == _currentPath) return;
    await openPath(parent);
  }
}
