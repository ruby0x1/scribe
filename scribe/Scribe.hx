
    //A haxe documentation converter.
    //http://github.com/underscorediscovery/scribe
package scribe;

import scribe.HaxeXMLDocParser.HaxeDoc;

class Scribe {
    
    public static function parse_from_string( config:Dynamic, xml:String ) : HaxeDoc {
            //first parse the xml
        var _xml = Xml.parse( xml );
            //return the parse results
        return parse_from_xml( config, _xml );
    }

    public static function parse_from_xml( config:Dynamic, root:Xml ) : HaxeDoc {
            //starts with <haxe>, so we start there
        var _root = root.firstElement();
            //return the parse results
        return scribe.HaxeXMLDocParser.parse( _root, config );
    }

} //Scribe