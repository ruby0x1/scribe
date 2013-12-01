
	//A haxe documentation converter.
	//http://github.com/underscorediscovery/scribe
package scribe;

class Scribe {
	
	public function new( config_path : String = 'scribe.json' ) {

		var config = haxe.Json.parse( Utils.read_file( config_path ) );
    		//read the file data
        var _xml_data = scribe.Utils.read_file( config.input );
            //start to look at the components
        var xml = Xml.parse( _xml_data );
        	//starts with <haxe>
		var root = xml.firstElement();
			//parse the xml file.
		var haxedoc = scribe.HaxeXMLDocParser.parse( root, config );

			//once we are done, we can output the json
		scribe.export.JSON.export( haxedoc, config.output );

	}	

} //Scribe