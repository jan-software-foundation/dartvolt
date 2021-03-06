part of dartvolt;

class WSClient {
    late Client revoltClient;
    int heartbeat;
    bool connected = false;
    bool ready = false;
    late _RevoltEventHandler evtHandler = _RevoltEventHandler(revoltClient);
    
    late WebSocketChannel _wsClient;
    
    WSClient({
        required this.revoltClient,
        this.heartbeat = 10
    });
    
    Future connect() async {
        _wsClient = WebSocketChannel.connect(
            Uri.parse(revoltClient.serverConfig.wsURL)
        );
        
        _wsClient.stream.listen((message) {
            revoltClient._logger.debug('[WS] [IN]  $message');
            evtHandler._handleWSEvent(jsonDecode(message));
        });
        
        // Authentication
        var authPayload = {
            'type': 'Authenticate',
            'id': revoltClient.sessionInfo.sessionId,
            'user_id': revoltClient.sessionInfo.clientId,
            'session_token': revoltClient.sessionInfo.sessionToken
        };
        send(authPayload);
        
        // Heartbeat
        var time = Duration(seconds: heartbeat);
        Timer.periodic(time, (timer) {
            var timestamp = DateTime.now().millisecondsSinceEpoch;
            var heartbeatPayload = {
                'type': 'Ping',
                'time': '$timestamp'
            };
            send(heartbeatPayload);
        });
    }
    
    void send(Map<String, dynamic> payload) {
        // Redact session token from payload
        var loggedPayload = jsonEncode(payload);
        
        loggedPayload = loggedPayload.replaceAll(
            revoltClient.sessionInfo.sessionToken,
            '[Session Token]'
        );
        
        revoltClient._logger.debug('[WS] [OUT] $loggedPayload');
        _wsClient.sink.add(jsonEncode(payload));
    }
}
