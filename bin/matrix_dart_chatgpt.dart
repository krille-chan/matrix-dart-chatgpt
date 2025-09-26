import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:matrix/matrix.dart';

import 'package:matrix_dart_chatgpt/config.dart';
import 'package:matrix_dart_chatgpt/connect_matrix_client.dart';
import 'package:matrix_dart_chatgpt/connect_streams.dart';

void main(List<String> arguments) async {
  final config = BotConfig.fromFile(arguments.singleOrNull ?? './config.json');

  final openAI = OpenAI.instance.build(
    token: config.openAiKey,
    baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 30)),
    enableLog: true,
  );

  final client = await connectMatrixClient(config);
  Logs().level = Level.verbose;
  client.connectChatGPTStreams(config, openAI);

  Logs().i(
    'Matrix Dart ChatGPT Bot started with introduction prompt',
    config.introductionPrompt,
  );
}
