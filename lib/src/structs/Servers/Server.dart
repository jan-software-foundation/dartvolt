part of dartvolt;

class Server {
    /// The Revolt Client that created this object
    Client client;
    
    /// The ID of this Server
    String id;
    
    /// The nonce of this Server
    String nonce;
    
    /// The Server's Owner
    User owner;
    
    /// The Server's name
    String name;
    
    /// The Server's description
    String? description;
    
    /// The Channels in this Server
    Map<String, Channel> channels;
    
    /// The categories in this Server
    Map<String, Category> categories;
    
    /// Array of the roles in this Server
    List<Role> roles;
    
    /// Default permissions object
    RolePermissions defaultPermissions;
    
    /// The channels system messages are sent to, or null if disabled.
    ServerSystemMessages systemMessages;
    
    late var members = ServerMemberManager(client, server: this);
    
    /// Server icon
    File? icon;
    
    /// Server banner
    File? banner;
    
    /// Fetches a member or gets it from cache
    Future<Member?> member(String id) async {
        return await members.fetch(id);
    }
    
    Server(this.client, {
        required this.id,
        required this.nonce,
        required this.owner,
        required this.name,
        required this.description,
        required this.channels,
        required this.categories,
        required this.roles,
        required this.defaultPermissions,
        required this.systemMessages,
        this.icon,
        this.banner
    });
}

class ServerSystemMessages {
    String? user_joined;
    String? user_left;
    String? user_kicked;
    String? user_banned;
    
    ServerSystemMessages({
        this.user_joined,
        this.user_left,
        this.user_kicked,
        this.user_banned,
    });
    
    ServerSystemMessages.fromJSON(Map<String, dynamic> json) {
        user_joined = json['user_joined'];
        user_left   = json['user_left'];
        user_kicked = json['user_kicked'];
        user_banned = json['user_banned'];
    }
}

class ServerUpdate {
    Server server;
    Map<String, dynamic> data;
    _ServerUpdateChanges changes;
    
    ServerUpdate({
        required this.server,
        required this.data,
        required this.changes
    });
}

class _ServerUpdateChanges {
    bool description;
    bool system_messages;
    bool icon;
    bool banner;
    _ServerUpdateChanges({
        this.banner = false,
        this.description = false,
        this.icon = false,
        this.system_messages = false,
    });
}
