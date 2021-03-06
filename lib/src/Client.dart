part of dartvolt;

class Client {
    Client(ClientConfig config) {
        clientConfig = config;
    }
    
    ClientConfig clientConfig = ClientConfig();
    late ServerConfig serverConfig;
    late WSClient wsClient;
    Map<String, String> _authHeaders = {};
    var _authStarted = false;
    late SessionInfo sessionInfo;
    
    late var users    = UserManager(this);
    late var channels = ChannelManager(this);
    late var messages = ClientMessageManager(this);
    late var servers  = ServerManager(this);
    
    /// The user the client logged in as.
    late User user;
    
    late final _logger = Logger(this);
    
    /// Eventify event emitter.
    /// Emits the following events:
    /// 
    /// `ready` -> [Client] \
    /// `authenticated` -> [null] \
    /// `message/create` -> [Message] \
    /// `message/update` -> [MessageEdit] \
    /// `message/delete` -> [Message] \
    /// `channel/create` -> [Channel] \
    /// `channel/update` -> [ChannelUpdateEvent] \
    /// `channel/delete` -> [Channel] The cached channel,
    ///  or a partial DummyChannel object \
    /// `channel/join` -> [Channel] \
    /// `channel/leave` -> [String] Channel ID \
    /// `channel/userAdded` -> [ChannelMemberAddEvent] \
    /// `channel/userLeave` -> [ChannelMemberLeaveEvent] \
    /// `server/join` -> [Server] Emitted when the client is
    ///  added to a new server \
    /// `server/memberJoin` -> [Member] Emitted when a user is
    ///  added to a server the client is already in \
    /// `server/leave` -> [String] Server ID -
    ///  Emitted when the client leaves a server \
    /// `server/memberLeave` -> [String] User ID -
    ///  Emitted when a user leaves a server the client is in \
    /// `server/memberUpdate` -> [Member] \
    /// `server/roleUpdate` -> [Role] \
    /// `server/roleDelete` -> [String] Role ID \
    /// `server/update` -> [ServerUpdate] \
    /// `server/delete` -> [String] ID of the deleted server \
    /// `user/update` -> [UserUpdate] \
    /// `user/relationship` -> [RelationshipUpdate]
    /// 
    /// Example: \
    /// `client.events.on('ready', null, (ev, ctx) { /* do something */ })`
    /// 
    /// You can also prefix `APIEvent/` to listen for WS events directly. \
    /// `client.events.on('APIEvent/Ready', null, (ev, ctx) {})`
    EventEmitter events = EventEmitter();
    
    /// Functions that might or might not be useful
    var utilities = UtilityFunctions();
    
    /// Generate a new session using username/password
    Future<void> login(AuthInfo authInfo) async {
        serverConfig = await _fetchServerConfig();
        //if (serverConfig.captcha != null && authInfo.captcha == null) {
        //    throw 'Server requires captcha, but none was provided';
        //}
        
        var authBody = {
            'email': authInfo.email,
            'password': authInfo.password,
        };
        
        if (authInfo.device_name != null) {
            authBody['device_name'] = authInfo.device_name as String;
        }
        if (authInfo.captcha != null) {
            authBody['captcha'] = authInfo.captcha as String;
        }
        
        var res = await http.post(
            Uri.parse(clientConfig.apiUrl + '/auth/login'),
            body: jsonEncode(authBody),
            headers: { 'User-Agent': clientConfig.user_agent }
        );
        
        print(res.body);
        if (res.statusCode != 200) throw res.body;
    }
    
    /// Use an existing session
    Future<void> useExistingSession(SessionInfo session) async {
        if (_authStarted) throw 'Cannot authenticate again';
        _authStarted = true;
        sessionInfo = session;
        _authHeaders = {
            'x-user-id': session.clientId,
            'x-session-token': session.sessionToken,
            'User-Agent': clientConfig.user_agent,
        };
        
        serverConfig = await _fetchServerConfig();
        
        if (!await _validateSession(session, clientConfig)) {
            throw 'Invalid session';
        }
        
        wsClient = WSClient(revoltClient: this, heartbeat: 10);
        await wsClient.connect();
    }
    
    Future<bool> _validateSession(
        SessionInfo session,
        ClientConfig clientConfig
    ) async {
        var res = await http.get(
            Uri.parse(clientConfig.apiUrl + '/auth/check'),
            headers: _authHeaders
        );
        
        if (res.statusCode != 200) {
            _logger.debug('${res.statusCode} : ${res.body}');
        }
        
        return res.statusCode == 200;
    }
    
    Future<ServerConfig> _fetchServerConfig() async {
        var res = await http.get(Uri.parse(clientConfig.apiUrl));
        Map<String, dynamic> config = jsonDecode(res.body);
        Map<String, dynamic> features = config['features'];
        return ServerConfig(
            wsURL:                  config['ws'],
            appURL:                 config['app'],
            vapid:                  config['vapid'],
            version:                config['revolt'],
            emailEnabled:           features['email'],
            inviteOnly:             features['invite_only'],
            captchaEnabled:         features['captcha']?['enabled'],
            captcha:                features['captcha']?['key'],
            januaryURL:             features['january']?['url'],
            autumnURL:              features['autumn']?['url'],
            vosoURL:                features['voso']['url'],
            vosoWS:                 features['voso']['ws']
        );
    }
}
