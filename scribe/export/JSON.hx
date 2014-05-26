package scribe.export;

import scribe.HaxeXMLDocParser.HaxeDoc;
import scribe.HaxeXMLDocParser.ClassDoc;
import scribe.HaxeXMLDocParser.TypedefDoc;
import scribe.HaxeXMLDocParser.EnumDoc;
import scribe.HaxeXMLDocParser.MemberDoc;
import scribe.HaxeXMLDocParser.PropertyDoc;
import scribe.HaxeXMLDocParser.MethodDoc;
import scribe.HaxeXMLDocParser.Argument;

class JSON {

    public static function format( haxedoc:HaxeDoc ) {

        var export_data = {
            types:haxedoc.types, 
            names:haxedoc.typelist
        };

        return haxe.Json.stringify(export_data, null, '  ' );

    } //format

} //JSON

