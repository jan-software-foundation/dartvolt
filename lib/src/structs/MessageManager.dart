part of dartvolt;

class MessageManager {
    /// The Client this Message Manager belongs to.
    Client client;
    
    /// The Channel this Message Manager belongs to.
    Channel channel;
    
    var cache = <String, Message>{};
    
    Future<Message> fetch(String id, { bool preferCached = true }) async {
        if (preferCached && cache[id] != null) {
            return cache[id] as Message;
        }
        
        var res = await http.get(
            Uri.parse(
                client.clientConfig.apiUrl +
                '/channels/${channel.id}/messages/$id'
            ),
            headers: client._authHeaders
        );
        
        var msgData = jsonDecode(res.body);
        var attachment = msgData['attachment'];
        
        var msg = Message(
            client,
            id: id,
            author: await client.users.fetch(msgData['author']),
            channel: channel,
            nonce: msgData['nonce'],
            content: msgData['content'],
            attachment: attachment == null ? null : File(
                id: attachment['_id'],
                tag: attachment['tag'],
                filename: attachment['filename'],
                content_type: attachment['content_type'],
                filesize: attachment['size'],
                type: attachment['metadata']?['type'],
                height: attachment['metadata']?['height'],
                width: attachment['metadata']?['width']
            )
        );
        
        cache[id] = msg;
        return msg;
    }
    
    void _storeAPIMessage(Map<String, dynamic> message) {
        
    }
    
    MessageManager({ required this.client, required this.channel });
}

/// Used for the Revolt Client to associate
/// message IDs to their respective channel
class ClientMessageManager {
    /// The associated Revolt Client
    Client client;
    
    /// Maps Message IDs to Channels
    var msgChannelCache = <String, Channel>{};
    
    void _pushMessage(Message message) {
        msgChannelCache[message.id] = message.channel;
    }
    
    ClientMessageManager(this.client);
}
