import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_chatgpt/answer_messages.dart';
import 'package:matrix_dart_chatgpt/config.dart';

extension ConnectStreams on Client {
  void connectChatGPTStreams(BotConfig config, OpenAI openAi) {
    onEvent.stream
        .where((eventUpdate) =>
            eventUpdate.type == EventUpdateType.timeline &&
            eventUpdate.content['type'] == EventTypes.Message &&
            eventUpdate.content['content']['msgtype'] == MessageTypes.Text &&
            eventUpdate.content['sender'] != userID)
        .listen(
          (eventUpdate) => answerMessage(
            Event.fromJson(
              eventUpdate.content,
              getRoomById(eventUpdate.roomID)!,
            ),
            openAi,
            config,
          ),
        );

    onEvent.stream
        .where((eventUpdate) =>
            eventUpdate.type == EventUpdateType.inviteState &&
            eventUpdate.content['type'] == EventTypes.RoomMember &&
            eventUpdate.content['state_key'] == userID &&
            eventUpdate.content['sender'] != userID)
        .listen(
      (eventUpdate) {
        final sender = eventUpdate.content['sender'] as String;
        Logs().i('Received invite from $sender');
        if (!config.allowList
            .any((allowRegex) => RegExp(allowRegex).hasMatch(sender))) {
          Logs().w('$sender is not in allow list! Ignoring invite.');
          return;
        }
        getRoomById(eventUpdate.roomID)!.join();
      },
    );
  }
}
