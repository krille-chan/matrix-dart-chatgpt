import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart';

import 'package:matrix_dart_chatgpt/answer_messages.dart';
import 'package:matrix_dart_chatgpt/config.dart';

extension ConnectStreams on Client {
  void connectChatGPTStreams(BotConfig config, OpenAI openAi) {
    onTimelineEvent.stream
        .where((event) =>
            event.type == EventTypes.Message &&
            event.messageType == MessageTypes.Text &&
            event.senderId != userID)
        .listen(
          (event) => answerMessage(
            event,
            openAi,
            config,
          ),
        );

    onNotification.stream
        .where((event) => event.room.membership == Membership.invite)
        .listen(
      (event) {
        final sender = event.senderId;
        Logs().i('Received invite from $sender');
        if (!config.allowList
            .any((allowRegex) => RegExp(allowRegex).hasMatch(sender))) {
          Logs().w('$sender is not in allow list! Ignoring invite.');
          return;
        }
        event.room.join();
      },
    );
  }
}
