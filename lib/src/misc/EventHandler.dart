part of dartvolt;

class _RevoltEventHandler {
    late Client revoltClient;
    
    dynamic _handleWSEvent(Map<String, dynamic> event) async {
        String evtType = event['type'];
        switch(evtType) {
            case 'Authenticated':
                revoltClient.wsClient.connected = true;
                revoltClient.events.emit('authenticated', null, null);
            break;
            case 'Ready':
                // Store all users and channels
                // received in the initial Ready event
                List<dynamic> users    = event['users'];
                List<dynamic> channels = event['channels'];
                List<dynamic> servers  = event['servers'];
                
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
                
                servers.forEach((server) {
                    try {
                        revoltClient.servers._storeAPIServer(server);
                    } catch(e) {
                        revoltClient._logger.warn('Failed to store server: $e');
                    }
                });
                
                revoltClient.user = revoltClient
                    .users
                    .cache[revoltClient.sessionInfo.clientId] ??
                    User(revoltClient, id: revoltClient.sessionInfo.clientId);
                
                await revoltClient.user.fetch();
                
                revoltClient.wsClient.ready = true;
                
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
                try {
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
                } catch(e) {
                    revoltClient._logger.debug(e);
                }
            break;
            
            case 'MessageDelete':
                try {
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
                } catch(e) {
                    revoltClient._logger.debug(e);
                }
            break;
            
            case 'ChannelGroupJoin':
                if (event['user'] == revoltClient.user.id) {
                    // channel/join event
                    
                    var channel = await revoltClient.channels.fetch(event['id']);
                    
                    revoltClient.events.emit('channel/join', null, channel);
                } else {
                    // channel/userAdded event
                    
                    var channel = await revoltClient.channels.fetch(event['id']);
                    var user = await revoltClient.users.fetch(event['user']);
                    
                    if (channel.partial) await channel.fetch();
                    
                    if (channel.members?[event['user']] == null) {
                        channel.members?[event['user']] = user;
                    }
                    
                    revoltClient.events.emit(
                        'channel/userAdded',
                        null,
                        ChannelMemberAddEvent(channel: channel, user: user)
                    );
                }
            break;
            
            case 'ChannelGroupLeave':
                if (event['user'] == revoltClient.user.id) {
                    // channel/leave event
                    
                    if (revoltClient.channels.cache[event['id']] != null) {
                        revoltClient.channels.cache.remove(event['id']);
                    }
                    
                    revoltClient.events.emit(
                        'channel/leave',
                        null,
                        event['id']
                    );
                } else {
                    // channel/userLeave event
                    
                    var channel = await revoltClient.channels.fetch(event['id']);
                    var user = revoltClient.users.cache[event['user']] ?? User(
                        revoltClient,
                        id: event['user']
                    );
                    
                    if (channel.members?[event['id']] != null) {
                        channel.members?.remove(event['id']);
                    }
                    
                    revoltClient.events.emit(
                        'channel/userLeave',
                        null,
                        ChannelMemberLeaveEvent(
                            channel: channel,
                            user: user
                        )
                    );
                }
            break;
            
            case 'ChannelCreate':
                var channel = await revoltClient.channels.fetch(event['_id']);
                if (event['channel_type'] == 'TextChannel' ||
                    event['channel_type'] == 'VoiceChannel'
                ) {
                    var server = await revoltClient.servers.fetch(event['server']);
                    server.channels[channel.id] = channel;
                }
                
                revoltClient.events.emit('channel/create', null, channel);
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
                        description: channel.description,
                        icon: channel.icon
                    ),
                );
                
