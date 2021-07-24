part of dartvolt;

class User {
    /// The client that created this user.
    Client client;
    
    /// The user's user ID.
    late String id;
    
    /// The user's username.
    String? name;
    
    /// Whether you are friends with this user.
    bool? friends;
    
    /// Whether you blocked the user from interacting with you.
    bool? blocked;
    
    /// Your relationship with this user, Friends, Blocked or None.
    /// Defaults to None.
    late UserRelationship relationship = UserRelationship.None;
    
    /// Whether the user is online.
    /// Will default to false if online status is unknown.
    late bool online = false;
    
    /// The user's status. Includes their presence and text status.
    UserStatus? status;
    
    /// The user's avatar, or null if not present.
    File? avatar;
    
    /// Whether the user is fully fetched.
    /// If false, only [id] is guaranteed to be present.
    bool partial = true;
    
    /// If the user is partial, this will fetch the full user.
    /// Pass `preferCache: false` to force re-fetching the user.
    Future<User> fetch({ preferCache = true }) async {
        if (!partial && preferCache) {
            return this;
        }
        
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/users/$id'),
            headers: client._authHeaders
        );
        
        var fetched = jsonDecode(res.body);
        client.users._storeAPIUser(fetched);
        
        return this;
    }
    
    User(this.client, { required this.id });
    
    User.fromJSON(this.client, Map<String, dynamic> data) {
        id = data['_id'];
        name = data['username'];
        avatar = data['avatar'] != null ? File.fromJSON(data['avatar']) : null;
        // data['relations']
        // data['badges']
        status = UserStatus(
            presence: data['status']?['presence'],
            text: data['status']?['text'],
        );
        switch(data['relationship']?['status']) {
            case 'Blocked': relationship = UserRelationship.Blocked; break;
            case 'Friends': relationship = UserRelationship.Friends; break;
            default:        relationship = UserRelationship.None;    break;
        }
        online = data['online'] ?? false;
        
        partial = false;
    }
}

/// UserUpdate event
class UserUpdate {
    User user;
    Map<String, dynamic> data;
    UserUpdate({ required this.user, required this.data });
}

class UserStatus {
    /// The presence of the user.
    /// Is null unless friends with the user.
    UserPresence? presence;
    
    /// The user's custom status text.
    /// Is null unless friends with the user.
    String? text;
    
    UserStatus({ this.presence, this.text });
}

/// A user's presence.
enum UserPresence {
    Online,
    Idle,
    Busy,
    Offline,
}

/// The client user's relationship with an user.
enum UserRelationship {
    Friends,
    Blocked,
    None,
}