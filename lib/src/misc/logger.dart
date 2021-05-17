part of dartvolt;

/// Helper function(s) for logging
class Logger {
    late Client client;
    
    Logger(this.client);
    
    debug(dynamic message) {
        if (client.clientConfig.debug) {
            // ansi
            print('\u001b[0m\u001b[2m[Debug] \u001b[0m$message');
        }
    }
}
