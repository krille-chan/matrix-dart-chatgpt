import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix_dart_chatgpt/answer_messages.dart';
import 'package:matrix_dart_chatgpt/config.dart';

extension ConnectStreams on Client {
  void connectChatGPTStreams(BotConfig config, OpenAI openAi) {
    onEvent.stream
        .where((eventUpdate) =>
            eventUpdate.type == EventUpdateType.timeline &&
            config.allowList.contains(eventUpdate.content['sender']) &&
            eventUpdate.content['type'] == EventTypes.Message &&
            eventUpdate.content['content']['msgtype'] == MessageTypes.Text)
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
            config.allowList.contains(eventUpdate.content['sender']) &&
            eventUpdate.content['type'] == EventTypes.RoomMember &&
            eventUpdate.content['state_key'] == userID)
        .listen(
          (eventUpdate) => getRoomById(eventUpdate.roomID)!.join(),
        );
  }
}
