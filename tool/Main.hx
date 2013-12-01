
import arguable.ArgParser;
import arguable.ArgParser.ArgValues;

class Main {

    public function new( args : ArgValues ) {

        var config_path = 'scribe.json';

        if( args.has('version') && args.length == 1 ) {
            display_version(false);
            return;
        }

        if( args.has('config') ) {
            config_path = args.get('config').value;
        }

        if( !sys.FileSystem.exists( config_path ) ) {
            display_version();
            Sys.println('- ERROR - Config path was invalid. ');
            Sys.println('-       - Use a scribe.json file in the current folder or ');
            Sys.println('-       - pass the config path using --config your.config.json\n');
            return;
        }

            //read the config path
        var config = haxe.Json.parse( Utils.read_file( config_path ) );
        if(config == null) {
            display_version();
            Sys.println('- ERROR - Config file was unreadable?. \n');
            return;
        }

            //If attempting to generate
        if( args.has('generate') ) {
            if(!handle_generate( args, config )) {
                return;
            }
        }

    }

    static function handle_generate( args:ArgValues, config:Dynamic ) : Bool {
            
            //we must have a valid output path specified
        var _generate_flag = args.get('generate');

        if(config.output == null && _generate_flag.value.length == 0 ) {
            display_version();
            Sys.println('- ERROR - Output path is required in config.output or --generate outputfile.json \n');
            return false;
        }

            //if they are asking for a specific file
            // on the command line parse that first
        var input_file = '';
        var output_file = '';

        if(args.has('input')) {
            input_file = args.get('input').value;
            if(input_file.length == 0) {
                 display_version();
                Sys.println('- ERROR - Cannot take --input without a file');
                return false;
            }
        } else {
            input_file = config.input;
        }

        if(_generate_flag.value.length != 0) {
            output_file = _generate_flag.value;
        } else {
            output_file = (config.output != null) ? config.output : 'docs.json';
        }

        if(args.has('display')) {
            output_file = '--display';
        }

        if( sys.FileSystem.exists( output_file ) && (!args.has('force') && !config.force ) ) {
            display_version();
            Sys.println('- ERROR - Cannot override ' + output_file + ' without --force or config.force = true');
            return false;
        }
        
        return do_generate( input_file, output_file, config );

    } //handle_generate
        
    static function do_generate(input_file:String, output_file:String, config:Dynamic) : Bool {

            //to measure how long
        var _start_time = haxe.Timer.stamp();
            //read the file data
        var _xml_data = Utils.read_file( input_file );
            //parse it
        var haxedoc = scribe.Scribe.parse_from_string(config, _xml_data);
            //export it
        var json = scribe.export.JSON.format( haxedoc );

        if(output_file != '--display') {
                //save it
            Utils.save_file( output_file, json );
                //calculate and round to a fixed precision
            var _time = haxe.Timer.stamp() - _start_time;
            var _n = Math.pow(10,5); //5 decimal points
                _time = (Std.int(_time*_n) / _n);

            Sys.println('converted ' + input_file + ' to ' + output_file + ' in ' + _time + 's' );
        } else {
            Sys.println(json);
        }

        return true;

    } //do_generate


    public static function display_version(adorned:Bool = true) {
        if(adorned) {
            Sys.println( '\nscribe v' + haxe.Resource.getString("version") + '\n' );
        } else {
            Sys.println( haxe.Resource.getString("version") );
        }
    }   

    public static function display_usage() { 
        display_version();       
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