import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../components/index.dart';
import '../../config.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// The wall in front of the library. One way in: a Google account.
///
/// The clips in the Cloudinary login folder play muted on a loop behind the
/// content. A fade runs from the bottom of the screen up to the button so the
/// button and its note stay legible. If no clip loads, the background is plain
/// black and the screen still works.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey _actionKey = GlobalKey();
  double _scrim = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final auth = state.auth;

    // The fade spans the bottom edge up to the top of the button, so its height
    // is whatever is left below the button once the frame is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureScrim());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppConfig.loginVideos.isEmpty
              ? const ColoredBox(color: AppColors.background)
              : const _LoginVideo(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _scrim,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.background],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Text(
                    'BreakLog',
                    style: context.appTextTheme.displayLarge
                        ?.copyWith(color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A personal log for your bboy moves.',
                    style: context.appTextTheme.bodyLarge
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(flex: 3),
                  KeyedSubtree(
                    key: _actionKey,
                    child: BrkButton(
                      label: 'Continue with Google',
                      variant: BrkButtonVariant.light,
                      leading: Image.asset(
                        'assets/images/google_g.png',
                        width: 18,
                        height: 18,
                      ),
                      loading: auth.busy,
                      onPressed: () => auth.signIn(),
                    ),
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      auth.error!,
                      style: context.appTextTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    state.online
                        ? 'Signing in sets up your alias and Google Drive backup.'
                        : 'You are offline. Connect to the internet to sign in.',
                    style: context.appTextTheme.bodySmall
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'In partnership with',
                        style: context.appTextTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 10),
                      Image.asset(
                        'assets/images/partner_logo.png',
                        height: 26,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _measureScrim() {
    if (!mounted) return;
    final box = _actionKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final top = box.localToGlobal(Offset.zero).dy;
    final height = MediaQuery.of(context).size.height - top;
    if (height <= 0 || (height - _scrim).abs() < 0.5) return;
    setState(() => _scrim = height);
  }
}

/// Plays the login clips one after another, muted, forever. Owns its controller
/// so the screen above it stays about layout.
class _LoginVideo extends StatefulWidget {
  const _LoginVideo();

  @override
  State<_LoginVideo> createState() => _LoginVideoState();
}

class _LoginVideoState extends State<_LoginVideo> {
  VideoPlayerController? _controller;
  int _index = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _advance(0);
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _advance(int index, {int tried = 0}) async {
    final urls = AppConfig.loginVideos;
    if (urls.isEmpty || tried >= urls.length) return;

    final controller =
        VideoPlayerController.networkUrl(Uri.parse(urls[index % urls.length]));
    try {
      await controller.initialize();
      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_onTick);
      await controller.play();
    } catch (_) {
      controller.removeListener(_onTick);
      await controller.dispose();
      if (mounted) {
        await _advance((index + 1) % urls.length, tried: tried + 1);
      }
      return;
    }

    if (!mounted) {
      controller.removeListener(_onTick);
      await controller.dispose();
      return;
    }
    final previous = _controller;
    setState(() {
      _controller = controller;
      _index = index % urls.length;
      _ready = true;
    });
    previous?.removeListener(_onTick);
    await previous?.dispose();
  }

  // A listener rather than a timer: the clip ends, we swap to the next one. The
  // listener is dropped first so a finished clip cannot advance twice. The end
  // is read from the position and the play flag, both of which every backend
  // reports, rather than a completion flag one backend might not.
  void _onTick() {
    final value = _controller?.value;
    if (value == null || !value.isInitialized) return;
    if (value.duration <= Duration.zero) return;
    final done = value.position >= value.duration ||
        (!value.isPlaying && value.position > Duration.zero);
    if (!done) return;
    _controller?.removeListener(_onTick);
    _advance((_index + 1) % AppConfig.loginVideos.length);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) {
      return const ColoredBox(color: AppColors.background);
    }
    final size = controller.value.size;
    return ColoredBox(
      color: AppColors.background,
      child: ClipRect(
        child: SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            // A backend can report a zero size until the first frame decodes,
            // so fall back to the usual vertical shape rather than collapse.
            child: SizedBox(
              width: size.width > 0 ? size.width : 9,
              height: size.height > 0 ? size.height : 16,
              child: VideoPlayer(controller),
            ),
          ),
        ),
      ),
    );
  }
}
