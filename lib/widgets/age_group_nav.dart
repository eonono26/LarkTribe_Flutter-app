import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import '../screens/product_list_screen.dart';

/// "Shop by Baby / Kids / Teens" — mirrors the web app's Header.tsx nav:
/// three life-stage tiles (Baby, Kids, Teens), each opening a Boys/Girls
/// breakdown by age range, plus a Brands tile. Age groups only ever carry
/// `stage` (baby/kids/teens); Boys/Girls is a separate gender filter
/// applied on top, same split as the web mega-menu.
class AgeGroupNav extends StatelessWidget {
  final List<AgeGroup> ageGroups;
  final List<Brand> brands;

  const AgeGroupNav({super.key, this.ageGroups = const [], this.brands = const []});

  static const _stages = [
    (key: 'baby', label: 'Baby', icon: Icons.child_friendly_rounded),
    (key: 'kids', label: 'Kids', icon: Icons.child_care_rounded),
    (key: 'teens', label: 'Teens', icon: Icons.face_rounded),
  ];

  List<AgeGroup> _forStage(String stage) {
    final groups = ageGroups.where((g) => g.stage == stage).toList()
      ..sort((a, b) => a.order - b.order);
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (ageGroups.isEmpty && brands.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Shop by Baby, Kids & Teens', style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 12),
        // All tiles share the width equally: nothing hidden, no scrolling.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in _stages)
                if (ageGroups.any((g) => g.stage == s.key) || ageGroups.isEmpty)
                  Expanded(
                    child: _StageTile(
                      label: s.label,
                      icon: s.icon,
                      color: AppColors.departmentColor('kids'),
                      onTap: () => _openStageSheet(context, s.key, s.label),
                    ),
                  ),
              if (brands.isNotEmpty)
                Expanded(
                  child: _StageTile(
                    label: 'Brands',
                    icon: Icons.sell_rounded,
                    color: AppColors.ink,
                    onTap: () => _openBrandsSheet(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openStageSheet(BuildContext context, String stage, String label) {
    final groups = _forStage(stage);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => _StageSheet(stage: stage, label: label, ageGroups: groups),
    );
  }

  void _openBrandsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg))),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Text('By Brand', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                itemCount: brands.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = brands[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.subtext),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductListScreen(title: b.name, brandSlug: b.slug)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StageTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.25))),
              child: Center(child: Icon(icon, color: color, size: 28)),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Boys / Girls columns for one life stage, each a plain list of that
/// stage's age ranges — mirrors the desktop mega-menu dropdown, and the
/// mobile drawer's nested `<details>` from Header.tsx.
class _StageSheet extends StatelessWidget {
  final String stage;
  final String label;
  final List<AgeGroup> ageGroups;

  const _StageSheet({required this.stage, required this.label, required this.ageGroups});

  void _goToProducts(BuildContext context, {String? gender, AgeGroup? ageGroup, required String title}) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          title: title,
          gender: gender,
          stage: ageGroup == null ? stage : null,
          ageGroupSlug: ageGroup?.slug,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAgeGroups = ageGroups.isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: hasAgeGroups ? 0.65 : 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          const SizedBox(height: 10),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Expanded(child: Text(label, style: Theme.of(context).textTheme.titleLarge)),
                TextButton(
                  onPressed: () => _goToProducts(context, title: 'Shop all $label'),
                  child: const Text('Shop all'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final gender in const ['boys', 'girls'])
                  _GenderColumn(
                    genderLabel: gender == 'boys' ? 'Boys' : 'Girls',
                    ageGroups: hasAgeGroups ? ageGroups : const [],
                    onTapShopAll: () => _goToProducts(context, gender: gender, title: '$label · ${gender == 'boys' ? 'Boys' : 'Girls'}'),
                    onTapAgeGroup: (ag) => _goToProducts(context, gender: gender, ageGroup: ag, title: ag.name),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderColumn extends StatelessWidget {
  final String genderLabel;
  final List<AgeGroup> ageGroups;
  final VoidCallback onTapShopAll;
  final void Function(AgeGroup) onTapAgeGroup;

  const _GenderColumn({
    required this.genderLabel,
    required this.ageGroups,
    required this.onTapShopAll,
    required this.onTapAgeGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTapShopAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(genderLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
          if (ageGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text('Shop all $genderLabel', style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ageGroups
                  .map((ag) => GestureDetector(
                        onTap: () => onTapAgeGroup(ag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.mist,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Text(ag.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
