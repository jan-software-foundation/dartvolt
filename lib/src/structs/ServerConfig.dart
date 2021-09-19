part of dartvolt;

class ServerConfig {
  /// Revolt API version
  late String version;

  /// Whether emails are enabled on the server
  late bool email;

  /// Whether the server requires an invite code for registration
  late bool invite_only;

  /// The URL that WebSocket connections should connect to
  late Uri ws;

  /// The address at which the web app is hosted
  late Uri app;

  /// Required for push notifications
  late String vapid;

  /// The server's captcha configuration
  late _serverCaptchaConfig captcha;

  /// Autumn is Revolt's CDN.
  late _serverAutumnConfig autumn;

  /// January is Revolt's media proxy and embed service.
  late _serverJanuaryConfig january;

  /// Voso is Revolt's WebRTC server and responsible for calls and voice chats.
  late _serverVosoConfig voso;

  ServerConfig({
    required this.version,
    required this.email,
    required this.invite_only,
    required this.ws,
    required this.app,
    required this.vapid,
    required this.captcha,
    required this.autumn,
    required this.january,
    required this.voso,
  });

  ServerConfig.fromJSON(Map<String, dynamic> json) {
    version = json['revolt'];
    email = json['features']['email'];
    invite_only = json['features']['invite_only'];
    ws = Uri.parse(json['ws']);
    app = Uri.parse(json['app']);
    vapid = json['vapid'];
    captcha = _serverCaptchaConfig(
      enabled: json['features']['captcha']['enabled'],
      captchaKey: json['features']['captcha']['key'],
    );
    autumn = _serverAutumnConfig(
      enabled: json['features']['autumn']['enabled'],
      url: Uri.parse(json['features']['autumn']['url']),
    );
    january = _serverJanuaryConfig(
      enabled: json['features']['january']['enabled'],
      url: Uri.parse(json['features']['january']['url']),
    );
    voso = _serverVosoConfig(
      enabled: json['features']['voso']['enabled'],
      url: Uri.parse(json['features']['voso']['url']),
      ws: Uri.parse(json['features']['voso']['ws']),
    );
  }
}

class _serverCaptchaConfig {
  /// Captcha enabled?
  bool enabled;

  /// The ReCaptcha public key
  String? captchaKey;

  _serverCaptchaConfig({required this.enabled, this.captchaKey});
}

class _serverAutumnConfig {
  bool enabled;
  Uri? url;

  _serverAutumnConfig({required this.enabled, this.url});
}

class _serverJanuaryConfig {
  bool enabled;
  Uri? url;

  _serverJanuaryConfig({required this.enabled, this.url});
}

class _serverVosoConfig {
  bool enabled;
  Uri? url;
  Uri? ws;

  _serverVosoConfig({required this.enabled, this.url, this.ws});
}
