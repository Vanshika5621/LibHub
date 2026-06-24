import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../models/chat_message.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _quickSend(String text) {
    _inputCtrl.text = text;
    _send();
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
    final dark = AppTheme.isDarkMode(context);
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
                ? _WelcomeState(onSelectSuggestion: (text) {
                    _inputCtrl.text = text;
                    _send();
                  })
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
          // Quick suggestions above input
          if (messages.isNotEmpty)
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _QuickChip(label: '📚 Recommend fiction', onTap: () => _quickSend('Recommend a fiction book')),
                  _QuickChip(label: '📋 Borrowing rules', onTap: () => _quickSend('What are the borrowing limits?')),
                  _QuickChip(label: '🔖 How to reserve?', onTap: () => _quickSend('How do I reserve a book?')),
                  _QuickChip(label: '💰 Fine policy', onTap: () => _quickSend('Tell me about late fines')),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Input Area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: dark ? const Color(0xFF2D2D3A) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _inputCtrl,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Type your question...',
                              hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.attach_file_rounded, size: 20, color: Colors.grey),
                          onPressed: () {}, // Future: image support
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _sending 
                          ? [Colors.grey, Colors.grey.shade400]
                          : [const Color(0xFF6366F1), const Color(0xFF4F46E5)]
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_sending)
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
    final dark = AppTheme.isDarkMode(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser)
                Container(
                  width: 34, height: 34,
                  margin: const EdgeInsets.only(right: 10, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 18),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryColor
                        : (dark ? const Color(0xFF2D2D3A) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      if (!isUser)
                        BoxShadow(
                          color: Colors.black.withOpacity(dark ? 0.2 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                    border: isUser ? null : Border.all(color: dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : (dark ? Colors.white : AppTheme.textColor),
                      fontSize: 14.5,
                      height: 1.5,
                      fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (isUser)
                const SizedBox(width: 4),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 6, right: isUser ? 8 : 0, left: isUser ? 0 : 44),
            child: Text(
              isUser ? 'You' : 'LibHub AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
          ),
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
  final Function(String) onSelectSuggestion;
  const _WelcomeState({required this.onSelectSuggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = AppTheme.isDarkMode(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 90, height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 45),
          ),
          const SizedBox(height: 28),
          Text(
            'Hello! I\'m your Librarian',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: dark ? Colors.white : AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything about our library, from book suggestions to membership policies.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: (dark ? Colors.white : AppTheme.textColor).withOpacity(0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _SuggestionGroup(
            title: 'Try asking...',
            suggestions: const [
              '📚 Recommend a fiction book',
              '📋 What are the borrowing limits?',
              '🔖 How do I reserve a book?',
              '💰 Tell me about late fines',
            ],
            onSelect: onSelectSuggestion,
          ),
        ],
      ),
    );
  }
}

class _SuggestionGroup extends StatelessWidget {
  final String title;
  final List<String> suggestions;
  final Function(String) onSelect;

  const _SuggestionGroup({
    required this.title,
    required this.suggestions,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDarkMode(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: (dark ? Colors.white : AppTheme.textColor).withOpacity(0.4),
          ),
        ),
        const SizedBox(height: 16),
        ...suggestions.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onSelect(s.substring(3)), // Remove emoji for query
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: dark ? const Color(0xFF2D2D3A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Text(s.substring(0, 2), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.substring(3),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : AppTheme.textColor,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 18, color: (dark ? Colors.white : AppTheme.textColor).withOpacity(0.3)),
                ],
              ),
            ),
          ),
        )).toList(),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDarkMode(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        onPressed: onTap,
        backgroundColor: dark ? const Color(0xFF2D2D3A) : Colors.white,
        side: BorderSide(color: dark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }
}
