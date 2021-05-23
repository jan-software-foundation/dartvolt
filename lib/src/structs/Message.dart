part of dartvolt;

class Message {
    /// The Client that created this message Object
    Client client;
    
    /// The Channel this message originated from
    Channel channel;
    
    /// The user who sent this message
    User author;
    
    /// A string unique to this message.
    /// Must be set by the client when sending.
    String nonce;
    
    /// The message's ID
    String id;
    
    /// Whether the message has been deleted
    bool deleted = false;
    
    /// The content of this message
    String? content;
    
    /// The file attached to this message
    File? attachment;
    
    Message(this.client, {
        required this.id,
        required this.author,
        required this.channel,
        required this.nonce,
        this.content,
        this.attachment,
    }) {
        client.messages.msgChannelCache[id] = channel;
    }
    
    /// Utility function to duplicate the message object
    Message.clone(Message message) : this(
        message.client,
        id: message.id,
        author: message.author,
        channel: message.channel,
        nonce: message.nonce,
        content: message.content,
        attachment: message.attachment
    );
}

/// Describes a message edit
class MessageEdit {
    /// Only available if old message was cached
    Message? oldMessage;
    
    Message newMessage;
    
    MessageEdit({ required this.oldMessage, required this.newMessage });
}

// TODO add system messages

/* class SystemMessage {} */