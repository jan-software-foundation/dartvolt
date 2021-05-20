part of dartvolt;

/// Helper function(s) for logging
class Logger {
    late Client client;
    
    Logger(this.client);
    
    void warn(dynamic message) {
        print('\u001b[0m\u001b[33;1m[Warn]  \u001b[0m$message');
    }
    
    void debug(dynamic message) {
        if (client.clientConfig.debug) {
            // ansi
            print('\u001b[0m\u001b[2m[Debug] \u001b[0m$message');
        }
    }
}
