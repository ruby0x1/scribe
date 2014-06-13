
import arguable.ArgParser;
import arguable.ArgParser.ArgValues;

class Main {

    static var old_cwd : String = '';
    static var cwd : String = '';

    public function new( run_path:String, args : ArgValues ) {

        old_cwd = Sys.getCwd();
        cwd = run_path;

        Sys.setCwd(cwd);

        var config_path = 'scribe.config.json';

        if( args.has('version') && args.length == 1 ) {
            display_version(false);
            return;
        } //version

        if( args.has('config') ) {
            config_path = args.get('config').value;
        } //config

        if( !sys.FileSystem.exists( config_path ) ) {

            display_version();

            Sys.println('- ERROR - Config path was invalid or config file is not found at ' + config_path);
            Sys.println('-       - Use a scribe.config.json file in the current folder or ');
            Sys.println('-       - pass the config path using -config your.config.json\n');

            return;

        } // config_path

            //read the config path
        var config = haxe.Json.parse( Utils.read_file( config_path ) );
        if(config == null) {
            display_version();
            Sys.println('- ERROR - Config file was unreadable?. \n');
            return;
        } //config == null

            //try and generate based on flags
        handle_generate( args, config );

            //fix changes we made
        Sys.setCwd(old_cwd);

    } //new

    static function handle_generate( args:ArgValues, config:Dynamic ) : Bool {

            //we must have a valid output path specified
        var _output_flag = args.get('output');

        if(config.output == null && _output_flag == null ) {
            display_version();
            Sys.println('- ERROR - Output path is required in config.output or -output outputfile.json \n');
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
                Sys.println('- ERROR - Cannot take -input without a file');
                return false;
            }
        } else {
            input_file = config.input;
        }

        if(_output_flag != null) {
            output_file = _output_flag.value;
        } else {
            output_file = (config.output != null) ? config.output : 'scribe_output.json';
        }

        if(args.has('display')) {
            output_file = '-display';
        }

        if( sys.FileSystem.exists( output_file ) && (!args.has('force') && !config.force ) ) {
            display_version();
            Sys.println('- ERROR - Cannot override ' + output_file + ' without -force or config.force = true');
            return false;
        }

        return do_generate( args, config, input_file, output_file );

    } //handle_generate

    static function generate_build_flags_hxml( args:ArgValues, config:Dynamic ) {

            //this runs a command like :
            //lime display /project/path/project.xml target

        var project_path : String = '';

        if(config.lime_project != null) {
            project_path = config.lime_project;
        }

        if(args.has('lime_project')) {
            project_path = args.get('lime_project').value;
        }

        if(project_path == '') {
            Sys.println("\n- WARNING - lime project type xml output requested but no lime project specified in config or with -lime_project");
            return '';
        }

        config.__project_path = project_path;

        var run_args = [
            'display',
            config.__project_path,
            Utils.current_platform()
        ];

        var process = new sys.io.Process('lime', run_args );
        var results = process.stdout.readAll().toString();

            process.close();

        return results;
    }

    static function generate_types_xml( args:ArgValues, config:Dynamic ) : Int {

            //try and generate the build flags
        var flags = generate_build_flags_hxml(args, config);

            //warning is up higher in the flags so we
            //can gracefully ignore
        if(flags == '') {
            return -1;
        }

            //There are flags, we can write them to a temp file
        Utils.save_file('.scribe.last_build_flags.hxml', flags);

            //The allowed packages should definitely be included, whether they are referenced or not
        if(Std.is(config.allowed_packages, String)) {
            config.allowed_packages = config.allowed_packages.split(',');
        }
            //so store them in an array
        var _allowed_packages : Array<String> = config.allowed_packages;
            _allowed_packages.map(function(_p:String){
                return _p = StringTools.trim(_p);
            });

            //now we construct our arguments for generating the xml type file
        var run_args = [
            cwd + '/.scribe.last_build_flags.hxml',
            '--no-output',
            '-dce', 'no',
            '-xml', cwd + '/scribe.types.xml'
        ];

            //and append each as a explicit --macro include('my.package')
        for(_package in _allowed_packages) {
            run_args.push('--macro');
            run_args.push('include("' + _package + '")');
        }

        Sys.println( run_args );

            //change to the project path
        Sys.setCwd( haxe.io.Path.directory(config.__project_path) );

            //and run it
        var _process = new sys.io.Process('haxe', run_args);
        var _results = _process.stdout.readAll().toString();

        var exitcode = _process.exitCode();
        if(exitcode != 0) {
            Sys.println("- ERROR - from lime project compile : ");
            Sys.println(_process.stderr.readAll());
        }

        _process.close();

            //set back to running path
        Sys.setCwd(cwd);

        return exitcode;

    } //generate_types_xml

    static function do_generate( args:ArgValues, config:Dynamic, input_file:String, output_file:String ) : Bool {

        if(!args.has('no-output-json')) {

                //to measure how long
            var _start_time = haxe.Timer.stamp();

                //if the input is a special file name we attempt to genrate the xml first
            if(input_file == 'scribe.types.xml') {
                var res = generate_types_xml( args, config );
                if(res != 0) {
                    Sys.println('- Stopping due to errors from build command.');
                    return false;
                }
            }

                //read the file data
            var _xml_data = '';

            try {
                _xml_data = Utils.read_file( input_file );
            } catch( e:Dynamic ) {
                Sys.println( "- ERROR - cannot read input xml file? " + input_file );
                Sys.println( e + "\n" );
                return false;
            }

                //parse it
            var haxedoc = scribe.Scribe.parse_from_string(config, _xml_data);
                //export it
            var json = scribe.export.JSON.format( haxedoc );

            if(output_file != '-display') {
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

        } //no-output-json

        if(!args.has('no-output')) {

            var _platform = Utils.current_platform();
            var postfix = '';

            switch(_platform) {
                case 'windows':
                    postfix = '-windows.exe';
                case 'linux':
                    postfix = '-linux64';
                case 'mac':
                    postfix = '-mac';
            }

            if(postfix == '') {
                Sys.println( "- ERROR - cannot find node for platform? in scriber/node/node-" + _platform + '\n');
                return false;
            }

            var node_path = old_cwd + 'scriber/node/node' + postfix;
            var script_path = old_cwd + 'scriber/' + 'generate';

            Utils.run(cwd, node_path, [script_path]);
        }

        return true;

    } //do_generate


    public static function display_version(adorned:Bool = true) {

        if(adorned) {
            Sys.println( '\nscribe v' + haxe.Resource.getString("version") + '\n' );
        } else {
            Sys.println( haxe.Resource.getString("version") );
        }

    } //display_version

    public static function display_usage() {

        display_version();
        Sys.println( haxe.Resource.getString("usage") );

    } //display_usage

    static function main() {

        var system_args = Sys.args();
        var run_path = system_args.pop();

        ArgParser.delimeter = '-';

        var results = ArgParser.parse( system_args );

        new Main( run_path, results );

    } //main

} //Main