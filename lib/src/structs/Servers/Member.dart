part of dartvolt;

class Member {
    Client client;
    
    late User user;
    
    /// The server this member is from
    late Server server;
    
    /// User ID
    late String id = user.id;
    
    /// Present if the user has a nickname in this server
    String? nickname;
    
    /// Present if the user has an avatar override for this server
    File? avatar;
    
    /// Array of the roles this user has
    late List<Role> roles; // Need a proper role manager later
    
    Member(this.client, {
        required this.user,
        required this.roles,
        required this.server,
        this.nickname,
        this.avatar
    });
    
    Member.fromJSON(this.client, Map<String, dynamic> data) {
        user = client.users._getOrCreateUser(data['_id']['user']);
        server = client.servers.cache[data['_id']['server']]!;
        nickname = data['nickname'];
        avatar = data['avatar'] != null ? File.fromJSON(data['avatar']) : null;
        roles = <Role>[];
        
        if (data['roles'] == null) data['roles'] = <dynamic>[];
        (data['roles'] as List<dynamic>).forEach((roleID) {
            roles.add(server.roles[roleID]);
        });
    }
}