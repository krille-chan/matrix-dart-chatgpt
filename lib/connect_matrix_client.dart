import 'dart:io';

import 'package:matrix/matrix.dart';
import 'package:matrix_dart_chatgpt/config.dart';

Future<Client> connectMatrixClient(BotConfig config) async {
  final client = Client(
    'matrix_dart_chatgpt',
    databaseBuilder: (_) async {
      final directory = Directory('./database/hive');
      await directory.create(recursive: true);
      final db = HiveCollectionsDatabase('matrix_example_chat', directory.path);
      await db.open();
      return db;
    },
    logLevel: config.logLevel,
  );
  client.syncPresence = PresenceType.offline;

  await client.init();

  if (!client.isLogged()) {
    await client.checkHomeserver(Uri.parse(config.homeserver));
    await client.login(
      LoginType.mLoginPassword,
      identifier: AuthenticationUserIdentifier(user: config.matrixId),
      password: config.password,
    );
  }

  return client;
}
