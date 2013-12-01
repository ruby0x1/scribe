
import arguable.ArgParser;

class Main {

    public function new( args : arguable.ArgParser.ArgValues ) {
        
        new scribe.Scribe();
        
    }

    public static function display_usage() {
        Sys.println( '\nscribe v' + haxe.Resource.getString("version") );
        Sys.println( haxe.Resource.getString("usage") );
    }

    static function main() {

        var results = ArgParser.parse( Sys.args() );

        if(results.any) {
            new Main( results );
        } else {
            Main.display_usage();
        }

    } //main()

} //Main