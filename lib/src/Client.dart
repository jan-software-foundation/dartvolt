part of dartvolt;

class Client {
  late _clientConfig config;
  late ServerConfig serverConfig;
  final Map<String, String> _httpHeaders = {};
  late _Logger _logger;
  bool _authStarted = false;
  _AuthMethod authMethod = _AuthMethod.None;
  WSClient? wsClient;
  String? token;

  Client({
    String userAgent =
        'Dartvolt/1.0 (+https://github.com/jan-software-foundation/dartvolt)',
    bool debug = false,
    String apiUrl = 'https://api.revolt.chat',
  }) {
    config = _clientConfig(
      userAgent: userAgent,
      debug: debug,
      apiUrl: apiUrl,
    );

    _logger = _Logger(this);
    _httpHeaders['User-Agent'] = config.userAgent;
  }

  Future<void> botLogin({required String token}) async {
    if (_authStarted) throw 'This client is already authenticating';
    _authStarted = true;
    _httpHeaders['x-bot-token'] = token;
    this.token = token;
    authMethod = _AuthMethod.Bot;

    var res = await http.get(Uri.parse(config.apiUrl + '/users/@me'),
        headers: _httpHeaders);

    if (res.statusCode != 200) {
      throw 'Failed to authenticate: HTTP ${res.statusCode}\n' + res.body;
    }

    var body = jsonDecode(res.body);
    _logger.debug('Validated bot token: $body');

    // TODO put this into its own method
    await _fetchServerConfig();

    wsClient = WSClient(this);
    await wsClient!._authenticate();
  }

  Future<void> useExistingSession({required String sessionToken}) async {
    if (_authStarted) throw 'This client is already authenticating';
    _authStarted = true;
    _httpHeaders['x-session-token'] = sessionToken;
    token = sessionToken;
    authMethod = _AuthMethod.User;

    var res = await http.get(Uri.parse(config.apiUrl + '/auth/account'),
        headers: _httpHeaders);

    if (res.statusCode != 200) {
      throw 'Failed to authenticate: HTTP ${res.statusCode}\n' + res.body;
    }

    var body = jsonDecode(res.body);
    _logger.debug('Validated session: $body');
    // { _id: string, email: string }
    // todo: create client user object

    await _fetchServerConfig();

    wsClient = WSClient(this);
    await wsClient!._authenticate();
  }

  Future<void> _fetchServerConfig() async {
    var res = await http.get(Uri.parse(config.apiUrl));

    if (res.statusCode != 200) {
      throw 'Failed to fetch server config: HTTP ${res.statusCode}\n' +
          res.body;
    }

    serverConfig = ServerConfig.fromJSON(jsonDecode(res.body));
    _logger.debug('Fetched server config');
  }
}

class _clientConfig {
  /// The User-Agent header that is sent with every request. Default:
  /// `Dartvolt/1.0 (+https://github.com/jan-software-foundation/dartvolt)`
  String userAgent;

  /// Enables debug logging
  bool debug;

  /// The API to connect to. Default: `https://api.revolt.chat`
  String apiUrl;

  _clientConfig({
    required this.userAgent,
    this.debug = false,
    required this.apiUrl,
  });
}

enum _AuthMethod { User, Bot, None }
