part of dartvolt;

class File {
    late String id;
    late String tag;
    late String filename;
    late String content_type;
    late String? type;
    late int filesize;
    
    /// If the file is an image
    late int? width; /// Image width
    late int? height; /// Image height
    
    File({
        required this.id,
        required this.tag,
        required this.filename,
        required this.content_type,
        required this.filesize,
        this.type,
        this.width,
        this.height,
    });
    
    File.fromJSON(Map<String, dynamic> json) {
        id = json['_id'];
        content_type = json['content_type'];
        filename = json['filename'];
        tag = json['tag'];
        filesize = json['size'];
        type = json['metatata']?['type'];
        height = json['metatata']?['height'];
        width = json['metatata']?['width'];
    }
}
