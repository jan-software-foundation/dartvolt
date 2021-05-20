part of dartvolt;

class _RevoltEventHandler {
    late Client revoltClient;
    
    dynamic _handleWSEvent(Map<String, dynamic> event) async {
        String evtType = event['type'];
        switch(evtType) {
            case 'Ready':
                // Store all users and channels
                // received in the initial Ready event
                var users    = event['users'];
                var channels = event['channels'];
                
                users.forEach((user) {
                    try {
                        revoltClient.users._storeAPIUser(user);
                    } catch(e) {
                        revoltClient._logger.warn('Failed to store user: $e');
                    }
                });
                
                channels.forEach((channel) {
                    try {
                        revoltClient.channels._storeAPIChannel(channel);
                    } catch(e) {
                        revoltClient._logger.warn('Failed to store channel: $e');
                    }
                });
                
                revoltClient.user = revoltClient
                    .users
                    .cache[revoltClient.sessionInfo.clientId] ??
                    User(revoltClient, id: revoltClient.sessionInfo.clientId);
                
                await revoltClient.user.fetch();
                
                revoltClient.events.emit('ready', null, revoltClient);
            break;
            
            case 'Message':
                var attachment = event['attachment'];
                var message = Message(
                    revoltClient,
                    id: event['_id'],
                    author: revoltClient.users._getOrCreateUser(event['_id']),
                    channel: await revoltClient.channels.fetch(event['channel']),
                    nonce: event['nonce'],
                    content: event['content'],
                    attachment: attachment != null ?
                        File(
                            id: attachment['_id'],
                            content_type: attachment['content_type'],
                            filename: attachment['filename'],
                            tag: attachment['tag'],
                            filesize: attachment['size'],
                            type: attachment['metatata']?['type'],
                            height: attachment['metatata']?['height'],
                            width: attachment['metatata']?['width'],
                        ) : null,
                );
                
                revoltClient.events.emit('message/create', null, message);
            break;
            
            case 'MessageUpdate':
                // TODO add message/update event
                // need a message cache for this
                // {"type":"MessageUpdate","id":"ASDDUGTDKKJ","data":{"content":"UKZGDZH","edited":{"$date":"2021-05-20T14:59:38.852Z"}}}
            break;
        }
        
        revoltClient.events.emit('APIEvent/$evtType', null, event);
    }
    _RevoltEventHandler(revoltClient) {
        this.revoltClient = revoltClient;
    }
}