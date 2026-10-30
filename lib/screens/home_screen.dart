import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/file_item.dart';
import '../services/app_settings.dart';
import '../services/private_vault.dart';
import '../services/social_folders_service.dart';
import '../services/storage_service.dart';
import '../services/transfer_service.dart';
import '../state/browser_controller.dart';
import '../widgets/file_tile.dart';
import '../widgets/path_breadcrumbs.dart';
import '../widgets/quick_chip.dart';
import 'image_viewer_screen.dart';
import 'video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late final BrowserController _browser;
  final _searchCtrl = TextEditingController();

  /// Called from ShellScreen system back.
  Future<bool> handleSystemBack() => _browser.handleSystemBack();

  @override
  void initState() {
    super.initState();
    _browser = BrowserController();
    _browser.init();
    SocialFoldersService.instance.ensureCreated().then((_) {
      _browser.init();
    });
    if (!AppSettings.instance.preferGrid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!AppSettings.instance.preferGrid && _browser.grid) {
          _browser.toggleGrid();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _browser.dispose();
    super.dispose();
  }

  Future<void> _openMedia(FileItem item) async {
    if (item.isFolder) {
      await _browser.openItem(item);
      return;
    }
    if (item.kind == FileKind.image) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImageViewerScreen(path: item.path, title: item.name),
        ),
      );
      return;
    }
    if (item.kind == FileKind.video) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(path: item.path, title: item.name),
        ),
      );
      return;
    }
    // Other types: try in-app share/open
    await StorageService.instance.open(item);
  }

  Future<void> _newFolder() async {
    final name = await _askText('Yeni klasor', 'Klasor adi');
    if (name == null || name.trim().isEmpty) return;
    final ok = await _browser.createFolder(name.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Klasor olusturuldu' : 'Olusturulamadi')),
    );
  }

  Future<void> _rename(FileItem item) async {
    final name =
        await _askText('Yeniden adlandir', item.name, initial: item.name);
    if (name == null || name.trim().isEmpty || name == item.name) return;
    final ok = await _browser.renameItem(item, name.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Ad degisti' : 'Basarisiz')),
    );
  }

  Future<String?> _askText(String title, String hint, {String? initial}) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Iptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDestAndTransfer(FileItem item, TransferOp op) async {
    final social = await SocialFoldersService.instance.ensureCreated();
    final suggested =
        await SocialFoldersService.instance.suggestDestFor(item.path);
    if (!mounted) return;

    final dest = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final entries = social.entries.toList();
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: Icon(
                  op == TransferOp.move
                      ? Icons.drive_file_move_rounded
                      : Icons.copy_rounded,
                ),
                title: Text(
                  op == TransferOp.move ? 'Nereye tasinsin?' : 'Nereye kopyalansin?',
                ),
                subtitle: const Text('Arka planda devam eder'),
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Akilli hedef (sosyal)'),
                subtitle: Text(suggested, maxLines: 2),
                onTap: () => Navigator.pop(ctx, suggested),
              ),
              const Divider(),
              ...entries.map(
                (e) => ListTile(
                  leading: Icon(iconForQuickLabel(e.key)),
                  title: Text(e.key),
                  subtitle: Text(
                    e.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(ctx, e.value),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (dest == null) return;
    TransferService.instance.enqueue(
      sourcePath: item.path,
      destDir: dest,
      op: op,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          op == TransferOp.move
              ? 'Tasimaya alindi — arka planda'
              : 'Kopyalamaya alindi — arka planda',
        ),
      ),
    );
  }

  void _itemSheet(FileItem item) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  item.isFolder
                      ? Icons.folder_rounded
                      : Icons.insert_drive_file_rounded,
                  color: cs.primary,
                ),
                title: Text(item.name),
                subtitle: Text('${item.sizeLabel}\n${item.path}'),
              ),
              const Divider(height: 1),
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: const Text('Ac'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openMedia(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Kopyala'),
                subtitle: const Text('Arka plan kuyrugu'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDestAndTransfer(item, TransferOp.copy);
                },
              ),
              ListTile(
                leading: const Icon(Icons.drive_file_move_rounded),
                title: const Text('Tasi'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDestAndTransfer(item, TransferOp.move);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_location_rounded),
                title: const Text('Sosyal klasore akilli kopyala'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final dest = await SocialFoldersService.instance
                      .suggestDestFor(item.path);
                  TransferService.instance.enqueue(
                    sourcePath: item.path,
                    destDir: dest,
                    op: TransferOp.copy,
                  );
                },
              ),
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: const Text('Ozel alana kopyala'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final ok =
                        await PrivateVault.instance.importFile(item.path);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok ? 'Ozel alana kopyalandi' : 'Kopyalanamadi',
                        ),
                      ),
                    );
                  },
                ),
              if (!item.isFolder)
                ListTile(
                  leading: const Icon(Icons.share_rounded),
                  title: const Text('Paylas'),
                  onTap: () {
                    Navigator.pop(ctx);
                    StorageService.instance.share(item);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.drive_file_rename_outline_rounded),
                title: const Text('Yeniden adlandir'),
                onTap: () {
                  Navigator.pop(ctx);
                  _rename(item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_rounded),
                title: const Text('Yolu kopyala'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.path));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yol kopyalandi')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline_rounded, color: cs.error),
                title: Text('Sil', style: TextStyle(color: cs.error)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await StorageService.instance.delete(item);
                  if (ok) _browser.refresh(force: true);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar(BrowserController b, ColorScheme cs) {
    return AppBar(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      leading: b.selectMode
          ? IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => b.toggleSelectMode(false),
            )
          : IconButton(
              icon: Icon(
                b.canGoUp
                    ? Icons.arrow_back_rounded
                    : Icons.folder_rounded,
              ),
              tooltip: b.canGoUp ? 'Geri' : 'Kok',
              onPressed: b.canGoUp ? b.goUp : null,
            ),
      title: Text(
        b.selectMode
            ? '${b.selectedCount} secili'
            : (b.currentPath.isEmpty
                ? 'DosyaX'
                : b.currentPath.split('/').where((e) => e.isNotEmpty).last),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        if (b.selectMode) ...[
          IconButton(
            tooltip: 'Tumu',
            onPressed: b.selectAll,
            icon: const Icon(Icons.select_all_rounded),
          ),
          IconButton(
            tooltip: 'Paylas',
            onPressed: () => b.shareSelected(),
            icon: const Icon(Icons.share_rounded),
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Silinsin mi?'),
                  content: Text('${b.selectedCount} oge silinecek.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Iptal'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await b.deleteSelected();
            },
            icon: Icon(Icons.delete_outline_rounded, color: cs.error),
          ),
        ] else ...[
          IconButton(
            tooltip: b.grid ? 'Liste' : 'Izgara',
            onPressed: b.toggleGrid,
            icon: Icon(
              b.grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Sirala / Filtre',
            icon: const Icon(Icons.tune_rounded),
            onSelected: (v) {
              switch (v) {
                case 'name':
                  b.setSort(SortBy.name);
                case 'size':
                  b.setSort(SortBy.size);
                case 'date':
                  b.setSort(SortBy.modified);
                case 'all':
                  b.setFilter(null);
                case 'img':
                  b.setFilter(FileKind.image);
                case 'vid':
                  b.setFilter(FileKind.video);
                case 'doc':
                  b.setFilter(FileKind.document);
                case 'aud':
                  b.setFilter(FileKind.audio);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'name',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.sort_by_alpha),
                  title: Text('Ada gore'),
                ),
              ),
              PopupMenuItem(
                value: 'size',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.data_usage),
                  title: Text('Boyuta gore'),
                ),
              ),
              PopupMenuItem(
                value: 'date',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.schedule),
                  title: Text('Tarihe gore'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'all',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.apps),
                  title: Text('Tum turler'),
                ),
              ),
              PopupMenuItem(
                value: 'img',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.image),
                  title: Text('Resimler'),
                ),
              ),
              PopupMenuItem(
                value: 'vid',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.movie),
                  title: Text('Videolar'),
                ),
              ),
              PopupMenuItem(
                value: 'doc',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.description),
                  title: Text('Belgeler'),
                ),
              ),
              PopupMenuItem(
                value: 'aud',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.audiotrack),
                  title: Text('Ses'),
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: () => b.refresh(force: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _browser,
      child: Consumer<BrowserController>(
        builder: (context, b, _) {
          return Scaffold(
            backgroundColor: cs.surface,
            resizeToAvoidBottomInset: false,
            appBar: _appBar(b, cs),
            body: Column(
              children: [
                if (!b.selectMode && b.quick.isNotEmpty)
                  Container(
                    color: cs.surface,
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: b.quick.entries.map((e) {
                        final active = b.currentPath == e.value ||
                            b.currentPath.startsWith('${e.value}/');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: QuickChip(
                            label: e.key,
                            selected: active,
                            onTap: () => b.openPath(e.value),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                Container(
                  color: cs.surface,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PathBreadcrumbs(
                        path: b.currentPath,
                        rootPath: b.rootPath,
                        onTapSegment: b.openPath,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _searchCtrl,
                        onChanged: b.setQuery,
                        decoration: InputDecoration(
                          hintText: 'Bu klasorde ara...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: b.query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    b.setQuery('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor:
                              cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildBody(b, cs)),
              ],
            ),
            floatingActionButton: b.selectMode
                ? null
                : FloatingActionButton.extended(
                    onPressed: _newFolder,
                    icon: const Icon(Icons.create_new_folder_rounded),
                    label: const Text('Klasor'),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BrowserController b, ColorScheme cs) {
    if (b.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (b.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: cs.error),
              const SizedBox(height: 12),
              Text(b.error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => b.refresh(force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      );
    }
    if (b.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off_outlined, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text(
              'Bos klasor',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (b.grid) {
      return RefreshIndicator(
        onRefresh: () => b.refresh(force: true),
        child: GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
          ),
          itemCount: b.items.length,
          itemBuilder: (_, i) {
            final item = b.items[i];
            final sel = b.selected.contains(item.id);
            return FileTile(
              item: item,
              grid: true,
              selected: sel,
              selectMode: b.selectMode,
              onTap: () {
                if (b.selectMode) {
                  b.toggleSelect(item);
                } else {
                  _openMedia(item);
                }
              },
              onLongPress: () {
                if (b.selectMode) {
                  b.toggleSelect(item);
                } else {
                  _itemSheet(item);
                }
              },
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => b.refresh(force: true),
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: b.items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final item = b.items[i];
          final sel = b.selected.contains(item.id);
          return FileTile(
            item: item,
            grid: false,
            selected: sel,
            selectMode: b.selectMode,
            onTap: () {
              if (b.selectMode) {
                b.toggleSelect(item);
              } else {
                _openMedia(item);
              }
            },
            onLongPress: () {
              if (b.selectMode) {
                b.toggleSelect(item);
              } else {
                _itemSheet(item);
              }
            },
          );
        },
      ),
    );
  }
}
