import 'dart:convert';
import 'dart:io';

import 'package:matrix_dart_chatgpt/config.dart';
import 'package:ti_messenger_client_sdk/ti_messenger_client_sdk.dart';
import 'package:http/http.dart' as http;

Future<Client> connectMatrixClient(BotConfig config) async {
  final client = TiMessengerClient(
    'matrix_dart_chatgpt',
    databaseBuilder: (_) async {
      final directory = Directory('./database/hive');
      await directory.create(recursive: true);
      final db = HiveCollectionsDatabase('matrix_example_chat', directory.path);
      await db.open();
      return db;
    },
    logLevel: config.logLevel,
    timHttpClient: TimHttpClient(
      productTypeVersion: '1.1.1',
      productVersion: 'v0.1',
      characteristics: TimProductCharacteristics.messengerClient,
      platform: TimPlatform.stationary,
      operatingSystem: TimOperatingSystem.linux,
      osVersion: Platform.operatingSystemVersion,
      clientId: 'none',
    ),
  );
  client.syncPresence = PresenceType.offline;

  await client.init();

  if (!client.isLogged()) {
    await client.checkHomeserver(Uri.parse(config.homeserver));
    await client.loginWithToken(
      'com.famedly.login.token.oidc',
      identifier: AuthenticationUserIdentifier(user: config.matrixId),
      token: config.token,
    );
  }

  return client;
}

extension ClientOidcExtension on Client {
  Future<void> loginWithToken(
    String type, {
    String? deviceId,
    AuthenticationIdentifier? identifier,
    String? initialDeviceDisplayName,
    bool? refreshToken,
    String? token,
  }) async {
    final requestUri = Uri(path: '_matrix/client/v3/login');
    final request = http.Request('POST', baseUri!.resolveUri(requestUri));
    request.headers['content-type'] = 'application/json';
    request.bodyBytes = utf8.encode(
      jsonEncode({
        if (deviceId != null) 'device_id': deviceId,
        if (identifier != null) 'identifier': identifier.toJson(),
        if (initialDeviceDisplayName != null)
          'initial_device_display_name': initialDeviceDisplayName,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (token != null) 'token': token,
        'type': type,
      }),
    );
    final response = await httpClient.send(request);
    final responseBody = await response.stream.toBytes();
    if (response.statusCode != 200) {
      unexpectedResponse(response, responseBody);
    }
    final responseString = utf8.decode(responseBody);
    final json = jsonDecode(responseString);
    final loginResponse = LoginResponse.fromJson(json as Map<String, Object?>);
    // Connect if there is an access token in the response.
    final accessToken = loginResponse.accessToken;
    final deviceId_ = loginResponse.deviceId;
    final userId = loginResponse.userId;
    final homeserver_ = homeserver;
    if (homeserver_ == null) {
      throw Exception('Registered but homeserver is null.');
    }

    final expiresInMs = loginResponse.expiresInMs;
    final tokenExpiresAt = expiresInMs == null
        ? null
        : DateTime.now().add(Duration(milliseconds: expiresInMs));

    await init(
      newToken: accessToken,
      newTokenExpiresAt: tokenExpiresAt,
      newRefreshToken: loginResponse.refreshToken,
      newUserID: userId,
      newHomeserver: homeserver_,
      newDeviceName: initialDeviceDisplayName ?? '',
      newDeviceID: deviceId_,
    );
  }
}
