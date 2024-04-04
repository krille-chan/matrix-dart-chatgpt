import 'dart:convert';
import 'dart:io';

import 'package:matrix/matrix.dart';

class BotConfig {
  final String matrixId;
  final String token;
  final String homeserver;
  final String openAiKey;
  final String? displayname;
  final String? introductionPrompt;
  final Level logLevel;
  final List<String> allowList;

  const BotConfig({
    required this.matrixId,
    required this.token,
    required this.homeserver,
    required this.openAiKey,
    this.displayname,
    this.introductionPrompt,
    required this.logLevel,
    required this.allowList,
  });

  factory BotConfig.fromJson(Map json) => BotConfig(
        matrixId: json['matrixId'],
        token: json['token'],
        homeserver: json['homeserver'],
        openAiKey: json['openAiKey'],
        displayname: json['displayname'],
        logLevel: Level.values.singleWhere(
          (l) => l.name == (json['logLevel'] ?? 'info'),
        ),
        allowList: List<String>.from(json['allowList']),
        introductionPrompt: json['introductionPrompt'],
      );

  factory BotConfig.fromFile(String path) {
    final file = File(path);
    final jsonStr = file.readAsStringSync();
    final json = jsonDecode(jsonStr);
    return BotConfig.fromJson(json);
  }
}
