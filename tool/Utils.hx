
import sys.io.Process;
import sys.FileSystem;
import haxe.io.BytesOutput;
import haxe.io.Eof;

class Utils {

    public static function read_file( _path:String ) : String {
        var f = sys.io.File.read( _path, false );
        var d = f.readAll().toString();
        f.close();
        return d;
    }
    
    public static function save_file( _path:String, _content:String ) {
        var file : sys.io.FileOutput = sys.io.File.write( _path, false);
            file.writeString(_content);
            file.close();
    }

    public static function current_platform() : String {
        return Std.string(Sys.systemName()).toLowerCase();
    }

    public static function run( path:String, command:String, args:Array<String> ) {

        var last_path:String = "";
        
        if (path != null && path != "") {
            
            Sys.println("\tchanging directory: " + path + " for " + command );
            
            last_path = Sys.getCwd();
            Sys.setCwd (path);
            
        }
        
        var _args = "";
        for (arg in args) {
            if (arg.indexOf (" ") > -1) {
                _args += " \"" + arg + "\"";
            } else {
                _args += " " + arg;
            }
        }
                
        Sys.println("\trunning : " + command + _args +  '\n');

        var result = Sys.command(command, args);

        if (last_path != "") {
            Sys.setCwd (last_path);
        }
        
        return result;

    } //run_process
    
}