import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_gate.dart';
import '../widgets/common.dart';
import '../widgets/form_bits.dart';

/// Personal styling session request (Stitch screen 13). There is no booking
/// endpoint in the backend, so the request is filed as a support ticket
/// (/notifications/support-tickets/) which the team follows up on.
class StylingScreen extends StatefulWidget {
  const StylingScreen({super.key});

  @override
  State<StylingScreen> createState() => _StylingScreenState();
}

class _StylingScreenState extends State<StylingScreen> {
  static const _focus = [
    'Everyday wardrobe',
    'Gifts & occasions',
    'Baby & kids',
    'Special event outfit',
  ];
  static const _slots = [
    ('Morning', '9:00 – 12:00'),
    ('Afternoon', '12:00 – 17:00'),
    ('Evening', '17:00 – 20:00'),
  ];

  int _focusIndex = 0;
  int _dayIndex = 0;
  int _slotIndex = 1;
  final _notes = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).add(Duration(days: i + 1)));
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  String _dayName(DateTime d) => const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][d.weekday - 1];
  String _monthName(DateTime d) =>
      const ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'][d.month - 1];

  Future<void> _submit() async {
    if (!await ensureSignedIn(context)) return;
    if (!mounted) return;
    setState(() => _sending = true);
    final day = _days[_dayIndex];
    final slot = _slots[_slotIndex];
    final message = 'Styling session request\n'
        'Focus: ${_focus[_focusIndex]}\n'
        'Preferred day: ${_dayName(day)} ${day.day} ${_monthName(day)} ${day.year}\n'
        'Preferred time: ${slot.$1} (${slot.$2})\n'
        'Notes: ${_notes.text.trim().isEmpty ? '—' : _notes.text.trim()}';
    try {
      await ApiService.instance.openSupportTicket('Styling session — ${_focus[_focusIndex]}', message);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) toast(context, e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _step(String no, String title, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 28, 0, 14),
        child: Row(children: [
          Text('$no / 04', style: AppType.labelBadge(AppColors.goldDeep)),
          const SizedBox(width: 12),
          Expanded(child: Text(title.toUpperCase(), style: AppType.labelCaps(AppColors.ink).copyWith(fontSize: 10.5))),
          if (trailing != null) Text(trailing, style: AppType.bodySm(AppColors.inkSoft).copyWith(fontStyle: FontStyle.italic)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (_sent) {
      return Scaffold(
        backgroundColor: AppColors.paper,
        appBar: const AtelierAppBar(title: 'Styling session'),
        body: LarkEmptyState(
          icon: Icons.check_circle_outline,
          title: 'Request received',
          message: 'Our team will contact you to confirm your styling session.',
          actionLabel: 'Done',
          onAction: () => Navigator.pop(context),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const AtelierAppBar(title: 'Styling session'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 32),
        children: [
          const Eyebrow('Styling service', dot: true),
          const SizedBox(height: 12),
          Text('Personal Styling Session', style: AppType.display(AppColors.ink).copyWith(fontSize: 34)),
          const SizedBox(height: 10),
          Text('A one-to-one session with the LarkTribe team to help you find the right pieces.',
              style: AppType.bodyLg(AppColors.inkSoft)),
          _step('01', 'Session focus', trailing: 'Choose one'),
          for (var i = 0; i < _focus.length; i++)
            GestureDetector(
              onTap: () => setState(() => _focusIndex = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                color: _focusIndex == i ? AppColors.ink : Colors.white,
                child: Row(children: [
                  Expanded(
                    child: Text(_focus[i],
                        style: AppType.bodyLg(_focusIndex == i ? Colors.white : AppColors.ink)
                            .copyWith(fontWeight: FontWeight.w500)),
                  ),
                  Icon(_focusIndex == i ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 20, color: _focusIndex == i ? AppColors.goldOnDark : AppColors.stone400),
                ]),
              ),
            ),
          _step('02', 'Preferred day'),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = _days[i];
                final sel = i == _dayIndex;
                return GestureDetector(
                  onTap: () => setState(() => _dayIndex = i),
                  child: Container(
                    width: 64,
                    color: sel ? AppColors.ink : Colors.white,
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_dayName(d), style: AppType.labelBadge(sel ? Colors.white70 : AppColors.inkSoft)),
                      const SizedBox(height: 4),
                      Text('${d.day}', style: AppType.headlineMd(sel ? Colors.white : AppColors.ink)),
                      Text(_monthName(d), style: AppType.labelBadge(sel ? Colors.white70 : AppColors.inkSoft).copyWith(fontSize: 9)),
                    ]),
                  ),
                );
              },
            ),
          ),
          _step('03', 'Preferred time'),
          for (var i = 0; i < _slots.length; i++)
            GestureDetector(
              onTap: () => setState(() => _slotIndex = i),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                color: _slotIndex == i ? AppColors.ink : Colors.white,
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_slots[i].$1,
                          style: AppType.bodyLg(_slotIndex == i ? Colors.white : AppColors.ink)
                              .copyWith(fontWeight: FontWeight.w500)),
                      Text(_slots[i].$2,
                          style: AppType.bodySm(_slotIndex == i ? Colors.white70 : AppColors.inkSoft)),
                    ]),
                  ),
                  if (_slotIndex == i) const Icon(Icons.check, size: 20, color: Colors.white),
                ]),
              ),
            ),
          _step('04', 'Notes & requests'),
          TextField(
            controller: _notes,
            maxLines: 4,
            decoration: const InputDecoration(
                hintText: 'e.g. budget, sizes, an event date, colours you like…'),
          ),
          const SizedBox(height: 24),
          InkButton('Request styling session', trailingIcon: Icons.arrow_forward, loading: _sending, onPressed: _submit),
          const SizedBox(height: 10),
          Text('Your request is sent to our support team, who will confirm a time with you.',
              textAlign: TextAlign.center, style: AppType.bodySm(AppColors.subtext)),
        ],
      ),
    );
  }
}
