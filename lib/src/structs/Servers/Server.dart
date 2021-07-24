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
    List<Channel> channels;
    
    /// The categories in this Server
    List<Category> categories;
    
    /// Array of the roles in this Server
    List<Role> roles;
    
    /// Default permissions object
    RolePermissions defaultPermissions;
    
    /// Don't know what this is for but the docs specify it
    /// https://developers.revolt.chat/api/#tag/Server-Information/paths/~1servers~1:server/get \
    /// Properties: `user joined`, `user left`, `user kicked`, `user banned`
    Map<String, dynamic> systemMessages;
    
    late var members = ServerMemberManager(client, server: this);
    
    /// Server icon
    File? icon;
    
    /// Server banner
    File? banner;
    
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
