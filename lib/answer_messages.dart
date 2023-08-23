import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_chatgpt/config.dart';

void answerMessage(Event event, OpenAI openAI, BotConfig config) async {
  await event.room.setTyping(true);

  final prompt = config.introductionPrompt;

  const int messageCount = 60;
  const int maxMessageLength = 50;

  final timeline = await event.room.getTimeline();
  try {
    await timeline.requestHistory(
        historyCount: messageCount - Room.defaultHistoryCount);
  } catch (e, s) {
    Logs().w('Unable to request history in room ${event.roomId}', e, s);
  }

  final messages = timeline.events
      .where((event) =>
          event.type == EventTypes.Message &&
          event.messageType == MessageTypes.Text &&
          !event.redacted)
      .map(
        (event) => Messages(
          role: event.senderId == event.room.client.userID
              ? Role.assistant
              : Role.user,
          content: event.body.substring(
            0,
            max(
              maxMessageLength,
              event.body.length,
            ),
          ),
        ),
      )
      .toList()
      .reversed
      .toList();

  try {
    final response = await openAI.onChatCompletion(
      request: ChatCompleteText(
        messages: [
          if (prompt != null)
            Messages(
              role: Role.system,
              content: prompt,
            ),
          ...messages,
        ],
        model: GptTurboChatModel(),
        user: event.roomId,
        temperature: 1,
        maxToken: null,
      ),
    );
    await event.room.sendTextEvent(
      response?.choices.firstOrNull?.message?.content ??
          'Error: Response is null',
    );
  } catch (e) {
    await event.room.sendTextEvent('Error: $e');
  } finally {
    await event.room.setTyping(false);
    timeline.cancelSubscriptions();
  }
}
