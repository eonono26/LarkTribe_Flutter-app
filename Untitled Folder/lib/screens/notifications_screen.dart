import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/link_resolver.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await ApiService.instance.notifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
        _error = false;
      });
      if (list.any((n) => !n.isRead)) ApiService.instance.markAllNotificationsRead();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  String _ago(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Notifications'),
      body: _loading
          ? const LarkLoading()
          : _error
              ? LarkErrorState(onRetry: () {
                  setState(() => _loading = true);
                  _load();
                })
              : _items.isEmpty
                  ? const LarkEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'All caught up',
                      message: 'Order updates and offers will appear here.')
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return const Padding(
                            padding: EdgeInsets.fromLTRB(16, 22, 16, 14),
                            child: SectionHeading(
                                eyebrow: 'Inbox', title: 'Notifications', padding: EdgeInsets.zero),
                          );
                        }
                        final n = _items[i - 1];
                        return InkWell(
                          onTap: n.link.isEmpty ? null : () => openLink(context, n.link),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.transparent : Colors.white,
                              border: const Border(bottom: BorderSide(color: AppColors.hairline)),
                            ),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 6, right: 12),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: n.isRead ? Colors.transparent : AppColors.ink),
                                ),
                              ),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(child: Eyebrow(n.category.replaceAll('_', ' '))),
                                    Text(_ago(n.sentAt), style: AppType.bodySm(AppColors.subtext)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(n.title, style: AppType.headlineSm(AppColors.ink).copyWith(fontSize: 17)),
                                  if (n.body.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(n.body, style: AppType.bodyMd(AppColors.inkSoft)),
                                  ],
                                ]),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}
