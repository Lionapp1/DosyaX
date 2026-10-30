import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../models/file_item.dart';
import '../services/storage_service.dart';

class BrowserController extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;

  String _currentPath = '';
  String _rootPath = '';
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
  String get rootPath => _rootPath;
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

  bool get canGoUp {
    if (_currentPath.isEmpty || _rootPath.isEmpty) return false;
    if (_currentPath == _rootPath) return false;
    final parent = p.dirname(_currentPath);
    return parent.isNotEmpty && parent != _currentPath;
  }

  /// System back: cancel select → go up folder → false if at root.
  Future<bool> handleSystemBack() async {
    if (_selectMode) {
      toggleSelectMode(false);
      return true;
    }
    if (canGoUp) {
      await goUp();
      return true;
    }
    return false;
  }

  Future<void> init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _storage.quickPaths(),
        _storage.startPath,
        _storage.primaryRoot,
      ]);
      _quick = results[0] as Map<String, String>;
      _currentPath = results[1] as String;
      _rootPath = results[2] as String;
      await refresh(force: true);
    } catch (e) {
      _error = 'Depolama acilamadi';
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh({bool force = false}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _storage.listDirectory(
        _currentPath,
        sortBy: _sortBy,
        ascending: _ascending,
        filterKind: _filterKind,
        forceRefresh: force,
      );
      _applyQuery();
      _selected.removeWhere((id) => !_items.any((i) => i.id == id));
      _loading = false;
      notifyListeners();
    } catch (_) {
      _error = 'Klasor okunamadi';
      _items = [];
      _visible = [];
      _loading = false;
      notifyListeners();
    }
  }

  void _applyQuery() {
    if (_query.isEmpty) {
      _visible = List.of(_items);
    } else {
      final q = _query.toLowerCase();
      _visible =
          _items.where((i) => i.name.toLowerCase().contains(q)).toList();
    }
  }

  Future<void> openPath(String path) async {
    if (path == _currentPath && _items.isNotEmpty) return;
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
    _applyQuery();
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
    refresh(force: true);
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
    _selectMode = _selected.isNotEmpty;
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
    await refresh(force: true);
  }

  Future<void> shareSelected() async {
    final files = selectedItems.where((i) => !i.isFolder).toList();
    for (final f in files) {
      await _storage.share(f);
    }
  }

  Future<bool> renameItem(FileItem item, String newName) async {
    final ok = await _storage.rename(item, newName);
    if (ok) await refresh(force: true);
    return ok;
  }

  Future<bool> createFolder(String name) async {
    final ok = await _storage.createFolder(_currentPath, name);
    if (ok) await refresh(force: true);
    return ok;
  }

  Future<void> goUp() async {
    if (!canGoUp) return;
    final parent = p.dirname(_currentPath);
    if (parent.isEmpty || parent == _currentPath) return;
    // Don't go above root
    if (_rootPath.isNotEmpty &&
        parent.length < _rootPath.length &&
        !_rootPath.startsWith(parent)) {
      await openPath(_rootPath);
      return;
    }
    await openPath(parent);
  }
}
