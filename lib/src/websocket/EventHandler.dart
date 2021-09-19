part of dartvolt;

class EventHandler {
  Client client;
  WSClient wsClient;
  StreamController stream = StreamController.broadcast();

  EventHandler(this.client, this.wsClient);
}
