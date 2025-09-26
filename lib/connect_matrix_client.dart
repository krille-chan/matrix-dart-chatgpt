import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import 'package:matrix_dart_chatgpt/config.dart';

Future<Client> connectMatrixClient(BotConfig config) async {
  await vod.init(libraryPath: './vod/release/');
  final client = Client(
    'matrix_dart_chatgpt',
    database: await MatrixSdkDatabase.init(
      '<Database Name>',
      database: await databaseFactoryFfi.openDatabase('./matrix.sqlite'),
      sqfliteFactory: databaseFactoryFfi,
    ),
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
