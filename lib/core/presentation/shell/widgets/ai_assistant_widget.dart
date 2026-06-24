import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../di/injection.dart';
import '../../../../features/ai_assistant/ai_assistant_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/app_typography.dart';

/// Floating AI assistant. Tapping the FAB opens a chat panel that renders
/// markdown answers, wired to the live `/ai-assistant` endpoint.
class AiAssistantWidget extends StatefulWidget {
  const AiAssistantWidget({
    super.key,
    this.bottomOffset = AppSpacing.md,
  });

  /// Distance from the bottom edge for the floating assistant button.
  /// The mobile authenticated shell passes a larger value so the assistant
  /// clears the bottom navigation bar on iOS and Android.
  final double bottomOffset;

  @override
  State<AiAssistantWidget> createState() => _AiAssistantWidgetState();
}

class _ChatMessage {
  _ChatMessage(this.text, {required this.fromUser});
  String text; // mutable so streamed chunks can append in place
  final bool fromUser;
}

class _AiAssistantWidgetState extends State<AiAssistantWidget> {
  bool _open = false;
  final _controller = TextEditingController();
  final _messages = <_ChatMessage>[
    _ChatMessage(
      "Hi! I'm your **AskAide** study buddy. Ask me to explain a concept or "
      'suggest what to practice next.',
      fromUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final reply = _ChatMessage('', fromUser: false);
    setState(() {
      _messages.add(_ChatMessage(text, fromUser: true));
      _controller.clear();
      _sending = true;
    });
    // Stream the assistant's reply token-by-token (SSE).
    final buffer = StringBuffer();
    var added = false;
    await for (final chunk in sl<AiAssistantRepository>().stream(text)) {
      if (!mounted) return;
      buffer.write(chunk);
      setState(() {
        if (!added) {
          _messages.add(reply);
          added = true;
        }
        reply.text = buffer.toString();
        _sending = false; // first chunk arrived → hide the thinking dots
      });
    }
    if (!mounted) return;
    setState(() {
      if (!added) {
        _messages.add(_ChatMessage(
            "Sorry — I couldn't reach the assistant just now.",
            fromUser: false));
      }
      _sending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      children: [
        if (_open)
          Positioned(
            right: AppSpacing.md,
            bottom: widget.bottomOffset + 68,
            child: _ChatPanel(
              messages: _messages,
              controller: _controller,
              sending: _sending,
              onSend: _send,
              onClose: () => setState(() => _open = false),
            ),
          ),
        Positioned(
          right: AppSpacing.md,
          bottom: widget.bottomOffset,
          child: FloatingActionButton(
            backgroundColor: c.accent,
            onPressed: () => setState(() => _open = !_open),
            child: Icon(_open ? LucideIcons.x : LucideIcons.sparkles,
                color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onClose,
  });
  final List<_ChatMessage> messages;
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: 340,
        height: 460,
        decoration: BoxDecoration(
          color: c.bgCard,
          borderRadius: AppRadii.modalR,
          border: Border.all(color: c.border),
          boxShadow: AppShadows.editorial(Theme.of(context).brightness),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.borderSubtle)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.sparkles, size: 16, color: c.accent),
                  const SizedBox(width: 8),
                  Text('AI Assistant',
                      style: AppTypography.labelLarge(c.textPrimary)),
                  const Spacer(),
                  InkWell(
                    onTap: onClose,
                    child: Icon(LucideIcons.x, size: 16, color: c.textMuted),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: messages.length + (sending ? 1 : 0),
                itemBuilder: (_, i) {
                  if (sending && i == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            color: c.bgRaised, borderRadius: AppRadii.modalR),
                        child: Text('Thinking…',
                            style: AppTypography.bodyMedium(c.textMuted)),
                      ),
                    );
                  }
                  return _Bubble(message: messages[i]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      onSubmitted: (_) => onSend(),
                      decoration:
                          const InputDecoration(hintText: 'Ask anything…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(LucideIcons.send, color: c.accent, size: 18),
                    onPressed: onSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final align =
        message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = message.fromUser ? c.accent : c.bgRaised;
    final fg = message.fromUser
        ? (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF14140F)
            : Colors.white)
        : c.textPrimary;
    return Align(
      alignment: align,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 260),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadii.modalR),
        child: message.fromUser
            ? Text(message.text, style: AppTypography.bodyMedium(fg))
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: AppTypography.bodyMedium(fg),
                  strong: AppTypography.bodyMedium(fg)
                      .copyWith(fontWeight: FontWeight.w700),
                  em: AppTypography.bodyMedium(c.textMuted)
                      .copyWith(fontStyle: FontStyle.italic),
                  listBullet: AppTypography.bodyMedium(fg),
                ),
              ),
      ),
    );
  }
}
