part of dartvolt;

class ServerConfig {
    String version;
    bool registrationEnabled;
    bool emailEnabled;
    bool inviteOnly;
    bool captchaEnabled;
    String? captcha;
    String wsURL;
    String appURL;
    String vapid;
    
    _Autumn? autumn;
    _Voso? voso;
    _January? january;
    
    /// Create server config
    ServerConfig({
        required this.version,
        required this.registrationEnabled,
        required this.emailEnabled,
        required this.inviteOnly,
        required this.captchaEnabled,
        required this.captcha,
        required this.wsURL,
        required this.appURL,
        required this.vapid,
        required autumnURL,
        required januaryURL,
        required vosoURL,
        required vosoWS
    }) {
        autumn = _Autumn(url: autumnURL);
        january = _January(url: januaryURL);
        voso = _Voso(url: vosoURL, wsUrl: vosoWS);
    }
}

class _Autumn {
    String? url;
    _Autumn({ this.url });
}

class _Voso {
    String? url;
    String? wsUrl;
    _Voso({ this.url, this.wsUrl });
}

class _January {
    String? url;
    _January({ this.url });
}