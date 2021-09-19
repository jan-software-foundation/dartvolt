part of dartvolt;

class WSClient {
  Client client;
  late EventHandler eventHandler;
  late WebSocketChannel _ws;
  bool connecting = false, ready = false;

  WSClient(this.client, {bool connectImmediately = true}) {
    eventHandler = EventHandler(client, this);
    if (connectImmediately == true) _connect();
  }

  /// connect to deez nuts lmao
  void _connect() async {
    if (ready || connecting) throw 'Already connecting';
    connecting = true;

    client._logger.debug('WS connecting');
    _ws = WebSocketChannel.connect(client.serverConfig.ws);

    _ws.stream.listen((message) {
      client._logger.debug('[WS] [IN]  $message');
    });
  }

  /// Send the `Authenticate` payload to authenticate the WebSocket connection.
  /// Returns after the `ready` event is received.
  Future<void> _authenticate() async {
    if (!connecting) {
      throw 'No connection attempt made yet; cannot authenticate';
    }

    if (ready) throw 'Already authenticated';

    var authPayload = {
      'type': 'Authenticate',
      'token': client.token,
    };

    client._logger.debug('WS authenticating');

    send(authPayload);
  }

  void send(Map<String, dynamic> payload) {
    // Redact the session token from the debug logs
    var loggedPayload = client.token != null
        ? jsonEncode(payload).replaceAll(client.token!, '[Session Token]')
        : jsonEncode(payload);

    client._logger.debug('[WS] [OUT] $loggedPayload');

    _ws.sink.add(jsonEncode(payload));
  }
}
