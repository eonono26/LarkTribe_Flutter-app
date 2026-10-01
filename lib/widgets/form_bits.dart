import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Uppercase tracked label above a field (mockup: "VAULT KEY / PASSWORD").
class FieldLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const FieldLabel(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(text.toUpperCase(), style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// Label + text field in one.
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final int maxLines;
  final TextCapitalization capitalization;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.maxLines = 1,
    this.capitalization = TextCapitalization.none,
    this.onSubmitted,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel(label),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            maxLines: maxLines,
            textCapitalization: capitalization,
            onSubmitted: onSubmitted,
            autofillHints: autofillHints,
            decoration: InputDecoration(hintText: hint, suffixIcon: suffix),
          ),
        ]),
      );
}

/// Two-option segmented track (Privé Member / Guest Order in the mockup).
class SegmentTrack extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const SegmentTrack({super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadii.sm)),
        child: Row(children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: i == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: Center(
                    child: Text(labels[i].toUpperCase(),
                        style: AppType.labelCaps(i == index ? AppColors.ink : AppColors.inkSoft)
                            .copyWith(fontSize: 10.5)),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// White rounded panel used on profile, addresses, payments, orders.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 12),
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(color: color ?? Colors.white, borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: child,
    );
    return Padding(
      padding: margin,
      child: onTap == null
          ? box
          : Material(
              color: Colors.transparent,
              child: InkWell(borderRadius: BorderRadius.circular(AppRadii.sm), onTap: onTap, child: box)),
    );
  }
}

String formatDate(DateTime? d) {
  if (d == null) return '';
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${m[d.month - 1]} ${d.day}, ${d.year}';
}

String formatTime(DateTime? d) {
  if (d == null) return '';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  return '$h:$mm ${d.hour >= 12 ? 'PM' : 'AM'}';
}
