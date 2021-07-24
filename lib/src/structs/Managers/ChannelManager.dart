part of dartvolt;

class ChannelManager {
    Client client;
    var cache = <String, Channel>{};
    
    void _storeAPIChannel(Map<String, dynamic> apiChannel) {
        Channel channel;
        
        switch(apiChannel['channel_type']) {
            case 'Group':
                channel = GroupChannel(client, id: apiChannel['_id']);
            break;
            case 'DirectMessage':
                channel = DMChannel(client, id: apiChannel['_id']);
            break;
            case 'SavedMessages':
                channel = SavedMessagesChannel(client, id: apiChannel['_id']);
            break;
            case 'TextChannel':
                channel = TextChannel(client, id: apiChannel['_id']);
            break;
            case 'VoiceChannel':
                channel = VoiceChannel(client, id: apiChannel['_id']);
            break;
            default: throw 'Invalid channel';
        }
        
        channel.name = apiChannel['name'];
        if (channel is GroupChannel) {
            channel.owner = client.users.cache[apiChannel['owner']]
                ?? User(client, id: apiChannel['owner']);
            
            channel.description = apiChannel['description'];
        }
        
        channel.nonce = apiChannel['nonce'];
        
        channel.members ??= <String, User>{};
        
        channel.icon = apiChannel['icon'] == null ? null : File.fromJSON(apiChannel['icon']);
        
        if (channel is GroupChannel ||
            channel is DMChannel ||
            channel is SavedMessagesChannel
        ) {
            (apiChannel['recipients'] as List<dynamic>).forEach((uid) {
                if (uid != null) {
                    (channel.members as Map<String, User>)[uid] =
                        client.users.cache[uid] ?? User(client, id: uid);
                }
            });
        }
        
        client.channels.cache[channel.id] = channel;
    }
    
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
            case ChannelType.TextChannel:
                var channel = TextChannel(client, id: id);
                await channel.fetch(preferCached: false);
                return channel;
            case ChannelType.VoiceChannel:
                var channel = VoiceChannel(client, id: id);
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
            case 'TextChannel':
                return ChannelType.TextChannel;
            case 'VoiceChannel':
                return ChannelType.VoiceChannel;
            default:
                throw 'Received invalid channel type. Expected one of either '
                'Group, DirectMessage, SavedMessages, TextChannel '
                'or VoiceChannel; received $channelType'
                '\nChannel object: ${jsonDecode(res.body)}';
        }
    }
    
    ChannelManager(this.client);
}

enum ChannelType {
    GroupChannel,
    DMChannel,
    SavedMessagesChannel,
    TextChannel,
    VoiceChannel
}