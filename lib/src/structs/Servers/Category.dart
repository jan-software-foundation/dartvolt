part of dartvolt;

class Category {
    /// The client that created this Object
    Client client;
    
    /// The category ID
    String id;
    
    /// The title of the category
    String title;
    
    /// Array of the channels in this category
    Map<String, Channel> channels;
    
    Category(this.client, {
        required this.id,
        required this.title,
        required this.channels
    });
}