part of dartvolt;

class UserManager {
    Client client;
    var cache = <String, User>{};
    
    /// Parse a user object received from
    /// the API and store it to the cache.
    /// Returns the user.
    User _storeAPIUser(Map<String, dynamic> apiUser) {
        User user;
        if (cache[apiUser['_id']] == null) {
            user = User(
                client,
                id: apiUser['_id']
            );
        } else {
            user = cache[apiUser['_id']]!;
        }
        
        user.partial = false;
        user.name = apiUser['username'];
        user.friends = apiUser['username'] == 'Friend';
        
        UserPresence? presence;
        switch(apiUser['status']?['presence']) {
            case 'Online':
                presence = UserPresence.Online; break;
            case 'Idle':
                presence = UserPresence.Idle; break;
            case 'Busy':
                presence = UserPresence.Busy; break;
            case 'Offline':
                presence = UserPresence.Offline; break;
            default:
                presence = null;
        }
        user.status = UserStatus(
            presence: presence,
            text: apiUser['status']?['text'] // null if unknown
        );
        
        var avatar = apiUser['avatar'];
        
        user.avatar = avatar == null ? null : File.fromJSON(avatar);
        
        client.users.cache[user.id] = user;
        return user;
    }
    
    // Gets an user from the cache, or creates one if not present
    User _getOrCreateUser(String id) {
        if (cache[id] != null) {
            // ignore: unnecessary_cast
            return (cache as Map)[id];
        } else {
            var user = User(client, id: id);
            cache[id] = user;
            return user;
        }
    }
    
    /// Fetch an user. If [preferCache]
    /// is false, any cached versions
    /// will be ignored.
    Future<User> fetch(String id, { preferCache = true }) async {
        if (cache.containsKey(id)) {
            var user = cache[id] as User;
            if (user.partial) {
                await user.fetch(preferCache: preferCache);
            }
            return user;
        } else {
            var user = User(client, id: id);
            await user.fetch(preferCache: false);
            cache[id] = user;
            return user;
        }
    }
    
    UserManager(this.client);
}