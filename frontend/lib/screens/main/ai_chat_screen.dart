import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/chat_message.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    await context.read<AppState>().sendChatMessage(text);
    if (mounted) setState(() => _sending = false);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final messages = state.chatMessages;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('LibHub AI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('Your library assistant', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _WelcomeState()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) => _ChatBubble(msg: messages[i]),
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _TypingIndicator(),
            ),
          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    minLines: 1, maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Ask about books, policies, recommendations...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: theme.dividerColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2)),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7C3AED)]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: theme.dividerColor),
              ),
              child: Text(
                msg.content,
                style: TextStyle(
                  color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(18), border: Border.all(color: theme.dividerColor)),
          child: Row(children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Container(width: 7, height: 7, decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.6), shape: BoxShape.circle)),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _WelcomeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, Color(0xFF7C3AED)]),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        const Text('LibHub AI Assistant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Ask me about books, policies, FAQs,\nor get personalized recommendations!', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 28),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          _QuickChip(label: '📚 Book recommendations'),
          _QuickChip(label: '📋 Library policies'),
          _QuickChip(label: '❓ How to borrow'),
          _QuickChip(label: '⭐ Top rated books'),
        ]),
      ]),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  const _QuickChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
