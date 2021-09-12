part of dartvolt;

/// Internal logging functions
class _Logger {
  Client client;

  _Logger(this.client);

  void debug(String text) {
    if (client.config.debug) {
      print('\u001b[0m\u001b[2m[Debug] \u001b[0m$text');
    }
  }
}
