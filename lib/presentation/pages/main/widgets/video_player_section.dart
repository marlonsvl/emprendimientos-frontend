import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';

class VideoPlayerSection extends StatefulWidget {
  final String videoUrl;
  
  const VideoPlayerSection({
    super.key,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerSection> createState() => _VideoPlayerSectionState();
}

class _VideoPlayerSectionState extends State<VideoPlayerSection> {
  late CachedVideoPlayerPlus _player;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _player = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(widget.videoUrl.replaceFirst('/upload/', '/upload/f_mp4/')),
      //Uri.parse(
      //  "https://res.cloudinary.com/djl0e1p6e/video/upload/v1762564764/samples/dance-2.mp4".replaceFirst('/upload/', '/upload/f_mp4/'),
      //),
      invalidateCacheIfOlderThan: const Duration(hours: 1),
    );

    _player.initialize().then((_) {
      if (!mounted) return;
      //1 
      _player.controller.play();
      //2
      _player.controller.addListener(_updateState);
      //3
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
      //_player.controller.play();
    }).catchError((error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    });
  }

  void _updateState() {
    if (mounted && _player.controller.value.isInitialized) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _player.controller.removeListener(_updateState);
    _player.controller.pause();
    _player.controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    
    setState(() {
      if (_player.controller.value.isPlaying) {
        _player.controller.pause();
      } else {
        _player.controller.play();
      }
    });
  }

  void _stopVideo() {
    if (!_isInitialized) return;
    
    _player.controller.pause();
    _player.controller.seekTo(Duration.zero);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildVideoPlayer(context),
          if (_isInitialized) ...[
            const SizedBox(height: 12),
            _buildVideoSlider(context),
            const SizedBox(height: 12),
            _buildControls(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.play_circle, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Video del Emprendimiento',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      /*child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _player.controller.value.aspectRatio,
                child: VideoPlayer(_player.controller),
              )
            : const Center(child: CircularProgressIndicator.adaptive()),
      ),*/
      child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: _isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: _player.controller.value.aspectRatio,
                  child: VideoPlayer(_player.controller),
                ),
                // Fullscreen button — bottom right
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _openFullscreen(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator.adaptive()),
    ),
    );
  }

  Future<void> _openFullscreen(BuildContext context) async {
  // Pause before entering fullscreen
  final wasPlaying = _player.controller.value.isPlaying;
  _player.controller.pause();

  // Force landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _FullscreenVideoPage(
        controller: _player.controller,
        wasPlaying: wasPlaying,
      ),
    ),
  );

  // Restore portrait when back
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Resume state from what fullscreen page left it at
  setState(() {});
}

  Widget _buildVideoSlider(BuildContext context) {
    final position = _player.controller.value.position.inSeconds.toDouble();
    final duration = _player.controller.value.duration.inSeconds.toDouble();

    return Slider(
      value: position.clamp(0.0, duration),
      max: duration,
      onChanged: (value) {
        _player.controller.pause();
      },
      onChangeEnd: (value) {
        _player.controller.seekTo(Duration(seconds: value.toInt()));
        _player.controller.play();
      },
      activeColor: Theme.of(context).colorScheme.primary,
      inactiveColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            _player.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _togglePlayPause,
        ),
        const SizedBox(width: 24),
        IconButton(
          icon: Icon(
            Icons.stop,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: _stopVideo,
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error al cargar el video',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final bool wasPlaying;

  const _FullscreenVideoPage({
    required this.controller,
    required this.wasPlaying,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  bool _showControls = true;

  @override
void initState() {
  super.initState();
  widget.controller.addListener(_updateState);
  
  // FIX: defer play() so it doesn't fire notifyListeners during build
  if (widget.wasPlaying) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.play();
    });
  }
  
  _scheduleHideControls();
}

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) setState(() {});
  });
  }

  void _scheduleHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _scheduleHideControls();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video fills entire screen
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),

            // Controls overlay — visible only when _showControls is true
            if (_showControls) ...[
              // Top bar: exit fullscreen button
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 28),
                  ),
                ),
              ),

              // Bottom controls: slider + play/pause
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Time labels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          Text(_formatDuration(controller.value.duration), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                      // Seek slider
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          trackHeight: 3,
                        ),
                        child: Slider(
                          value: controller.value.position.inSeconds.toDouble()
                              .clamp(0.0, controller.value.duration.inSeconds.toDouble()),
                          max: controller.value.duration.inSeconds.toDouble(),
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                          onChanged: (_) => controller.pause(),
                          onChangeEnd: (v) {
                            controller.seekTo(Duration(seconds: v.toInt()));
                            controller.play();
                          },
                        ),
                      ),
                      // Play/pause
                      IconButton(
                        icon: Icon(
                          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            controller.value.isPlaying
                                ? controller.pause()
                                : controller.play();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}