                if (channel != null) {
                    if (event['data']['name'] != null) {
                        channel.name = event['data']['name'];
                    }
                    if (event['data']['description'] != null && (
                        channel is GroupChannel ||
                        channel is TextChannel ||
                        channel is VoiceChannel
                    )) {
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
            
            case 'ChannelDelete':
                String id = event['id'];
                var channel = revoltClient.channels.cache[id];
                if (channel != null) {
                    if (channel is ServerBaseChannel) {
                        var server = channel.server;
                        if (server?.channels[channel.id] != null) {
                            server?.channels.remove(channel.id);
                        }
                    }
                    revoltClient.channels.cache.remove(id);
                    channel.deleted = true;
                } else {
                    channel = DummyChannel(revoltClient, id: id);
                    channel.deleted = true;
                }
                
                // ignore: unnecessary_cast
                revoltClient.events.emit('channel/delete', null, channel as Channel);
            break;
            
            case 'ServerMemberJoin':
                var server = await revoltClient.servers.fetch(event['id']);
                if (event['user'] == revoltClient.user.name) {
                    // Client was added to a new server
                    revoltClient.events.emit('server/join', null, server);
                } else {
                    var member = await server.members.fetch(event['user']);
                    revoltClient.events.emit('server/memberJoin', null, member);
                }
            break;
            
            case 'ServerMemberLeave':
                if (event['user'] == revoltClient.user) {
                    // Client left a server (or was kicked/banned)
                    if (revoltClient.servers.cache[event['id']] != null) {
                        revoltClient.servers.cache.remove(event['id']);
                    }
                    revoltClient.events.emit('server/leave', null, event['id']);
                } else {
                    var server = await revoltClient.servers.fetch(event['id']);
                    server.members.cache.remove(event['user']);
                    revoltClient.events.emit('server/memberLeave', null, event['user']);
                }
            break;
            
            case 'ServerUpdate':
                print(jsonEncode(event));
                var server = await revoltClient.servers.fetch(event['id']);
                var changes = _ServerUpdateChanges();
                
                if (event['clear'] != null) {
                    switch(event['clear']) {
                        case 'Icon':
                            server.icon = null;
                            changes.icon = true; break;
                        case 'Banner':
                            server.banner = null;
                            changes.banner = true; break;
                        case 'Description':
                            server.description = null;
                            changes.description = true; break;
                    }
                }
                
                if (event['data'] != null) {
                    var data = event['data'];
                    
                    if (data['description'] != null) {
                        server.description = data['description'];
                        changes.description = true;
                    }
                    
                    if (data['system_messages'] != null) {
                        server.systemMessages = ServerSystemMessages.fromJSON(
                            data['system_messages']
                        );
                        changes.system_messages = true;
                    }
                    
                    if (data['icon'] != null) {
                        server.icon = File.fromJSON(data['icon']);
                        changes.icon = true;
                    }
                    
                    if (data['banner'] != null) {
                        server.banner = File.fromJSON(data['banner']);
                        changes.banner = true;
                    }
                }
                
                revoltClient.events.emit('server/update', null, ServerUpdate(
                    server: server,
                    data: event['data'],
                    changes: changes
                ));
            break;
            
            case 'UserUpdate':
                User user;
                if (revoltClient.users.cache[event['id']] == null) {
                    user = await revoltClient.users.fetch(event['id']);
                } else {
                    user = revoltClient.users.cache[event['id']] as User;
                    
                    var data = event['data'];
                    if (data['username'] != null) {
                        user.name = data['username'];
                    }
                    if (data['avatar'] != null) {
                        user.avatar = File.fromJSON(data['avatar']);
                    }
                    if (data['status']?['text'] != null) {
                        user.status?.text = data['status']?['text'];
                    }
                    if (data['status']?['presence'] != null) {
                        switch(data['status']?['presence']) {
                            case 'Online':
                                user.status?.presence = UserPresence.Online;
                            break;
                            case 'Idle':
                                user.status?.presence = UserPresence.Idle;
                            break;
                            case 'Busy':
                                user.status?.presence = UserPresence.Busy;
                            break;
                            case 'Invisible':
                                user.status?.presence = UserPresence.Offline;
                            break;
                            default:
                                user.status?.presence = null;
                        }
                    }
                    if (data['online'] != null) {
                        user.online = data['online'];
                    }
                }
                
                revoltClient.events.emit(
                    'user/update',
                    null,
                    UserUpdate(user: user, data: event['data'])
                );
            break;
            
            // Deprecated afaik
            case 'UserPresence':
                var user = await revoltClient.users.fetch(event['id']);
                user.online = event['online'];
            break;
        }
        
        revoltClient.events.emit('APIEvent/$evtType', null, event);
    }
    _RevoltEventHandler(revoltClient) {
        this.revoltClient = revoltClient;
    }
}

class ChannelMemberAddEvent {
    Channel channel;
    User user;
    ChannelMemberAddEvent({ required this.channel, required this.user });
}

class ChannelMemberLeaveEvent {
    Channel channel;
    User user;
    ChannelMemberLeaveEvent({ required this.channel, required this.user });
}