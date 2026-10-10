import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/notifications_screen.dart';
import '../screens/search_screen.dart';
import '../screens/main_shell.dart';

// ---------------------------------------------------------------------------
// Typography helpers
// ---------------------------------------------------------------------------

/// Gold micro-label used above headlines ("NEW ARRIVALS", "COLLECTIONS / …").
class Eyebrow extends StatelessWidget {
  final String text;
  final Color? color;
  final bool dot;
  const Eyebrow(this.text, {super.key, this.color, this.dot = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.goldDeep;
    final label = Text(text.toUpperCase(), style: AppType.labelBadge(c));
    if (!dot) return label;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
      const SizedBox(width: 8),
      Flexible(child: label),
    ]);
  }
}

/// Eyebrow + Bodoni title, with an optional caps link on the right.
class SectionHeading extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String? trailing;
  final VoidCallback? onTrailing;
  final EdgeInsetsGeometry padding;
  final Widget? trailingWidget;

  const SectionHeading({
    super.key,
    this.eyebrow,
    required this.title,
    this.trailing,
    this.onTrailing,
    this.trailingWidget,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[Eyebrow(eyebrow!), const SizedBox(height: 4)],
                Text(title, style: AppType.headlineLgMobile(AppColors.ink)),
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget!,
          if (trailing != null)
            InkWell(
              onTap: onTrailing,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 8),
                child: Text(trailing!.toUpperCase(),
                    style: AppType.labelBadge(AppColors.ink).copyWith(letterSpacing: 1.3)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons & chips
// ---------------------------------------------------------------------------

enum InkVariant { filled, surface, outline, white }

class InkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon; // leading
  final IconData? trailingIcon;
  final bool loading;
  final InkVariant variant;
  final double height;
  final bool expand;

  const InkButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.loading = false,
    this.variant = InkVariant.filled,
    this.height = 52,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null && !loading;
    Color bg, fg;
    BorderSide? side;
    switch (variant) {
      case InkVariant.filled:
        bg = disabled ? AppColors.surface : AppColors.ink;
        fg = disabled ? AppColors.subtext : Colors.white;
        break;
      case InkVariant.surface:
        bg = AppColors.surface;
        fg = disabled ? AppColors.subtext : AppColors.ink;
        break;
      case InkVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.ink;
        side = const BorderSide(color: AppColors.ink);
        break;
      case InkVariant.white:
        bg = Colors.white;
        fg = AppColors.ink;
        break;
    }
    final child = loading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.labelCaps(fg).copyWith(letterSpacing: 1.4)),
              ),
              if (trailingIcon != null) ...[const SizedBox(width: 8), Icon(trailingIcon, size: 16, color: fg)],
            ],
          );
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        side: side ?? BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        onTap: (loading || onPressed == null) ? null : onPressed,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

/// Selectable pill (filter rows, department chips).
class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool subtle; // grey fill instead of white when unselected

  const PillChip(this.label,
      {super.key, this.selected = false, this.onTap, this.icon, this.trailingIcon, this.subtle = true});

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.ink : (subtle ? AppColors.surface : Colors.white);
    final fg = selected ? Colors.white : AppColors.ink;
    return Material(
      color: bg,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 8)],
            Text(label.toUpperCase(), style: AppType.labelCaps(fg).copyWith(fontSize: 10.5, letterSpacing: 1.2)),
            if (trailingIcon != null) ...[const SizedBox(width: 6), Icon(trailingIcon, size: 14, color: fg)],
          ]),
        ),
      ),
    );
  }
}

enum TagTone { ink, white, gold, peach, red, grey }

/// Small rectangular label ("NEW DROP", "LOW STOCK: 2 LEFT", "DEFAULT").
class TagBadge extends StatelessWidget {
  final String text;
  final TagTone tone;
  const TagBadge(this.text, {super.key, this.tone = TagTone.ink});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    switch (tone) {
      case TagTone.ink:
        bg = AppColors.ink;
        fg = Colors.white;
        break;
      case TagTone.white:
        bg = Colors.white.withOpacity(.94);
        fg = AppColors.ink;
        break;
      case TagTone.gold:
        bg = const Color(0xFF7A6544);
        fg = Colors.white;
        break;
      case TagTone.peach:
        bg = AppColors.goldTint;
        fg = AppColors.goldDeep;
        break;
      case TagTone.red:
        bg = const Color(0xFFB3261E);
        fg = Colors.white;
        break;
      case TagTone.grey:
        bg = AppColors.surface;
        fg = AppColors.ink;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      color: bg,
      child: Text(text.toUpperCase(),
          style: AppType.labelBadge(fg).copyWith(fontSize: 9.5, letterSpacing: 1.4)),
    );
  }
}

// ---------------------------------------------------------------------------
// App bars
// ---------------------------------------------------------------------------

/// Round profile picture / initial — used in every header, like the mockups.
class AvatarDot extends StatelessWidget {
  final double size;
  const AvatarDot({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final p = ApiService.instance.cachedProfile;
    final url = p?.profilePictureUrl;
    final initial = (p?.displayName.isNotEmpty ?? false) ? p!.displayName[0].toUpperCase() : null;
    return GestureDetector(
      onTap: () => shellTab.value = 4,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
        clipBehavior: Clip.antiAlias,
        alignment: Alignment.center,
        child: (url != null && url.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: ApiService.instance.absoluteMediaUrl(url),
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorWidget: (_, __, ___) => const Icon(Icons.person_outline, size: 18),
              )
            : (initial != null
                ? Text(initial, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 15))
                : Icon(Icons.person_outline, size: size * .55, color: AppColors.ink)),
      ),
    );
  }
}

