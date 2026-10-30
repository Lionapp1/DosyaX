import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ImageViewerScreen extends StatefulWidget {
  final String path;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  double _rotation = 0;
  final _transform = TransformationController();

  void _reset() {
    setState(() {
      _rotation = 0;
      _transform.value = Matrix4.identity();
    });
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Dondur',
            onPressed: () => setState(() => _rotation += math.pi / 2),
            icon: const Icon(Icons.rotate_right_rounded),
          ),
          IconButton(
            tooltip: 'Sifirla',
            onPressed: _reset,
            icon: const Icon(Icons.fit_screen_rounded),
          ),
          IconButton(
            tooltip: 'Paylas',
            onPressed: () async {
              try {
                await Share.shareXFiles([XFile(widget.path)], text: widget.title);
              } catch (_) {}
            },
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _transform,
          minScale: 0.4,
          maxScale: 6,
          child: Transform.rotate(
            angle: _rotation,
            child: Image.file(
              File(widget.path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
