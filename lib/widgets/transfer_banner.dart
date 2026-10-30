import 'package:flutter/material.dart';

import '../services/transfer_service.dart';

class TransferBanner extends StatelessWidget {
  const TransferBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final ts = TransferService.instance;
    return AnimatedBuilder(
      animation: ts,
      builder: (context, _) {
        if (ts.activeCount == 0) return const SizedBox.shrink();
        final running = ts.jobs.where((j) => j.status == TransferStatus.running).toList();
        final queued = ts.jobs.where((j) => j.status == TransferStatus.queued).length;
        final job = running.isNotEmpty ? running.first : null;
        final cs = Theme.of(context).colorScheme;

        return Material(
          color: cs.primaryContainer,
          child: SafeArea(
            top: false,
            bottom: false,
            child: InkWell(
              onTap: () => _openSheet(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: job?.progress,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            job == null
                                ? '$queued islem kuyrukta'
                                : '${job.op == TransferOp.move ? 'Tasiyor' : 'Kopyaliyor'}: ${job.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (job != null)
                            Text(
                              '${(job.progress * 100).toStringAsFixed(0)}%'
                              '${queued > 0 ? '  ·  +$queued kuyrukta' : ''}'
                              '  ·  arka planda devam',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(Icons.expand_less, color: cs.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    final ts = TransferService.instance;
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      showDragHandle: true,
      builder: (ctx) {
        return AnimatedBuilder(
          animation: ts,
          builder: (_, __) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Aktarimlar'),
                    subtitle: const Text('Uygulama acikken arka planda surer'),
                    trailing: TextButton(
                      onPressed: ts.clearFinished,
                      child: const Text('Temizle'),
                    ),
                  ),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      itemCount: ts.jobs.length,
                      itemBuilder: (_, i) {
                        final j = ts.jobs[i];
                        return ListTile(
                          leading: Icon(_icon(j.status)),
                          title: Text(j.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: j.status == TransferStatus.running
                              ? LinearProgressIndicator(value: j.progress)
                              : Text(_label(j)),
                          dense: true,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _icon(TransferStatus s) => switch (s) {
        TransferStatus.queued => Icons.schedule,
        TransferStatus.running => Icons.sync,
        TransferStatus.done => Icons.check_circle,
        TransferStatus.failed => Icons.error_outline,
        TransferStatus.cancelled => Icons.cancel_outlined,
      };

  String _label(TransferJob j) => switch (j.status) {
        TransferStatus.queued => 'Kuyrukta',
        TransferStatus.running => 'Islemde',
        TransferStatus.done => 'Tamam',
        TransferStatus.failed => 'Hata: ${j.error ?? ''}',
        TransferStatus.cancelled => 'Iptal',
      };
}
