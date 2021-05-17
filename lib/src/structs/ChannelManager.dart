part of dartvolt;

class ChannelManager {
    Client client;
    var cache = <String, Channel>{};
    
    /// Fetch a channel. If [preferCache]
    /// is false, any cached versions
    /// will be ignored.
    Future<Channel> fetch(String id, { preferCache = true }) async {
        if (cache.containsKey(id)) {
            var channel = cache[id] as Channel;
            if (channel.partial) {
                await channel.fetch(preferCached: preferCache);
            }
            return channel;
        } else {
            var channel = await _fetchChannel(id);
            cache[id] = channel;
            return channel;
        }
    }
    
    Future<Channel> _fetchChannel(String id) async {
        var channelType = await _fetchChannelType(id);
        
        switch(channelType) {
            case ChannelType.GroupChannel:
                var channel = GroupChannel(client, id: id);
                await channel.fetch(preferCached: false);
                return channel;
            case ChannelType.DMChannel:
                var channel = DMChannel(client, id: id);
                await channel.fetch(preferCached: false);
                return channel;
            case ChannelType.SavedMessagesChannel:
                var channel = SavedMessagesChannel(client, id: id);
                await channel.fetch(preferCached: false);
                return channel;
            default: throw 'Unknown channel type';
        }
    }
    
    Future<ChannelType> _fetchChannelType(String id) async {
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/channels/$id'),
            headers: client._authHeaders
        );
        var channelType = jsonDecode(res.body)['channel_type'];
        switch(channelType) {
            case 'Group':
                return ChannelType.GroupChannel;
            case 'DirectMessage':
                return ChannelType.DMChannel;
            case 'SavedMessages':
                return ChannelType.SavedMessagesChannel;
            default:
                throw 'Received invalid channel type. Expected one of either '
                'Group, DirectMessage, or SavedMessages; received $channelType';
        }
    }
    
    ChannelManager(this.client);
}

enum ChannelType {
    GroupChannel,
    DMChannel,
    SavedMessagesChannel,
}