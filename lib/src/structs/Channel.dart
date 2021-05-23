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
    
    /// The messages sent in this channel.
    late var messages = MessageManager(client: client, channel: this);
    
    /// The type of channel.
    /// Either `Group`, `DirectMessage` or `SavedMessages`.
    late String channel_type;
    
    /// Whether the channel is fully fetched.
    /// If false, only [id] is quaranteed to be present.
    bool partial = true;
    
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
            throw 'Failed to fetch channel $id: Expected type $channel_type, got ${fetched['channel_type']}';
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
        }
    }
}

class GroupChannel extends Channel {
    /// The ID of the channel's owner.
    String? ownerId;
    
    /// The owner of this channel.
    User? owner;
    
    // The channel's description.
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
    
    SavedMessagesChannel(Client client, { required id }) : super(client, id: id);
}
