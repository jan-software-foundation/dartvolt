part of dartvolt;

class ServerConfig {
    String version;
    bool registrationEnabled;
    bool emailEnabled;
    bool inviteOnly;
    String? captcha;
    String wsURL;
    String appURL;
    String vapid;
    
    _Autumn? autumn;
    _Voso? voso;
    _January? january;
    
    /// Create server config
    ServerConfig({
        this.version = '0',
        this.registrationEnabled = false,
        this.emailEnabled = false,
        this.inviteOnly = false,
        this.captcha,
        this.wsURL = 'http://localhost',
        this.appURL = 'http://localhost',
        this.vapid = '',
        autumnURL,
        januaryURL,
        vosoURL,
        vosoWS
    }) {
        autumn = _Autumn(url: autumnURL);
        january = _January(url: januaryURL);
        voso = _Voso(url: vosoURL, wsUrl: vosoWS);
    }
}

class _Autumn {
    String url;
    _Autumn({ this.url = 'http://localhost' });
}

class _Voso {
    String url;
    String wsUrl;
    _Voso({ this.url = 'http://localhost', this.wsUrl = 'http://localhost' });
}

class _January {
    String url;
    _January({ this.url = 'http://localhost' });
}