import 'dart:convert';
import 'dart:io';

import 'package:matrix/matrix.dart';

class BotConfig {
  final String matrixId;
  final String? password;
  final String? accessToken;
  final String homeserver;
  final String openAiKey;
  final String? displayname;
  final String? introductionPrompt;
  final String? passphrase;
  final Level logLevel;
  final List<String> allowList;

  const BotConfig({
    required this.matrixId,
    required this.password,
    required this.homeserver,
    required this.openAiKey,
    this.displayname,
    this.introductionPrompt,
    required this.logLevel,
    required this.allowList,
    required this.passphrase,
    required this.accessToken,
  });

  factory BotConfig.fromJson(Map json) => BotConfig(
        matrixId: json['matrixId'],
        password: json['password'],
        homeserver: json['homeserver'],
        openAiKey: json['openAiKey'],
        displayname: json['displayname'],
        logLevel: Level.values.singleWhere(
          (l) => l.name == (json['logLevel'] ?? 'info'),
        ),
        allowList: List<String>.from(json['allowList']),
        introductionPrompt: json['introductionPrompt'],
        passphrase: json['passphrase'],
        accessToken: json['accessToken'],
      );

  factory BotConfig.fromFile(String path) {
    final file = File(path);
    final jsonStr = file.readAsStringSync();
    final json = jsonDecode(jsonStr);
    return BotConfig.fromJson(json);
  }
}
