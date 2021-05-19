part of dartvolt;

/// Stores data about an existing session:
/// [clientId] - The ID of the user the
/// session belongs to.
/// [sessionId] and [sessionToken] - ID
/// and secret of the session
class SessionInfo {
    late String sessionId;
    late String sessionToken;
    late String clientId;
    
    SessionInfo({ sessionId, sessionToken, clientId }) {
        this.sessionId = sessionId;
        this.sessionToken = sessionToken;
        this.clientId = clientId;
    }
}

/// Authentication info for creating a new
/// session.
class AuthInfo {
    String email;
    String password;
    String? device_name;
    String? captcha;
    
    AuthInfo({
        required this.email,
        required this.password,
        this.device_name,
        this.captcha
    });
}
