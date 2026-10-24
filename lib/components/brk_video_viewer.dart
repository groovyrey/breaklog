import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

/// Full-screen player for a local clip, matching the photo viewer chrome.
Future<void> showBrkVideoViewer(
  BuildContext context,
  String path, {
  bool cover = false,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    BrkVideoViewerRoute(path: path, cover: cover),
  );
}

class BrkVideoViewerRoute extends PageRoute<void> {
  BrkVideoViewerRoute({required this.path, this.cover = false});

  final String path;
  final bool cover;

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
    return _BrkVideoViewer(path: path, cover: cover);
  }
}

class _BrkVideoViewer extends StatefulWidget {
  const _BrkVideoViewer({required this.path, required this.cover});

  final String path;
  final bool cover;

  @override
  State<_BrkVideoViewer> createState() => _BrkVideoViewerState();
}

class _BrkVideoViewerState extends State<_BrkVideoViewer> {
  late final VideoPlayerController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path));
    _controller.addListener(_onControllerUpdate);
    _init();
  }

  // Playback position arrives on the controller, so the seek bar and clock only
  // move if we rebuild on each notification (they otherwise froze until pause).
  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _init() async {
    if (!await File(widget.path).exists()) {
      if (mounted) {
        setState(() =>
            _error = 'This clip is not on the device any more.\n${widget.path}');
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
    return 'This clip could not be opened.\n$detail\n${widget.path}';
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

  String _time(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ready = _error == null && _controller.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: context.appTextTheme.bodyMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else if (!ready)
              const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            else
              GestureDetector(
                onTap: _togglePlayback,
                behavior: HitTestBehavior.opaque,
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: widget.cover ? BoxFit.cover : BoxFit.contain,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),
            if (ready)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(color: AppColors.outline),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _togglePlayback,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 26,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _time(_controller.value.position),
                        style: context.appTextTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurface),
                      ),
                      Expanded(
                        child: Slider(
                          value: _controller.value.position.inMilliseconds
                              .toDouble()
                              .clamp(
                                  0,
                                  _controller.value.duration.inMilliseconds
                                      .toDouble()),
                          min: 0,
                          max: _controller.value.duration.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                          activeColor: AppColors.accent,
                          inactiveColor: AppColors.surfaceVariant,
                          onChanged: (v) => _controller
                              .seekTo(Duration(milliseconds: v.round())),
                        ),
                      ),
                      Text(
                        _time(_controller.value.duration),
                        style: context.appTextTheme.labelMedium
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surfaceVariant,
                  ),
                  child: const Icon(Icons.close,
                      size: 20, color: AppColors.onSurface),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
