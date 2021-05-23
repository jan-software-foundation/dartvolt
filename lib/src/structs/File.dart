part of dartvolt;

class File {
    String id;
    String tag;
    String filename;
    String content_type;
    String? type;
    int filesize;
    
    /// If the file is an image
    int? width; /// Image width
    int? height; /// Image height
    
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
}