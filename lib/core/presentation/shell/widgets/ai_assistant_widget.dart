import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../di/injection.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_tokens.dart';
import '../../../theme/app_typography.dart';
import '../cubit/ai_assistant_cubit.dart';

/// Floating AI assistant. Tapping the FAB opens a chat panel that renders
/// markdown answers, wired to the live `/ai-assistant` endpoint.
class AiAssistantWidget extends StatelessWidget {
  const AiAssistantWidget({
    super.key,
    this.bottomOffset = AppSpacing.md,
  });

  /// Distance from the bottom edge for the floating assistant button.
  /// The mobile authenticated shell passes a larger value so the assistant
  /// clears the bottom navigation bar on iOS and Android.
  final double bottomOffset;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AiAssistantCubit>(
      create: (_) => sl<AiAssistantCubit>(),
      child: Builder(builder: (context) => _buildStack(context)),
    );
  }

  Widget _buildStack(BuildContext context) {
    final c = context.colors;
    final cubit = context.read<AiAssistantCubit>();
    return BlocBuilder<AiAssistantCubit, AiAssistantState>(
      builder: (context, state) => Stack(
        children: [
          if (state.open)
            Positioned(
              right: AppSpacing.md,
              bottom: bottomOffset + 68,
              child: _ChatPanel(
                messages: state.messages,
                controller: cubit.controller,
                sending: state.sending,
                onSend: cubit.send,
                onClose: cubit.togglePanel,
              ),
            ),
          Positioned(
            right: AppSpacing.md,
            bottom: bottomOffset,
            child: FloatingActionButton(
              backgroundColor: c.accent,
              onPressed: cubit.togglePanel,
              child: Icon(state.open ? LucideIcons.x : LucideIcons.sparkles,
                  color: Colors.white),
            ),
          ),
        ],
      ),
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
  final List<ChatMessage> messages;
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
  final ChatMessage message;

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
