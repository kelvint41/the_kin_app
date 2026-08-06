import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '/flutter_flow/flutter_flow_theme.dart';

/// Inline video playback for an Exchange post's `post_video`.
///
/// `video_player` has been a pubspec dependency since the start, but this is
/// its first real use for playback anywhere in the app - its only prior use
/// (`upload_data.dart`) spins up a throwaway controller just to read a
/// picked video's pixel dimensions before upload, then discards it.
///
/// There's no `video_thumbnail` package in the project, so this doesn't
/// extract a real poster frame - it shows a plain dark placeholder with a
/// play glyph until tapped, then initializes the controller and starts
/// playing. Sized to the same 220px height the image slot already uses so
/// it drops into the feed without changing card layout.
class ExchangeVideoPlayerWidget extends StatefulWidget {
  const ExchangeVideoPlayerWidget({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<ExchangeVideoPlayerWidget> createState() =>
      _ExchangeVideoPlayerWidgetState();
}

class _ExchangeVideoPlayerWidgetState
    extends State<ExchangeVideoPlayerWidget> {
  static const double _height = 220.0;

  VideoPlayerController? _controller;
  bool _started = false;
  bool _loading = false;
  bool _errored = false;
  bool _muted = false;

  Future<void> _start() async {
    setState(() {
      _started = true;
      _loading = true;
      _errored = false;
    });
    final controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      controller.dispose();
      if (!mounted) return;
      setState(() {
        _started = false;
        _loading = false;
        _errored = true;
      });
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      _muted = !_muted;
      controller.setVolume(_muted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final controller = _controller;

    if (controller != null && controller.value.isInitialized) {
      return GestureDetector(
        onTap: _togglePlayback,
        child: SizedBox(
          width: double.infinity,
          height: _height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              Positioned(
                top: 8.0,
                right: 8.0,
                child: _RoundIconButton(
                  icon: _muted ? Icons.volume_off : Icons.volume_up,
                  onTap: _toggleMute,
                ),
              ),
              if (!controller.value.isPlaying)
                Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    size: 56.0,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Not started, loading, or the initialize()/play() call above threw.
    return GestureDetector(
      onTap: _loading ? null : _start,
      child: Container(
        width: double.infinity,
        height: _height,
        color: Colors.black87,
        child: Center(
          child: _loading
              ? CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.accent4),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _errored ? Icons.refresh : Icons.play_circle_fill,
                      size: 56.0,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    if (_errored) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        'Couldn\'t load video. Tap to retry.',
                        style: theme.bodySmall.override(color: Colors.white),
                      ),
                    ] else if (_started == false) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'Video',
                        style: theme.labelSmall.override(color: Colors.white),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999.0),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6.0),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18.0, color: Colors.white),
      ),
    );
  }
}
