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
                var channel = await revoltClient.channels.fetch(event['channel']);
                var attachment = event['attachment'];
                var message = Message(
                    revoltClient,
                    id: event['_id'],
                    author: revoltClient.users._getOrCreateUser(event['_id']),
                    channel: channel,
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
                
                channel.messages.cache[message.id] = message;
                
                revoltClient.events.emit('message/create', null, message);
            break;
            
            case 'MessageUpdate':
                // TODO fix this clusterfuck when https://gitlab.insrt.uk/revolt/delta/-/issues/6 is fixed
                var channel = revoltClient.messages.msgChannelCache[event['id']];
                
                if (channel != null) {
                    var oldMsg = channel.messages.cache[event['id']];
                    Message newMsg;
                    if (oldMsg == null) {
                        newMsg = await channel.messages.fetch(event['id']);
                    } else {
                        newMsg = Message.clone(oldMsg);
                        newMsg.content = event['data']['content'];
                    }
                    
                    revoltClient.events.emit(
                        'message/update',
                        null,
                        MessageEdit(
                            oldMessage: oldMsg,
                            newMessage: newMsg
                        )
                    );
                    
                    // Update cached message object
                    channel.messages.cache[event['id']] = newMsg;
                }
            break;
            case 'MessageDelete':
                var channel = revoltClient.messages.msgChannelCache[event['id']];
                if (channel != null) {
                    var msg = channel.messages.cache[event['id']];
                    if (msg != null) {
                        msg.deleted = true;
                        revoltClient.events.emit(
                            'message/delete',
                            null,
                            msg
                        );
                    }
                }
            break;
        }
        
        revoltClient.events.emit('APIEvent/$evtType', null, event);
    }
    _RevoltEventHandler(revoltClient) {
        this.revoltClient = revoltClient;
    }
}