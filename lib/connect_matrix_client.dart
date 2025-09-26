import 'dart:async';

import 'package:matrix/encryption/utils/bootstrap.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import 'package:matrix_dart_chatgpt/config.dart';

Future<Client> connectMatrixClient(BotConfig config) async {
  await vod.init(libraryPath: './vod/release/');
  final client = Client(
    'matrix_dart_chatgpt',
    database: await MatrixSdkDatabase.init(
      'matrix_dart_chatgpt',
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
      initialDeviceDisplayName: config.displayname,
      identifier: AuthenticationUserIdentifier(user: config.matrixId),
      password: config.password,
    );
  }

  final passphrase = config.passphrase;
  final completer = Completer();
  client.encryption?.bootstrap(onUpdate: (bootstrap) async {
    final wipe = passphrase == null;
    switch (bootstrap.state) {
      case BootstrapState.loading:
        return;
      case BootstrapState.askWipeSsss:
        bootstrap.wipeSsss(wipe);
        return;
      case BootstrapState.askUseExistingSsss:
        bootstrap.useExistingSsss(!wipe);
        return;
      case BootstrapState.askUnlockSsss:
        bootstrap.unlockedSsss();
        return;
      case BootstrapState.askBadSsss:
        bootstrap.ignoreBadSecrets(true);
        return;
      case BootstrapState.askNewSsss:
        bootstrap.newSsss(passphrase);
        return;
      case BootstrapState.openExistingSsss:
        await bootstrap.newSsssKey!.unlock(keyOrPassphrase: passphrase);
        await bootstrap.openExistingSsss();
        await bootstrap.client.encryption!.crossSigning
            .selfSign(recoveryKey: passphrase);
        return;
      case BootstrapState.askWipeCrossSigning:
        bootstrap.wipeCrossSigning(wipe);
        return;
      case BootstrapState.askSetupCrossSigning:
        bootstrap.askSetupCrossSigning(
          setupMasterKey: true,
          setupSelfSigningKey: true,
          setupUserSigningKey: true,
        );
      case BootstrapState.askWipeOnlineKeyBackup:
        bootstrap.wipeOnlineKeyBackup(wipe);
        return;
      case BootstrapState.askSetupOnlineKeyBackup:
        bootstrap.askSetupOnlineKeyBackup(true);
        return;
      case BootstrapState.error:
        completer.completeError(bootstrap);
        return;
      case BootstrapState.done:
        completer.complete();
        return;
    }
  });

  await completer.future;

  return client;
}
