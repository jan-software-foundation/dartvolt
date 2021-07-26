part of dartvolt;

class Role {
    /// The Client that created this Object
    Client client;
    
    /// The role's ID
    String id;
    
    /// The role's name
    String name;
    
    /// The role's permissions
    RolePermissions permissions;
    
    /// The role's hex color
    String? color;
    
    Role(this.client, {
        required this.id,
        required this.name,
        required this.permissions,
        required this.color
    });
}
