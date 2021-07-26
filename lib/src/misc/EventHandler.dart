part of dartvolt;

class _RevoltEventHandler {
    late Client client;
    
    dynamic _handleWSEvent(Map<String, dynamic> event) async {
        String evtType = event['type'];
        switch(evtType) {
            case 'Authenticated':
                client.wsClient.connected = true;
                client.events.emit('authenticated', null, null);
            break;
            case 'Ready':
                // Store all users and channels
                // received in the initial Ready event
                List<dynamic> users    = event['users'];
                List<dynamic> channels = event['channels'];
                List<dynamic> servers  = event['servers'];
                
                users.forEach((user) {
                    try {
                        client.users._storeAPIUser(user);
                    } catch(e) {
                        client._logger.warn('Failed to store user: $e');
                    }
                });
                
                channels.forEach((channel) {
                    try {
                        client.channels._storeAPIChannel(channel);
                    } catch(e) {
                        client._logger.warn('Failed to store channel: $e');
                    }
                });
                
                servers.forEach((server) {
                    try {
                        client.servers._storeAPIServer(server);
                    } catch(e) {
                        client._logger.warn('Failed to store server: $e');
                    }
                });
                
                client.user = client
                    .users
                    .cache[client.sessionInfo.clientId] ??
                    User(client, id: client.sessionInfo.clientId);
                
                await client.user.fetch();
                
                client.wsClient.ready = true;
                
                client.events.emit('ready', null, client);
            break;
            
            case 'Message':
                if (!(event['content'] is String)) {
                    // TODO handle system messages
                    client._logger.debug('Received system message; ignoring');
                    return;
                }
                
                var channel = await client.channels.fetch(event['channel']);
                var attachment = event['attachment'];
                var message = Message(
                    client,
                    id: event['_id'],
                    author: client.users._getOrCreateUser(event['_id']),
                    channel: channel,
                    nonce: event['nonce'] ?? '',
                    content: event['content'],
                    attachment: attachment != null ?
                        File.fromJSON(attachment) : null,
                );
                
                channel.messages.cache[message.id] = message;
                
                client.events.emit('message/create', null, message);
            break;
            
            case 'MessageUpdate':
                try {
                    var channel = await client.channels.fetch(event['channel']);

                    var oldMsg = channel.messages.cache[event['id']];
                    Message newMsg;
                    if (oldMsg == null) {
                        newMsg = await channel.messages.fetch(event['id']);
                    } else {
                        newMsg = Message.clone(oldMsg);
                        newMsg.content = event['data']['content'];
                    }

                    client.events.emit(
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
                    client._logger.debug(e);
                }
            break;
            
            case 'MessageDelete':
                try {
                    var channel = await client.channels.fetch(event['channel']);
                    var msg = channel.messages.cache[event['id']];
                    if (msg != null) {
                        msg.deleted = true;
                        client.events.emit(
                            'message/delete',
                            null,
                            msg
                        );
                    }
                } catch(e) {
                    client._logger.debug(e);
                }
            break;
            
            case 'ChannelGroupJoin':
                if (event['user'] == client.user.id) {
                    // channel/join event
                    
                    var channel = await client.channels.fetch(event['id']);
                    
                    client.events.emit('channel/join', null, channel);
                } else {
                    // channel/userAdded event
                    
                    var channel = await client.channels.fetch(event['id']);
                    var user = await client.users.fetch(event['user']);
                    
                    if (channel.partial) await channel.fetch();
                    
                    if (channel.members?[event['user']] == null) {
                        channel.members?[event['user']] = user;
                    }
                    
                    client.events.emit(
                        'channel/userAdded',
                        null,
                        ChannelMemberAddEvent(channel: channel, user: user)
                    );
                }
            break;
            
            case 'ChannelGroupLeave':
                if (event['user'] == client.user.id) {
                    // channel/leave event
                    
                    if (client.channels.cache[event['id']] != null) {
                        client.channels.cache.remove(event['id']);
                    }
                    
                    client.events.emit(
                        'channel/leave',
                        null,
                        event['id']
                    );
                } else {
                    // channel/userLeave event
                    
                    var channel = await client.channels.fetch(event['id']);
                    var user = client.users.cache[event['user']] ?? User(
                        client,
                        id: event['user']
                    );
                    
                    if (channel.members?[event['id']] != null) {
                        channel.members?.remove(event['id']);
                    }
                    
                    client.events.emit(
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
                var channel = await client.channels.fetch(event['_id']);
                if (event['channel_type'] == 'TextChannel' ||
                    event['channel_type'] == 'VoiceChannel'
                ) {
                    var server = await client.servers.fetch(event['server']);
                    server.channels[channel.id] = channel;
                }
                
                client.events.emit('channel/create', null, channel);
            break;
            
            case 'ChannelUpdate':
                var channel = client.channels.cache[event['id']];
                
                var changes = ChannelUpdateChanges(
                    name: event['data']['name'] != null,
                    description: event['data']['description'] != null,
                    image: event['data']['icon'] != null
                );
                
                var update = ChannelUpdateEvent(
                    update: event['data'] ?? jsonDecode('{}'),
                    changes: changes,
                    channel: channel ?? await client.channels.fetch(event['id']),
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
                    channel = await client.channels.fetch(event['id']);
                }
                
                client.events.emit('channel/update', null, update);
            break;
            
            case 'ChannelDelete':
                String id = event['id'];
                var channel = client.channels.cache[id];
                if (channel != null) {
                    if (channel is ServerBaseChannel) {
                        var server = channel.server;
                        if (server?.channels[channel.id] != null) {
                            server?.channels.remove(channel.id);
                        }
                    }
                    client.channels.cache.remove(id);
                    channel.deleted = true;
                } else {
                    channel = DummyChannel(client, id: id);
                    channel.deleted = true;
                }
                
                // ignore: unnecessary_cast
                client.events.emit('channel/delete', null, channel as Channel);
            break;
            
            case 'ServerMemberJoin':
                var server = await client.servers.fetch(event['id']);
                if (event['user'] == client.user.name) {
                    // Client was added to a new server
                    client.events.emit('server/join', null, server);
                } else {
                    var member = await server.members.fetch(event['user']);
                    client.events.emit('server/memberJoin', null, member);
                }
            break;
            
            case 'ServerMemberUpdate':
                var server = await client.servers.fetch(event['id']['server']);
                var member = await server.member(event['id']['user']);
                
                if (event['clear'] != null) {
                    switch(event['clear']) {
                        case 'Avatar': member?.avatar = null; break;
                        case 'Nickname': member?.nickname = null; break;
                    }
                }
                
                var data = event['data'];
                if (data['nickname'] != null) {
                    member?.nickname = data['nickname'];
                }
                if (data['avatar'] != null) {
                    member?.avatar = File.fromJSON(data['avatar']);
                }
                
                if (data['roles'] != null) {
                    member?.roles.clear();
                    (data['roles'] as List<dynamic>).forEach((roleID) {
                        member?.roles.add(
                            server.roles.firstWhere((r) => r.id == roleID)
                        );
                    });
                }
                
                // TODO Return a MemberUpdate instead of the new member
                client.events.emit('server/memberUpdate', null, member);
            break;
            
            case 'ServerMemberLeave':
                if (event['user'] == client.user) {
                    // Client left a server (or was kicked/banned)
                    if (client.servers.cache[event['id']] != null) {
                        client.servers.cache.remove(event['id']);
                    }
                    client.events.emit('server/leave', null, event['id']);
                } else {
                    var server = await client.servers.fetch(event['id']);
                    server.members.cache.remove(event['user']);
                    client.events.emit('server/memberLeave', null, event['user']);
                }
            break;
            
            case 'ServerUpdate':
                print(jsonEncode(event));
                var server = await client.servers.fetch(event['id']);
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
                
                client.events.emit('server/update', null, ServerUpdate(
                    server: server,
                    data: event['data'],
                    changes: changes
                ));
            break;
            
            case 'ServerDelete':
                client.servers.cache.remove(event['id']);
                client.events.emit('server/delete', null, event['id']);
            break;
            
            case 'ServerRoleUpdate':
                var data = event['data'] ?? <dynamic>{};
                var server = await client.servers.fetch(event['id']);
                var roleID = event['role_id'];
                Role role;
                if (server.roles.indexWhere((role) => role.id == roleID) == -1) {
                    role = Role(
                        client,
                        id: roleID,
                        name: event['data']['name'],
                        permissions: RolePermissions(
                            client,
                            serverPermissions: BasePermissions(
                                event['data']['permissions'][0],
                                ServerPermissions
                            ),
                            channelPermissions: BasePermissions(
                                event['data']['permissions'][1],
                                ChannelPermissions
                            )
                        ),
                        color: event['data']['colour']
                    );
                    
                    client.events.emit('server/roleCreate', null, role);
                } else {
                    role = server.roles.firstWhere((role) => role.id == roleID);
                    
                    if (data['name'] != null) {
                        role.name = data['name'];
                    }
                    if (data['colour'] != null) {
                        role.color = data['colour'];
                    }
                    if (data['permissions'] != null) {
                        var perms = data['permissions'];
                        role.permissions.serverPermissions = perms[0];
                        role.permissions.channelPermissions = perms[1];
                    }
                    
                    // TODO return RoleUpdate instead of the role itself
                    client.events.emit('server/roleUpdate', null, role);
                }
            break;
            
            case 'UserUpdate':
                User user;
                if (client.users.cache[event['id']] == null) {
                    user = await client.users.fetch(event['id']);
                } else {
                    user = client.users.cache[event['id']] as User;
                    
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
                
                client.events.emit(
                    'user/update',
                    null,
                    UserUpdate(user: user, data: event['data'])
                );
            break;
            
            // Deprecated afaik
            case 'UserPresence':
                var user = await client.users.fetch(event['id']);
                user.online = event['online'];
            break;
        }
        
        client.events.emit('APIEvent/$evtType', null, event);
    }
    _RevoltEventHandler(revoltClient) {
        client = revoltClient;
    }
}
