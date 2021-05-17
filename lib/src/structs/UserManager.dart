part of dartvolt;

class UserManager {
    Client client;
    var cache = <String, User>{};
    
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