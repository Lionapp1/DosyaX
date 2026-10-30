import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'storage_service.dart';

enum TransferOp { copy, move }

enum TransferStatus { queued, running, done, failed, cancelled }

class TransferJob {
  final String id;
  final String sourcePath;
  final String destDir;
  final TransferOp op;
  TransferStatus status;
  double progress; // 0..1
  String? error;
  final int totalBytes;
  int doneBytes;

  TransferJob({
    required this.id,
    required this.sourcePath,
    required this.destDir,
    required this.op,
    required this.totalBytes,
    this.status = TransferStatus.queued,
    this.progress = 0,
    this.doneBytes = 0,
  });

  String get name => p.basename(sourcePath);
  String get destPath => p.join(destDir, name);
}

/// Non-blocking transfer queue — UI stays responsive; work continues while app lives.
class TransferService extends ChangeNotifier {
  TransferService._();
  static final TransferService instance = TransferService._();

  final List<TransferJob> jobs = [];
  bool _pumping = false;

  int get activeCount =>
      jobs.where((j) => j.status == TransferStatus.running || j.status == TransferStatus.queued).length;

  int get runningCount =>
      jobs.where((j) => j.status == TransferStatus.running).length;

  void enqueue({
    required String sourcePath,
    required String destDir,
    required TransferOp op,
  }) {
    final size = _fileSize(sourcePath);
    final job = TransferJob(
      id: '${DateTime.now().microsecondsSinceEpoch}_$sourcePath',
      sourcePath: sourcePath,
      destDir: destDir,
      op: op,
      totalBytes: size,
    );
    jobs.insert(0, job);
    notifyListeners();
    _pump();
  }

  void enqueueMany({
    required List<String> sources,
    required String destDir,
    required TransferOp op,
  }) {
    for (final s in sources) {
      enqueue(sourcePath: s, destDir: destDir, op: op);
    }
  }

  void clearFinished() {
    jobs.removeWhere(
      (j) =>
          j.status == TransferStatus.done ||
          j.status == TransferStatus.failed ||
          j.status == TransferStatus.cancelled,
    );
    notifyListeners();
  }

  int _fileSize(String path) {
    try {
      final type = FileSystemEntity.typeSync(path, followLinks: false);
      if (type == FileSystemEntityType.directory) return 0;
      return File(path).lengthSync();
    } catch (_) {
      return 0;
    }
  }

  Future<void> _pump() async {
    if (_pumping) return;
    _pumping = true;
    try {
      while (true) {
        final next = jobs.cast<TransferJob?>().firstWhere(
              (j) => j!.status == TransferStatus.queued,
              orElse: () => null,
            );
        if (next == null) break;
        await _runJob(next);
      }
    } finally {
      _pumping = false;
    }
  }

  Future<void> _runJob(TransferJob job) async {
    job.status = TransferStatus.running;
    job.progress = 0;
    notifyListeners();

    try {
      await Directory(job.destDir).create(recursive: true);
      final dest = job.destPath;
      // Unique name if exists
      var finalDest = dest;
      if (FileSystemEntity.typeSync(finalDest) != FileSystemEntityType.notFound) {
        final base = p.basenameWithoutExtension(job.name);
        final ext = p.extension(job.name);
        finalDest = p.join(
          job.destDir,
          '${base}_${DateTime.now().millisecondsSinceEpoch}$ext',
        );
      }

      final type = FileSystemEntity.typeSync(job.sourcePath, followLinks: false);
      if (type == FileSystemEntityType.directory) {
        await _copyDir(job.sourcePath, finalDest, job);
        if (job.op == TransferOp.move) {
          await Directory(job.sourcePath).delete(recursive: true);
        }
      } else {
        await _copyFileChunked(job.sourcePath, finalDest, job);
        if (job.op == TransferOp.move) {
          await File(job.sourcePath).delete();
        }
      }

      job.progress = 1;
      job.status = TransferStatus.done;
      StorageService.instance.invalidateCache(p.dirname(job.sourcePath));
      StorageService.instance.invalidateCache(job.destDir);
    } catch (e) {
      job.status = TransferStatus.failed;
      job.error = e.toString();
    }
    notifyListeners();
  }

  /// Chunked copy — yields to event loop so UI never freezes.
  Future<void> _copyFileChunked(String src, String dest, TransferJob job) async {
    final input = File(src).openRead();
    final output = File(dest).openWrite();
    final total = job.totalBytes > 0 ? job.totalBytes : 1;
    var done = 0;
    var lastNotify = DateTime.now();

    await for (final chunk in input) {
      output.add(chunk);
      done += chunk.length;
      job.doneBytes = done;
      job.progress = (done / total).clamp(0.0, 1.0);
      final now = DateTime.now();
      if (now.difference(lastNotify).inMilliseconds > 120) {
        lastNotify = now;
        notifyListeners();
        // Let frames paint
        await Future<void>.delayed(Duration.zero);
      }
    }
    await output.flush();
    await output.close();
    job.progress = 1;
  }

  Future<void> _copyDir(String src, String dest, TransferJob job) async {
    await Directory(dest).create(recursive: true);
    final entities = Directory(src).listSync(recursive: true, followLinks: false);
    final files = entities.whereType<File>().toList();
    var i = 0;
    for (final f in files) {
      final rel = p.relative(f.path, from: src);
      final out = p.join(dest, rel);
      await Directory(p.dirname(out)).create(recursive: true);
      await f.copy(out);
      i++;
      job.progress = files.isEmpty ? 1.0 : i / files.length;
      if (i % 3 == 0) {
        notifyListeners();
        await Future<void>.delayed(Duration.zero);
      }
    }
    job.progress = 1;
  }
}
