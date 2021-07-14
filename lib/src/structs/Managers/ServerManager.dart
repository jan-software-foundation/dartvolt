part of dartvolt;

class ServerManager {
    Client client;
    
    Map<String, Server> cache = {};
    
    Future<Server> _storeAPIServer(Map<String, dynamic> APIServer) async {
        var channels = <Channel>[];
        (APIServer['channels'] as List<dynamic>).forEach((channelID) async {
            var channel = await client.channels.fetch(channelID);
            channels.add(channel);
        });
        
        var categories = <Category>[];
        ((APIServer['categories'] ?? <String>[]) as List<dynamic>).forEach((category) {
            var categoryChannels = <Channel>[];
            (category['channels'] as List<dynamic>).forEach((channelID) async {
                var channel = await client.channels.fetch(channelID);
                categoryChannels.add(channel);
            });
            
            categories.add(
                Category(client,
                    id: category['id'],
                    title: category['title'],
                    channels: categoryChannels
                )
            );
        });
        
        var roles = <Role>[];
        (APIServer['roles'] ?? <String, dynamic>{}).forEach((roleID, role) {
            roles.add(
                Role(client,
                    id: roleID,
                    name: role['name'],
                    color: role['colour'] ?? 'ffffff',
                    permissions: RolePermissions(
                        client,
                        serverPermissions: BasePermissions(
                            role['permissions'][0],
                            ServerPermissions
                        ),
                        channelPermissions: BasePermissions(
                            role['permissions'][1],
                            ChannelPermissions
                        )
                    )
                )
            );
        });
        
        var defaultPermissions = RolePermissions(client,
            channelPermissions: BasePermissions(
                APIServer['defaultPermissions']?[0] ?? 0,
                ChannelPermissions
            ),
            serverPermissions: BasePermissions(
                APIServer['defaultPermissions']?[1] ?? 0,
                ChannelPermissions
            )
        );
        
        var server = Server(client,
            id: APIServer['_id'],
            nonce: APIServer['nonce'] ?? '',
            owner: client.users._getOrCreateUser(APIServer['owner']),
            name: APIServer['name'],
            description: APIServer['description'],
            channels: channels,
            categories: categories,
            roles: roles,
            defaultPermissions: defaultPermissions,
            systemMessages: APIServer['system_messages']
        );
        
        cache[server.id] = server;
        return server;
    }
    
    Future<Server> _fetchServer(String id) async {
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/servers/$id'),
            headers: client._authHeaders
        );
        
        var fetched = jsonDecode(res.body);
        var server = await _storeAPIServer(fetched);
        return server;
    }
    
    /// Fetch a server. If [preferCache]
    /// is false, all cached versions
    /// will be ignored.
    Future<Server> fetch(String id, { preferCache = true }) async {
        if (cache.containsKey(id) && preferCache) {
            return cache[id] as Server;
        }
        return _fetchServer(id);
    }
    
    ServerManager(this.client);
}