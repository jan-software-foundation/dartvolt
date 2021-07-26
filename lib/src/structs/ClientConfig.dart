part of dartvolt;

class ClientConfig {
    String apiUrl;
    bool debug;
    String user_agent;
    
    ClientConfig({
        this.apiUrl = 'https://api.revolt.chat',
        this.debug = false,
        this.user_agent = 'dartvolt/1.0 '
            '(+https://github.com/janderedev/dartvolt)'
    });
}
