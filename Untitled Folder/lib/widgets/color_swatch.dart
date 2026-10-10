import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Turns the colour NAME a vendor typed on a variant ("Off White", "Navy
/// Blue", "Black / Grey") into something a swatch can paint — the Dart twin
/// of the storefront's lib/colors.ts.
const _colorMap = <String, int>{
  'white': 0xFFFFFFFF,
  'off white': 0xFFF4F0E6,
  'off-white': 0xFFF4F0E6,
  'offwhite': 0xFFF4F0E6,
  'ivory': 0xFFFFFFF0,
  'cream': 0xFFF3EAD3,
  'ecru': 0xFFE9DFC7,
  'natural': 0xFFE6DCC6,
  'beige': 0xFFD8C8A8,
  'sand': 0xFFD6C09A,
  'stone': 0xFFBDB5A6,
  'oatmeal': 0xFFD9CDB5,
  'tan': 0xFFC8A878,
  'camel': 0xFFC19A6B,
  'khaki': 0xFFB5A67A,
  'taupe': 0xFF8B7D70,
  'black': 0xFF111111,
  'charcoal': 0xFF383B40,
  'graphite': 0xFF3F4348,
  'grey': 0xFF8C8F94,
  'gray': 0xFF8C8F94,
  'light grey': 0xFFC9CBCE,
  'light gray': 0xFFC9CBCE,
  'dark grey': 0xFF52555A,
  'dark gray': 0xFF52555A,
  'heather': 0xFFAEB1B6,
  'silver': 0xFFC0C0C0,
  'navy': 0xFF1D2A4A,
  'navy blue': 0xFF1D2A4A,
  'blue': 0xFF2F5FB3,
  'royal blue': 0xFF2B4FBF,
  'light blue': 0xFFA9C8EC,
  'sky blue': 0xFF87CEEB,
  'baby blue': 0xFFB7D4EE,
  'denim': 0xFF3D5A80,
  'teal': 0xFF1F7A7A,
  'turquoise': 0xFF2EC4B6,
  'red': 0xFFC62828,
  'burgundy': 0xFF6D1A2B,
  'maroon': 0xFF6B1F2A,
  'wine': 0xFF5E1A2C,
  'pink': 0xFFF2A7C0,
  'hot pink': 0xFFE8489A,
  'baby pink': 0xFFF6CFD9,
  'dusty pink': 0xFFD9A5AC,
  'blush': 0xFFEEC3C3,
  'rose': 0xFFD67A8F,
  'coral': 0xFFEE7B6B,
  'orange': 0xFFF08A24,
  'rust': 0xFFB7501F,
  'terracotta': 0xFFC4623F,
  'brown': 0xFF6B4530,
  'chocolate': 0xFF4A2C1D,
  'coffee': 0xFF5B3D2B,
  'mocha': 0xFF7A5A46,
  'mustard': 0xFFD9A520,
  'yellow': 0xFFF4D03F,
  'gold': 0xFFC5A25A,
  'green': 0xFF2E7D4F,
  'olive': 0xFF6B7140,
  'olive green': 0xFF6B7140,
  'sage': 0xFFA8B5A0,
  'mint': 0xFFB8E0CE,
  'lime': 0xFF9ACD32,
  'forest green': 0xFF1F4D33,
  'purple': 0xFF6A3FA0,
  'lavender': 0xFFC9B8E6,
  'lilac': 0xFFC8A2C8,
  'plum': 0xFF5B2A56,
};

Color colorFromName(String name) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return AppColors.stone400;
  final direct = _colorMap[key];
  if (direct != null) return Color(direct);

  final hex = RegExp(r'^#?([0-9a-f]{6})$').firstMatch(key);
  if (hex != null) return Color(int.parse('FF${hex.group(1)}', radix: 16));

  // "Black / Grey", "Navy & White" → first recognised word run.
  for (final part in key.split(RegExp(r'\s*[/&,+-]\s*'))) {
    final v = _colorMap[part.trim()];
    if (v != null) return Color(v);
  }
  // "Light Olive Stripe" → any known colour word inside the name.
  for (final e in _colorMap.entries) {
    if (key.contains(e.key)) return Color(e.value);
  }
  return AppColors.stone400;
}

/// A round swatch. [selected] draws the ink ring used on the product page.
class ColorDot extends StatelessWidget {
  final String name;
  final double size;
  final bool selected;
  final VoidCallback? onTap;
  const ColorDot(this.name, {super.key, this.size = 12, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = colorFromName(name);
    final light = c.computeLuminance() > .8;
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        shape: BoxShape.circle,
        border: Border.all(color: light ? AppColors.line : Colors.transparent),
      ),
    );
    if (!selected && onTap == null) return dot;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? AppColors.ink : Colors.transparent, width: 1.5),
        ),
        child: dot,
      ),
    );
  }
}
