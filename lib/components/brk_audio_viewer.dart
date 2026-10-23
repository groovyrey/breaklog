import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Full-screen player for a voice note, matching the photo and clip viewers.
Future<void> showBrkAudioViewer(BuildContext context, String path) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    BrkAudioViewerRoute(path: path),
  );
}

class BrkAudioViewerRoute extends PageRoute<void> {
  BrkAudioViewerRoute({required this.path});

  final String path;

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel => 'Close';

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return _BrkAudioViewer(path: path);
  }
}

class _BrkAudioViewer extends StatefulWidget {
  const _BrkAudioViewer({required this.path});

  final String path;

  @override
  State<_BrkAudioViewer> createState() => _BrkAudioViewerState();
}

class _BrkAudioViewerState extends State<_BrkAudioViewer> {
  late final VideoPlayerController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller.addListener(_onControllerUpdate);
    _init();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    if (!await File(widget.path).exists()) {
      if (mounted) {
        setState(() =>
            _error = 'This voice note is not on the device any more.\n${widget.path}');
      }
      return;
    }
    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {});
      await _controller.play();
    } catch (error) {
      if (mounted) setState(() => _error = _describe(error));
    }
  }

  String _describe(Object error) {
    final detail = error is PlatformException
        ? (error.message ?? error.code)
        : error.toString();
    return 'This voice note could not be opened.\n$detail\n${widget.path}';
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  void _seek(double seconds) {
    _controller.seekTo(Duration(milliseconds: (seconds * 1000).round()));
  }

  String _time(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ready = _error == null && _controller.value.isInitialized;
    final value = _controller.value;
    final total = value.duration.inMilliseconds / 1000;
    final position =
        (value.position.inMilliseconds / 1000).clamp(0.0, total).toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: _error != null
                    ? Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: context.appTextTheme.bodyMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: AppColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.graphic_eq,
                              size: 44,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'Voice note',
                            style: context.appTextTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _fileName(widget.path),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.appTextTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 28),
                          if (ready) ...[
                            Slider(
                              value: position,
                              max: total > 0 ? total : 1,
                              activeColor: AppColors.accent,
                              inactiveColor: AppColors.outline,
                              onChanged: total > 0 ? _seek : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _time(value.position),
                                    style: context.appTextTheme.labelSmall
                                        ?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                  ),
                                  Text(
                                    _time(value.duration),
                                    style: context.appTextTheme.labelSmall
                                        ?.copyWith(
                                            color: AppColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _PlayButton(
                              playing: value.isPlaying,
                              onPressed: _togglePlayback,
                            ),
                          ] else
                            const Padding(
                              padding: EdgeInsets.only(top: 24),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                color: AppColors.onSurface,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fileName(String path) {
    final parts = path.split('/');
    return parts.isEmpty ? path : parts.last;
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          size: 32,
          color: AppColors.onAccent,
        ),
      ),
    );
  }
}
