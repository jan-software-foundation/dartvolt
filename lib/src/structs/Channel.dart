part of dartvolt;

abstract class Channel {
    
    /// The Client that created this channel.
    Client client;
    
    /// The channel's ID.
    String id;
    
    /// The display name of the channel.
    String? name;
    
    /// I have no idea what this is used for.
    String? nonce;
    
    /// All participants in this channel.
    Map<String, User>? members;
    
    /// The channel's icon, null if undefined
    File? icon;
    
    /// The messages sent in this channel.
    late var messages = MessageManager(client: client, channel: this);
    
    /// The type of channel.
    /// Either `Group`, `DirectMessage` or `SavedMessages`.
    late String channel_type;
    
    /// The channel description. Only present
    /// on TextChannel, VoiceChannel or GroupChannel.
    String? description;
    
    /// Whether the channel is fully fetched.
    /// If false, only [id] is quaranteed to be present.
    bool partial = true;
    
    /// If the channel has been deleted
    bool deleted = false;
    
    /// Takes the values fetched by [_fetchSelf()]
    /// and assigns them to itself
    void _fetchAssignProps(Map<String, dynamic> props);
    
    /// Fetch the channel. Disable [preferCached]
    /// to force an API request, even if the
    /// channel is already cached.
    Future<Channel> fetch({ bool preferCached = true }) async {
        if (preferCached && !partial) {
            return this;
        }
        var fetched = await _fetchSelf();
        
        if (fetched['channel_type'] != channel_type) {
            throw 'Failed to fetch channel $id: Expected type '
            '$channel_type, got ${fetched['channel_type']}';
        }
        
        _fetchAssignProps(fetched);
        return this;
    }
    
    Future<Map<String, dynamic>> _fetchSelf() async {
        var fetched = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/channels/$id'),
            headers: client._authHeaders
        );
        return jsonDecode(fetched.body);
    }
    
    Future<void> send(message) async {
        var res = await http.post(
            Uri.parse(client.clientConfig.apiUrl + '/channels/$id/messages'),
            headers: client._authHeaders,
            body: jsonEncode({
                'nonce': DateTime.now().millisecondsSinceEpoch.toString(),
                'content': message
            })
        );
        if (res.statusCode != 200) throw res.body;
        return null;
    }
    
    Channel(this.client, { required this.id }) {
        if (this is GroupChannel) {
            channel_type = 'Group';
        } else if (this is DMChannel) {
            channel_type = 'DirectMessage';
        } else if (this is SavedMessagesChannel) {
            channel_type = 'SavedMessages';
        } else if (this is TextChannel) {
            channel_type = 'TextChannel';
        } else if (this is VoiceChannel) {
            channel_type = 'VoiceChannel';
        }
    }
}

class DummyChannel extends Channel {
    @override
    void _fetchAssignProps(Map<String, dynamic> props) {
        throw '_fetchAssignProps() was called on a DummyChannel';
    }
    
    DummyChannel(Client client, { required id }) : super(client, id: id);
}

class GroupChannel extends Channel {
    /// The ID of the channel's owner.
    String? ownerId;
    
    /// The owner of this channel.
    User? owner;
    
    // The channel's description.
    @override
    String? description;
    
    @override
    Future<Channel> _fetchAssignProps(Map<String, dynamic> props) async {
        name = props['name'];
        id = props['_id'];
        description = props['description'];
        // owner = client.users.fetch(c['owner']);
        
        return this;
    }
    
    GroupChannel(Client client, { required id }) : super(client, id: id);
}

class DMChannel extends Channel {
    @override
    Future<Channel> _fetchAssignProps(Map<String, dynamic> props) async {
        name = props['name'];
        id = props['_id'];
        // owner = client.users.fetch(c['owner']);
        
        return this;
    }
    
    DMChannel(Client client, { required id }) : super(client, id: id);
}

class SavedMessagesChannel extends Channel {
    @override
    Future<Channel> _fetchAssignProps(Map<String, dynamic> props) async {
        name = props['name'];
        id = props['_id'];
        // owner = client.users.fetch(c['owner']);
        
        return this;
    }
    
    SavedMessagesChannel(Client client, {required id}) : super(client, id: id);
}

abstract class ServerBaseChannel extends Channel {
    /// The server this channel belongs to
    Server? server;
    
    /// The default permissions on this channel
    RolePermissions? defaultPermissions;
    
    ServerBaseChannel(Client client, { required id }) : super(client, id: id);
}

class TextChannel extends ServerBaseChannel {
    // TODO Add ChannelPermissions Manager
    
    @override
    Future<Channel> _fetchAssignProps(Map<String, dynamic> props) async {
        name = props['name'];
        id = props['_id'];
        server = await client.servers.fetch(props['server']);
        icon = props['icon'] != null ? File.fromJSON(props['icon']) : null;
        description = props['description'];
        
        return this;
    }
    
    TextChannel(Client client, { required id }) : super(client, id: id);
}

class VoiceChannel extends ServerBaseChannel {    
    // TODO Add ChannelPermissions Manager
    
    @override
    Future<Channel> _fetchAssignProps(Map<String, dynamic> props) async {
        name = props['name'];
        id = props['_id'];
        server = await client.servers.fetch(props['server']);
        icon = props['icon'] != null ? File.fromJSON(props['icon']) : null;
        description = props['description'];
        //members = server.users;
        
        return this;
    }
    
    // I don't know if it's possible to remove
    // inherited functions but this works too
    @override
    Future<void> send(message) async {
        client._logger.warn(
            'send() has been invoked on a voice channel Object.'
        );
    }
    
    VoiceChannel(Client client, { required id }) : super(client, id: id);
}

class ChannelUpdateEvent {
    /// The new channel object.
    Channel channel;
    
    /// Array of changed attributes.
    /// Null if channel was not already cached.
    ChannelUpdateChanges? changes;
    
    /// The update event, as returned by the API.
    /// Probably has a `description`, `name` and/or `icon` property.
    Map<String, dynamic> update;
    
    ChannelUpdateOldValues? oldValues;
    
    ChannelUpdateEvent({
        required this.channel,
        this.changes,
        required this.update,
        this.oldValues,
    });
}

/// Describes which properties were changed in a [ChannelUpdateEvent].
class ChannelUpdateChanges {
    bool name;
    bool description;
    bool image;
    
    ChannelUpdateChanges({
        this.name = false,
        this.description = false,
        this.image = false,
    });
}

class ChannelUpdateOldValues {
    String? name;
    String? description;
    File? icon;
    
    ChannelUpdateOldValues({
        this.name,
        this.description,
        this.icon,
    });
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
