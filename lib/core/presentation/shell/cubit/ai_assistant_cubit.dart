import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

class ChatMessage extends Equatable {
  const ChatMessage(this.text, {required this.fromUser});

  final String text;
  final bool fromUser;

  ChatMessage copyWith({String? text}) =>
      ChatMessage(text ?? this.text, fromUser: fromUser);

  @override
  List<Object?> get props => [text, fromUser];
}

class AiAssistantState extends Equatable {
  const AiAssistantState({
    this.open = false,
    this.sending = false,
    this.messages = const [],
  });

  final bool open;
  final bool sending;
  final List<ChatMessage> messages;

  AiAssistantState copyWith({
    bool? open,
    bool? sending,
    List<ChatMessage>? messages,
  }) =>
      AiAssistantState(
        open: open ?? this.open,
        sending: sending ?? this.sending,
        messages: messages ?? this.messages,
      );

  @override
  List<Object?> get props => [open, sending, messages];
}

/// Floating AI assistant chat. Owns the panel-open flag, message log, the
/// streaming-reply flag, and the [TextEditingController] (disposed in
/// [close]). One instance per widget mount, DI-registered as a factory.
class AiAssistantCubit extends Cubit<AiAssistantState> {
  AiAssistantCubit(this._repo)
      : controller = TextEditingController(),
        super(const AiAssistantState(messages: [
          ChatMessage(
            "Hi! I'm your **AskAide** study buddy. Ask me to explain a concept or "
            'suggest what to practice next.',
            fromUser: false,
          ),
        ]));

  final AiChatRepository _repo;
  final TextEditingController controller;

  void togglePanel() => emit(state.copyWith(open: !state.open));

  Future<void> send() async {
    final text = controller.text.trim();
    if (text.isEmpty || state.sending) return;
    controller.clear();
    emit(state.copyWith(
      messages: [...state.messages, ChatMessage(text, fromUser: true)],
      sending: true,
    ));

    final buffer = StringBuffer();
    var added = false;
    await for (final chunk in _repo.stream(text)) {
      if (isClosed) return;
      buffer.write(chunk);
      final messages = List<ChatMessage>.from(state.messages);
      if (!added) {
        messages.add(ChatMessage(buffer.toString(), fromUser: false));
        added = true;
      } else {
        messages[messages.length - 1] =
            messages.last.copyWith(text: buffer.toString());
      }
      emit(state.copyWith(messages: messages, sending: false));
    }
    if (isClosed) return;
    if (!added) {
      emit(state.copyWith(
        messages: [
          ...state.messages,
          const ChatMessage(
            "Sorry — I couldn't reach the assistant just now.",
            fromUser: false,
          ),
        ],
        sending: false,
      ));
    } else {
      emit(state.copyWith(sending: false));
    }
  }

  @override
  Future<void> close() {
    controller.dispose();
    return super.close();
  }
}
