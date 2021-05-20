part of dartvolt;

class File {
    String id;
    String tag;
    String filename;
    String type;
    String content_type;
    int filesize;
    
    /// If the file is an image
    int? width; /// Image width
    int? height; /// Image height
    
    File({
        required this.id,
        required this.tag,
        required this.filename,
        required this.type,
        required this.content_type,
        required this.filesize,
        this.width,
        this.height,
    });
}