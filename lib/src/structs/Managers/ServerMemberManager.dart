part of dartvolt;

class ServerMemberManager {
    /// The client that created this object
    Client client;
    
    /// The server this object belongs to
    Server server;
    
    /// Member cache. Might not be complete,
    /// make sure to call fetchAll() first
    var cache = <String, Member>{};
    
    /// Fetches all members in this server.
    /// Returns the member cache
    Future<Map<String, Member>> fetchAll() async {
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/servers/${server.id}/members'),
            headers: client._authHeaders
        );
        var body = jsonDecode(res.body);
        
        // Store user objects first
        (body['users'] as List<dynamic>).forEach((userObj) {
            try {
                client.users._storeAPIUser(userObj);
            } catch(e) {
                client._logger.warn(
                    'Failed to store user from server member list: $e'
                );
            }
        });
        
        (body['members'] as List<dynamic>).forEach((memberObj) {
            cache[memberObj['_id']['user']] = Member.fromJSON(client, memberObj);
        });
        
        return cache;
    }
    
    ServerMemberManager(this.client, { required this.server });
}