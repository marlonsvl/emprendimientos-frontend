import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:video_player/video_player.dart';

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
      //Uri.parse(widget.videoUrl.replaceFirst('/upload/', '/upload/f_mp4/')),
      Uri.parse(
        "https://res.cloudinary.com/djl0e1p6e/video/upload/v1762564764/samples/dance-2.mp4".replaceFirst('/upload/', '/upload/f_mp4/'),
      ),
      invalidateCacheIfOlderThan: const Duration(hours: 1),
    );

    _player.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isInitialized = true);
      _player.controller.addListener(_updateState);
      _player.controller.play();
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _player.controller.value.aspectRatio,
                child: VideoPlayer(_player.controller),
              )
            : const Center(child: CircularProgressIndicator.adaptive()),
      ),
    );
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