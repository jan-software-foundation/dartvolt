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
                if (!(event['content'] is String)) {
                    // TODO handle system messages
                    revoltClient._logger.debug('Received system message; ignoring');
                    return;
                }
                
                var channel = await revoltClient.channels.fetch(event['channel']);
                var attachment = event['attachment'];
                var message = Message(
                    revoltClient,
                    id: event['_id'],
                    author: revoltClient.users._getOrCreateUser(event['_id']),
                    channel: channel,
                    nonce: event['nonce'] ?? '',
                    content: event['content'],
                    attachment: attachment != null ?
                        File.fromJSON(attachment) : null,
                );
                
                channel.messages.cache[message.id] = message;
                
                revoltClient.events.emit('message/create', null, message);
            break;
            
            case 'MessageUpdate':
                var channel = await revoltClient.channels.fetch(event['channel']);
                
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
            break;
            
            case 'MessageDelete':
                var channel = await revoltClient.channels.fetch(event['channel']);
                var msg = channel.messages.cache[event['id']];
                if (msg != null) {
                    msg.deleted = true;
                    revoltClient.events.emit(
                        'message/delete',
                        null,
                        msg
                    );
                }
            break;
            
            case 'ChannelUpdate':
                var channel = revoltClient.channels.cache[event['id']];
                
                var changes = ChannelUpdateChanges(
                    name: event['data']['name'] != null,
                    description: event['data']['description'] != null,
                    image: event['data']['icon'] != null
                );
                
                var update = ChannelUpdateEvent(
                    update: event['data'] ?? jsonDecode('{}'),
                    changes: changes,
                    channel: channel ?? await revoltClient.channels.fetch(event['id']),
                    oldValues: channel == null ? null : ChannelUpdateOldValues(
                        name: channel.name,
                        description: channel is GroupChannel ? channel.description : null,
                        icon: channel.icon
                    ),
                );
                
                if (channel != null) {
                    if (event['data']['name'] != null) {
                        channel.name = event['data']['name'];
                    }
                    if (event['data']['description'] != null && channel is GroupChannel) {
                        channel.description = event['data']['description'];
                    }
                    if (event['data']['icon'] != null) {
                        channel.icon = File.fromJSON(event['data']['icon']);
                    }
                } else {
                    channel = await revoltClient.channels.fetch(event['id']);
                }
                
                revoltClient.events.emit('channel/update', null, update);
            break;
        }
        
        revoltClient.events.emit('APIEvent/$evtType', null, event);
    }
    _RevoltEventHandler(revoltClient) {
        this.revoltClient = revoltClient;
    }
}