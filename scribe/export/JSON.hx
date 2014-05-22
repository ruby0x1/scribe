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

        var export_json = '';

        var tab_depth : Int = 0;

        export_json = insert(export_json, '{', tab_depth );
            tab_depth++;

    //classes
            export_json = insert(export_json, '"classes":[', tab_depth);
                tab_depth++;

                    //for each class
                var _class_count = Lambda.count(haxedoc.classes);
                var _current_class = 0;
                for(_class in haxedoc.classes) {
                    _current_class++;
                    export_json = push_class(export_json, _class, tab_depth, _current_class, _class_count);
                } //_class

                tab_depth--;
            export_json = insert(export_json, '],', tab_depth);

    //typedefs
            export_json = insert(export_json, '"typedefs":[', tab_depth);
                tab_depth++;

                    //for each class
                var _typedef_count = Lambda.count(haxedoc.typedefs);
                var _current_typedef = 0;
                for(_typedef in haxedoc.typedefs) {
                    _current_typedef++;
                    export_json = push_typedef(export_json, _typedef, tab_depth, _current_typedef, _typedef_count);
                } //_class

                tab_depth--;
            export_json = insert(export_json, '],', tab_depth);
    
    //enums
            export_json = insert(export_json, '"enums":[', tab_depth);
                tab_depth++;

                    //for each class
                var _enum_count = Lambda.count(haxedoc.enums);
                var _current_enum = 0;
                for(_enum in haxedoc.enums) {
                    _current_enum++;
                    export_json = push_enum(export_json, _enum, tab_depth, _current_enum, _enum_count);
                } //_class

                tab_depth--;
            export_json = insert(export_json, ']', tab_depth);


            tab_depth--;
        export_json = insert(export_json, '}', tab_depth );

        return export_json;
    }

    static function push_class(export_json:String, _class:ClassDoc, tab_depth:Int, _c:Int, _t:Int ) {

        export_json = insert(export_json, '{ "name": "'+ _class.name +'",', tab_depth);

//Meta
            export_json = insert(export_json, '  "meta":[', tab_depth);
                tab_depth++;

                        //for each member
                    var _meta_count = Lambda.count(_class.meta);
                    var _current_meta = 0;
                    for(_meta in _class.meta) {
                        _current_meta++;
                        export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                    }

                tab_depth--;
            export_json = insert(export_json, '  ],', tab_depth);


// Sub properties

            tab_depth++;

    //extends
                export_json = insert(export_json, '"extends":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _extends_count = _class.extend.length;
                        var _current_extend = 0;
                        for(_extend in _class.extend) {
                            _current_extend++;
                            export_json = push_extend(export_json, _extend, tab_depth, _current_extend, _extends_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //implements
                export_json = insert(export_json, '"implements":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _implements_count = _class.implement.length;
                        var _current_implement = 0;
                        for(_implement in _class.implement) {
                            _current_implement++;
                            export_json = push_implement(export_json, _implement, tab_depth, _current_implement, _implements_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //members
                export_json = insert(export_json, '"members":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _member_count = Lambda.count(_class.members);
                        var _current_member = 0;
                        for(_member in _class.members) {
                            _current_member++;
                            export_json = push_member(export_json, _member, tab_depth, _current_member, _member_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //properties
                export_json = insert(export_json, '"properties":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _property_count = Lambda.count(_class.properties);
                        var _current_property = 0;
                        for(_property in _class.properties) {
                            _current_property++;
                            export_json = push_property(export_json, _property, tab_depth, _current_property, _property_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //methods
                export_json = insert(export_json, '"methods":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _method_count = Lambda.count(_class.methods);
                        var _method_property = 0;
                        for(_method in _class.methods) {
                            _method_property++;
                            export_json = push_method(export_json, _method, tab_depth, _method_property, _method_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //doc
                export_json = insert(export_json, '"ispublic":' + _class.ispublic + ',', tab_depth);
                export_json = insert(export_json, '"doc":"' + quote(_class.doc) + '"', tab_depth);


            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);

        return export_json;
    }

    static function push_typedef(export_json:String, _typedef:TypedefDoc, tab_depth:Int, _c:Int, _t:Int ) {

        export_json = insert(export_json, '{ "name": "'+ _typedef.name +'",', tab_depth);

//Meta
            export_json = insert(export_json, '  "meta":[', tab_depth);
                tab_depth++;

                        //for each member
                    var _meta_count = Lambda.count(_typedef.meta);
                    var _current_meta = 0;
                    for(_meta in _typedef.meta) {
                        _current_meta++;
                        export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                    }

                tab_depth--;
            export_json = insert(export_json, '  ],', tab_depth);


// Sub properties

            tab_depth++;

    //members
                export_json = insert(export_json, '"members":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _member_count = Lambda.count(_typedef.members);
                        var _current_member = 0;
                        for(_member in _typedef.members) {
                            _current_member++;
                            export_json = push_member(export_json, _member, tab_depth, _current_member, _member_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //doc
                export_json = insert(export_json, '"ispublic":' + _typedef.ispublic + ',', tab_depth);
                export_json = insert(export_json, '"doc":"' + quote(_typedef.doc) + '",', tab_depth);
                export_json = insert(export_json, '"alias":"' + quote(_typedef.alias) + '"', tab_depth);


            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);

        return export_json;
    }

    static function push_enum(export_json:String, _enum:EnumDoc, tab_depth:Int, _c:Int, _t:Int ) {

        export_json = insert(export_json, '{ "name": "'+ _enum.name +'",', tab_depth);

//Meta
            export_json = insert(export_json, '  "meta":[', tab_depth);
                tab_depth++;

                        //for each member
                    var _meta_count = Lambda.count(_enum.meta);
                    var _current_meta = 0;
                    for(_meta in _enum.meta) {
                        _current_meta++;
                        export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                    }

                tab_depth--;
            export_json = insert(export_json, '  ],', tab_depth);


// Sub properties

            tab_depth++;

    //members
                export_json = insert(export_json, '"values":[', tab_depth);
                    tab_depth++;

                            //for each value
                    var _total_enums = _enum.values.length;
                    var _current_enum = 0;
                    for(_value in _enum.values) {
                        _current_enum++;
                        export_json = insert(export_json, '"${_value}"' + ((_current_enum != _total_enums) ? ',' : ''), tab_depth);                        
                    }

                    tab_depth--;
                export_json = insert(export_json, '],', tab_depth);
    //doc
                export_json = insert(export_json, '"ispublic":' + _enum.ispublic + ',', tab_depth);
                export_json = insert(export_json, '"doc":"' + quote(_enum.doc) + '"', tab_depth);


            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);

        return export_json;
    }

    static function push_meta(export_json:String, _meta:String, _value:String='', tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{ "name":"'+_meta+'", "value":"'+_value+'" }' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }
    static function push_extend(export_json:String, _extend:String, tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{ "name":"'+_extend+'" }' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }
    static function push_implement(export_json:String, _implement:String, tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{ "name":"'+_implement+'" }' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }

    static function push_member(export_json:String, _member:MemberDoc, tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{', tab_depth);
            tab_depth++;

                    //write the member values
                export_json = insert(export_json, '"name":"'+_member.name+'",', tab_depth);

            //Meta
                export_json = insert(export_json, '  "meta":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _meta_count = Lambda.count(_member.meta);
                        var _current_meta = 0;
                        for(_meta in _member.meta) {
                            _current_meta++;
                            export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '  ],', tab_depth);


                tab_depth++;
                    export_json = insert(export_json, '"ispublic":'       + _member.ispublic + ',', tab_depth);
                    export_json = insert(export_json, '"isinline":'       + _member.isinline + ',', tab_depth);
                    export_json = insert(export_json, '"isstatic":'       + _member.isstatic + ',', tab_depth);
                    export_json = insert(export_json, '"signature":"'   + _member.signature + '",', tab_depth);
                    export_json = insert(export_json, '"type":"'        + _member.type + '",', tab_depth);
                    export_json = insert(export_json, '"doc":"'         + quote(_member.doc) + '"', tab_depth);
                tab_depth--;
                
            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }
    static function push_property(export_json:String, _property:PropertyDoc, tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{', tab_depth);
            tab_depth++;

                export_json = insert(export_json, '"name":"'+_property.name+'",', tab_depth);
  
            //Meta
                export_json = insert(export_json, '  "meta":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _meta_count = Lambda.count(_property.meta);
                        var _current_meta = 0;
                        for(_meta in _property.meta) {
                            _current_meta++;
                            export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '  ],', tab_depth);


                    //write the member values
                tab_depth++;
                    export_json = insert(export_json, '"get":'          + _property.isread + ',', tab_depth);
                    export_json = insert(export_json, '"set":'          + _property.iswrite + ',', tab_depth);
                    export_json = insert(export_json, '"signature":"'   + _property.signature + '",', tab_depth);
                    export_json = insert(export_json, '"doc":"'         + quote(_property.doc) + '",', tab_depth);
                    export_json = insert(export_json, '"type":"'        + _property.type + '",', tab_depth);
                    export_json = insert(export_json, '"type_desc":"'   + _property.type_desc + '"', tab_depth);
                tab_depth--;

            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }
    static function push_method(export_json:String, _method:MethodDoc, tab_depth:Int, _c:Int, _t:Int ) {
        export_json = insert(export_json, '{', tab_depth);
            tab_depth++;

                export_json = insert(export_json, '"name":"'+_method.name+'",', tab_depth);

            //Meta
                export_json = insert(export_json, '  "meta":[', tab_depth);
                    tab_depth++;

                            //for each member
                        var _meta_count = Lambda.count(_method.meta);
                        var _current_meta = 0;
                        for(_meta in _method.meta) {
                            _current_meta++;
                            export_json = push_meta(export_json, _meta.name, _meta.value, tab_depth, _current_meta, _meta_count);
                        }

                    tab_depth--;
                export_json = insert(export_json, '  ],', tab_depth);
                

                    //write the member values
                tab_depth++;
                    export_json = insert(export_json, '"ispublic":'       + _method.ispublic + ',', tab_depth);
                    export_json = insert(export_json, '"isstatic":'       + _method.isstatic + ',', tab_depth);
                    export_json = insert(export_json, '"isinline":'       + _method.isinline + ',', tab_depth);
                    export_json = insert(export_json, '"doc":"'         + quote(_method.doc) + '",', tab_depth);
                    export_json = insert(export_json, '"signature":"'   + _method.signature + '",', tab_depth);
                    export_json = insert(export_json, '"return":"'      + _method.returntype + '",', tab_depth);
                
                var arg_count = _method.args.length;
                var _current_arg = 0;
                export_json = insert(export_json, '"args":[', tab_depth);
                    tab_depth++;
                        for(_arg in _method.args) {
                            _current_arg++;
                            export_json = insert(export_json, '{ "name": "'+_arg.name+'","type": "'+_arg.type+'","value": "'+_arg.value+'" }' + ((_current_arg != arg_count) ? ',' : ''), tab_depth);
                        }
                    tab_depth--;
                export_json = insert(export_json, ']', tab_depth);

            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }

    static function tabs(_s:String, _count:Int) { for(i in 0 ..._count) { _s = '  ' + _s; }  return _s; }
    static function insert( _target:String, _kind:String, _tabs:Int ) {
        _target += tabs(_kind, _tabs) + '\n';
        return _target;
    }   

    static function quote( s : String ) {
            
        if(s.length == 0) return s;
        return StringTools.replace(s, '"', '\\\"');

    }

} //JSON

