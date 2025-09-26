import 'dart:math';

import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart' hide Role;

import 'package:matrix_dart_chatgpt/config.dart';

void answerMessage(Event event, OpenAI openAI, BotConfig config) async {
  Logs().i('Received new message from ${event.senderId}');
  if (!config.allowList
      .any((allowRegex) => RegExp(allowRegex).hasMatch(event.senderId))) {
    Logs().w('${event.senderId} is not in allow list! Ignoring message.');
    return;
  }

  event.room.client.syncPresence = PresenceType.online;
  await event.room.setTyping(true);

  final prompt = config.introductionPrompt;

  const int maxMessageLength = 1000;

  final timeline = await event.room.getTimeline();

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
            min(
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
            ).toJson(),
          ...messages.map((m) => m.toJson()),
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
    event.room.client.syncPresence = PresenceType.offline;
    await event.room.setTyping(false);
    timeline.cancelSubscriptions();
  }
}
