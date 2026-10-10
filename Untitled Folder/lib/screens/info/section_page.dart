import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Shared scaffold for static content pages that are just a title, a
/// subtitle, and a list of "## heading / paragraph" sections — mirrors the
/// web app's about/privacy/terms/delivery/returns pages.
class InfoSection {
  final String title;
  final String body;
  const InfoSection(this.title, this.body);
}

class SectionPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<InfoSection> sections;
  final Widget? footer;
  final Widget? header;

  const SectionPage({
    super.key,
    required this.title,
    this.subtitle,
    this.sections = const [],
    this.footer,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Text(subtitle!, style: const TextStyle(color: AppColors.subtext, fontSize: 13)),
            ),
          if (header != null) header!,
          for (final s in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 15.5)),
                  const SizedBox(height: 6),
                  Text(s.body, style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}
