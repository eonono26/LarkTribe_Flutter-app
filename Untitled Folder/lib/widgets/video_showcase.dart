import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'link_resolver.dart';

/// "Watch & Shop" — autoplaying muted vertical film tiles that link to the
/// tagged product or department.
class VideoShowcase extends StatelessWidget {
  final List<ShowcaseVideoItem> videos;
  const VideoShowcase({super.key, required this.videos});

  @override
  Widget build(BuildContext context) {
    final items = videos.where((v) => v.videoUrl != null && v.videoUrl!.isNotEmpty).toList();
    final shown = items.length > 4 ? items.sublist(items.length - 4) : items;
    if (shown.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(eyebrow: 'Shoppable film', title: 'Watch & Shop'),
        const SizedBox(height: 14),
        SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => SizedBox(width: 180, child: _VideoTile(item: shown[i])),
          ),
        ),
      ],
    );
  }
}

class _VideoTile extends StatefulWidget {
  final ShowcaseVideoItem item;
  const _VideoTile({required this.item});

  @override
  State<_VideoTile> createState() => _VideoTileState();
}

class _VideoTileState extends State<_VideoTile> {
  VideoPlayerController? _controller;
  bool _muted = true;
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final url = widget.item.videoUrl;
    if (url == null) return;
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c
        ..setLooping(true)
        ..setVolume(0)
        ..play();
      setState(() => _ready = true);
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() => _muted = !_muted);
    c.setVolume(_muted ? 0 : 1);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTap: () => openLink(context, item.resolvedLink),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (!_ready && item.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: item.thumbnailUrl!,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(color: Colors.black),
            ),
          if (_ready && !_failed && _controller != null)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x59000000), Color(0x00000000), Color(0xB3000000)],
                stops: [0, .4, 1],
              ),
            ),
          ),
          if (!_ready && !_failed)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(color: Color(0x80000000), shape: BoxShape.circle),
                child: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          if (item.title.isNotEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headlineSm(Colors.white).copyWith(fontSize: 16)),
            ),
        ],
      ),
    );
  }
}
