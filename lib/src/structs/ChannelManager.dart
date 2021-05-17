part of dartvolt;

class Channel {
    Client client;
    late String _id;
    late String name;
    late Map<String, User>? members;
    late ChannelType channelType;
    bool partial = true;
    
    User? owner;
    
    /// If partial, fetch the channel.
    /// When [preferCached] is disabled,
    /// this will ignore the cached version.
    Future<Channel> fetch({ bool preferCached = true }) async {
        if (preferCached && !partial) {
            return this;
        }
        
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/channels/$_id'),
            headers: client._authHeaders
        );
        var c = jsonDecode(res.body);
        
        print(c);
        
        channelType =
            c['channel_type'] == 'Group' ? ChannelType.Group :
            c['channel_type'] == 'DirectMessage' ? ChannelType.DirectMessage :
            ChannelType.SavedMessages;
        name = c['name'];
        // owner = client.users.fetch(c['owner']);
        
        return this;
    }
    
    Channel(this.client, { id, name, channelType }) {
        this._id = id;
        this.name = name;
        this.channelType = channelType;
    }
}

enum ChannelType {
    Group,
    DirectMessage,
    SavedMessages,
}