/// LARKTRIBE wordmark (Bodoni, tracked).
class BrandWordmark extends StatelessWidget {
  final double size;
  final Color? color;
  const BrandWordmark({super.key, this.size = 22, this.color});

  @override
  Widget build(BuildContext context) => Text(
        'LARKTRIBE',
        style: AppType.headlineMd(color ?? AppColors.ink)
            .copyWith(fontSize: size, letterSpacing: size * .16, fontWeight: FontWeight.w500),
      );
}

int? _unreadCache;
DateTime? _unreadAt;

/// Header for the five tab screens: wordmark, search, bell (with unread dot),
/// avatar. Sits above the scroll view, separated by a hairline when [line].
class AtelierTopBar extends StatefulWidget {
  final bool line;
  const AtelierTopBar({super.key, this.line = true});

  @override
  State<AtelierTopBar> createState() => _AtelierTopBarState();
}

class _AtelierTopBarState extends State<AtelierTopBar> {
  bool _unread = (_unreadCache ?? 0) > 0;

  @override
  void initState() {
    super.initState();
    _loadUnread();
  }

  Future<void> _loadUnread() async {
    if (!ApiService.instance.isLoggedIn) return;
    final fresh = _unreadAt != null && DateTime.now().difference(_unreadAt!).inSeconds < 60;
    if (!fresh) {
      try {
        final list = await ApiService.instance.notifications();
        _unreadCache = list.where((n) => !n.isRead).length;
        _unreadAt = DateTime.now();
      } catch (_) {}
    }
    if (mounted) setState(() => _unread = (_unreadCache ?? 0) > 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.paper,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: widget.line ? const Border(bottom: BorderSide(color: AppColors.hairline)) : null,
          ),
          child: Row(
            children: [
              if (Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                ),
              const BrandWordmark(size: 20),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.search, size: 24),
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.notifications_none_rounded, size: 24),
                  if (_unread)
                    Positioned(
                      right: 1,
                      top: 1,
                      child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle)),
                    ),
                ]),
                onPressed: () async {
                  await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                  _unreadAt = null;
                  _loadUnread();
                },
              ),
              const SizedBox(width: 4),
              const AvatarDot(),
            ],
          ),
        ),
      ),
    );
  }
}

/// App bar for pushed screens: back arrow, tracked caps title, avatar.
class AtelierAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;
  final bool showAvatar;
  const AtelierAppBar({super.key, required this.title, this.actions = const [], this.showAvatar = true});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 60,
      backgroundColor: AppColors.paper,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Text(title.toUpperCase(),
          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.labelCaps(AppColors.ink)),
      actions: [
        ...actions,
        if (showAvatar) const Padding(padding: EdgeInsets.only(right: 16, left: 4), child: AvatarDot()),
      ],
      shape: const Border(bottom: BorderSide(color: AppColors.hairline)),
    );
  }
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

class LarkLoading extends StatelessWidget {
  const LarkLoading({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      );
}

class LarkEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const LarkEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.surfaceLow, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: AppColors.ink),
            ),
            const SizedBox(height: 20),
            Text(title, textAlign: TextAlign.center, style: AppType.headlineMd(AppColors.ink)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center, style: AppType.bodyMd(AppColors.subtext)),
            if (actionLabel != null) ...[
              const SizedBox(height: 24),
              InkButton(actionLabel!, onPressed: onAction, expand: false, height: 48),
            ],
          ],
        ),
      ),
    );
  }
}

class LarkErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const LarkErrorState({super.key, this.message = "We couldn't load this right now.", this.onRetry});

  @override
  Widget build(BuildContext context) => LarkEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Connection lost',
        message: message,
        actionLabel: onRetry == null ? null : 'Try again',
        onAction: onRetry,
      );
}

// ---------------------------------------------------------------------------
// Skeletons
// ---------------------------------------------------------------------------

Widget _shimmer(Widget child) => Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLow,
      child: child,
    );

class ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  const ShimmerBlock({super.key, this.width, required this.height});

  @override
  Widget build(BuildContext context) =>
      _shimmer(Container(width: width, height: height, color: AppColors.surface));
}

class ProductGridSkeleton extends StatelessWidget {
  final int count;
  const ProductGridSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    Widget col(int n, double top) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: top),
            child: Column(children: [
              for (var i = 0; i < n; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AspectRatio(aspectRatio: .75, child: const ShimmerBlock(height: double.infinity)),
                    const SizedBox(height: 10),
                    const ShimmerBlock(width: 120, height: 16),
                    const SizedBox(height: 6),
                    const ShimmerBlock(width: 60, height: 12),
                  ]),
                ),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        col((count / 2).ceil(), 0),
        const SizedBox(width: 12),
        col(count ~/ 2, 28),
      ]),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: const [
          ShimmerBlock(height: 480),
          SizedBox(height: 20),
          ProductGridSkeleton(count: 4),
        ],
      );
}

/// Convenience used by list rows: a labelled key/value line.
class KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const KeyValueRow(this.label, this.value, {super.key, this.valueColor, this.bold = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: AppType.bodyMd(AppColors.ink))),
          Text(value,
              style: AppText.price(14, color: valueColor ?? AppColors.ink,
                  weight: bold ? FontWeight.w600 : FontWeight.w500)),
        ]),
      );
}

/// Show a snackbar with a message (shared error surface).
void toast(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(message),
    action: actionLabel == null
        ? null
        : SnackBarAction(label: actionLabel, textColor: AppColors.goldOnDark, onPressed: onAction ?? () {}),
  ));
}

/// Placeholder when an image is missing or fails.
class ImageFallback extends StatelessWidget {
  const ImageFallback({super.key});
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceLow,
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: AppColors.stone400, size: 28),
      );
}

/// Unused import guard for `models` in files that only need the types.
typedef ProductItem = ProductListItem;
