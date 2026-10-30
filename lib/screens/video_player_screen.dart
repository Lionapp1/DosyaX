import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String path;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.path,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _error = false;
  bool _muted = false;
  bool _showUi = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _error = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showUi
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              actions: [
                IconButton(
                  tooltip: _muted ? 'Ses ac' : 'Sessiz',
                  onPressed: () {
                    setState(() {
                      _muted = !_muted;
                      _controller.setVolume(_muted ? 0 : 1);
                    });
                  },
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                ),
                IconButton(
                  tooltip: 'Paylas',
                  onPressed: () async {
                    try {
                      await Share.shareXFiles(
                        [XFile(widget.path)],
                        text: widget.title,
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.share_rounded),
                ),
              ],
            )
          : null,
      body: _error
          ? const Center(
              child: Text('Video acilamadi', style: TextStyle(color: Colors.white)),
            )
          : !_ready
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : GestureDetector(
                  onTap: () => setState(() => _showUi = !_showUi),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio == 0
                                ? 16 / 9
                                : _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      ),
                      if (_showUi)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: Column(
                            children: [
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFF3B82F6),
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.white12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      final pos = _controller.value.position -
                                          const Duration(seconds: 10);
                                      _controller.seekTo(
                                        pos < Duration.zero
                                            ? Duration.zero
                                            : pos,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.replay_10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _controller.value.isPlaying
                                            ? _controller.pause()
                                            : _controller.play();
                                      });
                                    },
                                    icon: Icon(
                                      _controller.value.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 44,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      final pos = _controller.value.position +
                                          const Duration(seconds: 10);
                                      final dur = _controller.value.duration;
                                      _controller.seekTo(pos > dur ? dur : pos);
                                    },
                                    icon: const Icon(
                                      Icons.forward_10,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_fmt(_controller.value.position)} / ${_fmt(_controller.value.duration)}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
