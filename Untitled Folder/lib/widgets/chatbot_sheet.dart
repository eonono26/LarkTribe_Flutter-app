import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'product_card.dart';
import '../screens/product_detail_screen.dart';

void showChatbotSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChatbotSheet(),
  );
}

class _ChatbotSheet extends StatefulWidget {
  const _ChatbotSheet();

  @override
  State<_ChatbotSheet> createState() => _ChatbotSheetState();
}

class _ChatbotSheetState extends State<_ChatbotSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
        sender: 'bot',
        text: "Hello — I'm the LarkTribe shopping assistant. Ask me to find something, or check on an order."),
  ];
  bool _sending = false;

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(ChatMessage(sender: 'user', text: text));
      _sending = true;
    });
    _controller.clear();
    _scrollDown();
    try {
      final reply = await ApiService.instance.chatbot(text);
      if (mounted) setState(() => _messages.add(reply));
    } catch (_) {
      if (mounted) {
        setState(() => _messages
            .add(ChatMessage(sender: 'bot', text: 'Sorry, something went wrong. Try again shortly.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollDown();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        color: AppColors.paper,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
              color: AppColors.ink,
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppColors.goldOnDark, size: 16),
                  const SizedBox(width: 10),
                  Text('SHOPPING ASSISTANT', style: AppType.labelCaps(Colors.white)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isUser = m.sender == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.ink : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.text,
                              style: AppType.bodyMd(isUser ? Colors.white : AppColors.ink)),
                          for (final p in m.products.take(4))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ProductDetailScreen(slug: p.slug)));
                                },
                                child: Text(
                                  '${p.name} — ${formatKES(p.price)}',
                                  style: AppType.bodySm(AppColors.goldDeep).copyWith(
                                      decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        decoration:
                            const InputDecoration(hintText: 'Ask about products, orders, returns…'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadii.xs),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        onTap: _send,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.arrow_upward, color: Colors.white, size: 20),
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
