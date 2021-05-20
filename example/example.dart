import 'package:dartvolt/dartvolt.dart' as dartvolt;

void main() {
    var client = dartvolt.Client(dartvolt.ClientConfig(
        apiUrl: 'https://api.revolt.chat',
        debug: true
    ));

    // Use existing session credentials.
    // You can use client.login() in the
    // future to create a new session, but
    // this isn't properly implemented right now. 
    client.useExistingSession(dartvolt.SessionInfo(
        clientId: 'My very epic 26 letter User ID',
        sessionId: 'My equally epic 26 letter Session ID',
        sessionToken: 'My super epic 64 letter Session Secret'
    ));

    // Listen for the ready event.
    // Will probably change in the future.
    client.events.on('ready', null, (ev, context) {
        print('My super epic client logged in!');
    });

    // Reply to messages starting with `!test`
    client.events.on('message/create', null, (evt, context) {
        var message = (evt.eventData as dartvolt.Message);
        
        if ((message.content ?? '').startsWith('!test')) {
            message.channel.send('Dartvolt is yes!');
        }
    });
}
