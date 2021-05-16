part of dartvolt;

class Client {
    Client(ClientConfig config) {
        this.clientConfig = config;
    }
    
    ClientConfig clientConfig = ClientConfig();
    late ServerConfig serverConfig;
    late WSClient wsClient;
    Map<String, String> _authHeaders = {};
    var _authStarted = false;
    SessionInfo? sessionInfo;
    
    /// Use an existing session
    useExistingSession(SessionInfo session) async {
        if (_authStarted) throw 'Cannot authenticate again';
        _authStarted = true;
        sessionInfo = session;
        _authHeaders = {
            'x-user-id': session.clientId,
            'x-session-token': session.sessionToken
        };
        
        serverConfig = await _fetchServerConfig();
        
        if (!await _validateSession(session, clientConfig)) {
            throw 'Invalid session';
        }
        
        wsClient = WSClient(revoltClient: this, heartbeat: 10);
        await wsClient.connect();
    }
    
    Future<bool> _validateSession(SessionInfo session, ClientConfig clientConfig) async {
        var res = await http.get(
            Uri.parse(clientConfig.API_URL + '/auth/check'),
            headers: _authHeaders
        );
        
        return res.statusCode == 200;
    }
    
    Future<ServerConfig> _fetchServerConfig() async {
        var res = await http.get(Uri.parse(clientConfig.API_URL));
        Map<String, dynamic> config = jsonDecode(res.body);
        Map<String, dynamic> features = config['features'];
        return ServerConfig(
            wsURL:                  config['ws'],
            appURL:                 config['app'],
            vapid:                  config['vapid'],
            version:                config['revolt'],
            emailEnabled:           features['email'],
            inviteOnly:             features['invite_only'],
            registrationEnabled:    features['registration'],
            captcha:                features['captcha']?['key'],
            januaryURL:             features['january']?['url'],
            autumnURL:              features['autumn']?['url'],
            vosoURL:                features['voso']['url'],
            vosoWS:                 features['voso']['ws']
        );
    }
}