part of dartvolt;

abstract class BaseUser {
  Client client;
  late String id;
  late String username;

  BaseUser(this.client, {required this.id, required this.username});
  BaseUser.fromJson(this.client, Map<String, dynamic> json) {
    id = json['_id'];
    username = json['username'];
  }
}

// TODO i am too tired to finish this right now
class User extends BaseUser {
  @override
  Client client;
  @override
  late String id;
  @override
  late String username;

  User(this.client, {required this.id, required this.username})
      : super(client, id: id, username: username);
}
