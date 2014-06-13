package scribe.export;

class JSON {

    public static function format( haxedoc:Dynamic ) {

        return haxe.Json.stringify(haxedoc, null, '   ' );

    } //format

} //JSON

