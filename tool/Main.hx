
import arguable.ArgParser;
import arguable.ArgParser.ArgValues;

class Main {

    static var old_cwd : String = '';
    static var cwd : String = '';

    static var skip_scribe : Bool = false;
    static var skip_scriber : Bool = false;

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

        skip_scribe = args.has('no-scribe');
        skip_scriber = args.has('no-scriber');

        if( !sys.FileSystem.exists( config_path ) && !skip_scribe ) {

            display_version();

            Sys.println('- ERROR - Config path was invalid or config file is not found at ' + config_path);
            Sys.println('-       - Use a scribe.config.json file in the current folder or ');
            Sys.println('-       - pass the config path using -config your.config.json\n');

            return;

        } // config_path

        var config = {};

        if(!skip_scribe) {

            //read the config path
            config = haxe.Json.parse( Utils.read_file( config_path ) );

            if(config == null) {
                display_version();
                Sys.println('- ERROR - Config file was unreadable?. \n');
                return;
            } //config == null

        } //skip_scribe

            //try and generate based on flags
        handle_generate( args, config );

            //fix changes we made
        Sys.setCwd(old_cwd);

    } //new

    static function handle_generate( args:ArgValues, config:Dynamic ) : Bool {

        var input_file = '';
        var output_file = '';

        if(!skip_scribe) {

                //we must have a valid output path specified
            var _output_flag = args.get('output');

            if(config.output == null && _output_flag == null ) {
                display_version();
                Sys.println('- ERROR - Output path is required in config.output or -output outputfile.json \n');
                return false;
            }

                //if they are asking for a specific file
                // on the command line parse that first

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

        } //!skip_scribe

        return do_generate( args, config, input_file, output_file );

    } //handle_generate

    static function generate_build_flags_hxml_from_aether( args:ArgValues, config:Dynamic ) {

            //this runs a command like :
            //aether display /project/path/project.xml target

        var project_path : String = '';

        if(config.lime_project != null) {
            project_path = config.lime_project;
        }

        if(args.has('aether_project')) {
            project_path = args.get('aether_project').value;
        }

        if(project_path == '') {
            Sys.println("\n- WARNING - lime project type xml output requested but no lime project specified in config or with -aether_project");
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

    static function generate_build_flags_hxml_from_flow( args:ArgValues, config:Dynamic ) {

            //this runs a command like :
            //flow <system> info --hxml /project/path/project.flow target

        var project_path : String = '';

        if(config.flow_project != null) {
            project_path = config.flow_project;
        }

        if(args.has('flow_project')) {
            project_path = args.get('flow_project').value;
        }

        if(project_path == '') {
            Sys.println("\n- WARNING - flow project output requested but no flow project specified in config or with -flow_project");
            return '';
        }

        config.__project_path = project_path;

        var run_args = [
            'info',
            Utils.current_platform(),
            '--hxml',
            '--project',
            config.__project_path
        ];

        var process = new sys.io.Process('flow', run_args );
        var results = process.stdout.readAll().toString();

            process.close();

        return results;

    }

    static function generate_types_xml( args:ArgValues, config:Dynamic ) : Int {

            //try and generate the build flags
        var flags = generate_build_flags_hxml_from_flow(args, config);

            //warning is up higher in the flags so we
            //can gracefully ignore
        if(flags == '') {
            return -1;
        }

            //There are flags, we can write them to a temp file
        Utils.save_file('.scribe.last_build_flags.hxml', flags);

            //now we construct our arguments for generating the xml type file
        var run_args = [
            cwd + '/.scribe.last_build_flags.hxml',
            '--no-output',
            '-dce', 'no',
            '-xml', cwd + '/scribe.types.xml'
        ];

            //and append each as a explicit --macro include('my.package')
        for(_package in allowed_packages) {
            run_args.push('--macro');
            run_args.push('include("' + _package + '")');
        }

            //and append each as a explicit --macro include('my.package')
        for(_type in allowed_from_empty_package) {
            run_args.push('--macro');
            run_args.push('keep("' + _type + '")');
        }

        Sys.println( run_args );

            //change to the project path
        Sys.setCwd( haxe.io.Path.directory(config.__project_path) + '/bin/mac64.build/' );

            //and run it
        var _process = new sys.io.Process('haxe', run_args);
        var _results = _process.stdout.readAll().toString();

        var exitcode = _process.exitCode();
        if(exitcode != 0) {
            Sys.println("- ERROR - from project compile : ");
            Sys.println(_process.stderr.readAll());
        }

        _process.close();

            //set back to running path
        Sys.setCwd(cwd);

        return exitcode;

    } //generate_types_xml


    static var allowed_packages : Array<String>;
    static var allowed_from_empty_package : Array<String>;

    static function init_config(args:ArgValues, config:Dynamic) {

        allowed_packages = [];
        allowed_from_empty_package = [];

            //The allowed packages should definitely be included, whether they are referenced or not
        if(Std.is(config.allowed_packages, String)) {
            config.allowed_packages = config.allowed_packages.split(',');
        }
            //The allowed types should be included from the empty package
        if(Std.is(config.allowed_from_empty_package, String)) {
            config.allowed_from_empty_package = config.allowed_from_empty_package.split(',');
        }
            //so store them in an array
        var _allowed_packages : Array<String> = config.allowed_packages;
            _allowed_packages.map(function(_p:String){
                return _p = StringTools.trim(_p);
            });

            //so store them in an array
        var _allowed_from_empty_package : Array<String> = config.allowed_from_empty_package;
        if(_allowed_from_empty_package == null) {
            _allowed_from_empty_package = [];
        }

        _allowed_from_empty_package.map(function(_p:String){
            return _p = StringTools.trim(_p);
        });

        allowed_packages = _allowed_packages;
        allowed_from_empty_package = _allowed_from_empty_package;

    } //init_config

    static function do_generate( args:ArgValues, config:Dynamic, input_file:String, output_file:String ) : Bool {

        if(!skip_scribe) {

                //to measure how long
            var _start_time = haxe.Timer.stamp();


            init_config(args, config);

                //if the input is a special file name we attempt to genrate the xml first
            if(input_file == 'scribe.types.xml' && args.has('do-generate')) {
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

        if(!args.has('skip_scriber')) {

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

        ArgParser.delimiter = '-';

        var results = ArgParser.parse( system_args );

        new Main( run_path, results );

    } //main

} //Main