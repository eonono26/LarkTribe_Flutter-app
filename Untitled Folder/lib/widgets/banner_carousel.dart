import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'link_resolver.dart';
import 'product_card.dart';

/// Same selection the website's home page uses: every live
/// `homepage_banner` campaign that has an image, whatever its style.
List<Campaign> homepageBanners(List<Campaign> all) => all
    .where((c) =>
        c.placement == 'homepage_banner' && c.isLive && c.image != null && c.image!.isNotEmpty)
    .toList();

/// Image-only banner carousel — the app twin of the storefront's
/// HeroCarousel: full-bleed art with the headline baked into the image (no
/// text overlay), cross-fade between slides with a slow zoom, dot
/// indicators, swipe to change slide, auto-advance that pauses while a
/// finger is down, and a tap that opens the campaign link.
///
/// [aspectRatio] is width / height. 1.6 gives ~244 px on a 390 px phone —
/// clearly a banner, not a strip. Raise it for a shorter banner, lower it
/// for a taller one.
class HeroCarousel extends StatefulWidget {
  final List<Campaign> campaigns;
  final double aspectRatio;
  final Duration interval;

  const HeroCarousel({
    super.key,
    required this.campaigns,
    this.aspectRatio = 1.6,
    this.interval = const Duration(seconds: 7),
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  Timer? _timer;
  int _index = 0;
  bool _paused = false;
  double _dragDx = 0;

  int get _count => widget.campaigns.length;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HeroCarousel old) {
    super.didUpdateWidget(old);
    if (old.campaigns.length != widget.campaigns.length) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_count <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_paused && mounted) _goTo(_index + 1);
    });
  }

  void _goTo(int i) {
    if (_count == 0) return;
    setState(() => _index = ((i % _count) + _count) % _count);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _paused = true;
          _dragDx = 0;
        },
        onHorizontalDragUpdate: (d) => _dragDx += d.delta.dx,
        onHorizontalDragEnd: (_) {
          if (_dragDx > 40) {
            _goTo(_index - 1);
          } else if (_dragDx < -40) {
            _goTo(_index + 1);
          }
          _paused = false;
        },
        onHorizontalDragCancel: () => _paused = false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF0C0A09)),
            for (var i = 0; i < _count; i++)
              _BannerSlide(campaign: widget.campaigns[i], active: i == _index),
            if (_count > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _count; i++)
                      GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _index ? Colors.white : Colors.white.withOpacity(.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                  ],
                ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerSlide extends StatelessWidget {
  final Campaign campaign;
  final bool active;
  const _BannerSlide({required this.campaign, required this.active});

  @override
  Widget build(BuildContext context) {
    final hasImage = campaign.image != null && campaign.image!.isNotEmpty;
    Color base = const Color(0xFF0C0A09);
    final bg = campaign.backgroundColor;
    if (bg != null && RegExp(r'^#?[0-9a-fA-F]{6}$').hasMatch(bg)) {
      base = Color(int.parse('FF${bg.replaceAll('#', '')}', radix: 16));
    }
    return AnimatedOpacity(
      opacity: active ? 1 : 0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      child: IgnorePointer(
        ignoring: !active,
        child: GestureDetector(
          onTap: () => openLink(context, campaign.linkUrl),
          child: ClipRect(
            child: AnimatedScale(
              scale: active ? 1.05 : 1.0,
              duration: active ? const Duration(seconds: 7) : const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              child: hasImage
                  ? NetImage(campaign.image)
                  : Container(
                      color: base,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(campaign.title.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppType.headlineLgMobile(Colors.white)),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
