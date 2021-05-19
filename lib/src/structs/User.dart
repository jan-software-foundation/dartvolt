part of dartvolt;

class User {
    Client client;
    late String id;
    String? name;
    bool? friends;
    bool partial = true;
    
    Future<User> fetch({ preferCache = true }) async {
        if (!partial && preferCache) {
            return this;
        }
        
        var res = await http.get(
            Uri.parse(client.clientConfig.apiUrl + '/users/$id'),
            headers: client._authHeaders
        );
        var fetched = jsonDecode(res.body);
        
        id = fetched['_id'];
        name = fetched['username'];
        friends = fetched['relationship'] == 'Friend';
        partial = false;
        
        return this;
    }
    
    User(this.client, { required this.id });
}