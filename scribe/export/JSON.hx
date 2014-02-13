package scribe.export;

import scribe.HaxeXMLDocParser.HaxeDoc;
import scribe.HaxeXMLDocParser.ClassDoc;
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
                export_json = insert(export_json, ']', tab_depth);

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
                    export_json = insert(export_json, '"public":'       + _member.ispublic + ',', tab_depth);
                    export_json = insert(export_json, '"inline":'       + _member.isinline + ',', tab_depth);
                    export_json = insert(export_json, '"static":'       + _member.isstatic + ',', tab_depth);
                    export_json = insert(export_json, '"signature":"'   + _member.signature + '",', tab_depth);
                    export_json = insert(export_json, '"type":"'        + _member.type + '"', tab_depth);
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
                    export_json = insert(export_json, '"public":'       + _method.ispublic + ',', tab_depth);
                    export_json = insert(export_json, '"static":'       + _method.isstatic + ',', tab_depth);
                    export_json = insert(export_json, '"inline":'       + _method.isinline + ',', tab_depth);
                    export_json = insert(export_json, '"signature":"'   + _method.signature + '",', tab_depth);
                    export_json = insert(export_json, '"return":"'      + _method.returntype + '",', tab_depth);
                
                var arg_count = _method.args.length;
                var _current_arg = 0;
                export_json = insert(export_json, '"args":[', tab_depth);
                    tab_depth++;
                        for(_arg in _method.args) {
                            _current_arg++;
                            export_json = insert(export_json, '{ "name": "'+_arg.name+'","type": "'+_arg.type+'" }' + ((_current_arg != arg_count) ? ',' : ''), tab_depth);
                        }
                    tab_depth--;
                export_json = insert(export_json, ']', tab_depth);

            tab_depth--;
        export_json = insert(export_json, '}' + ((_c != _t) ? ',' : ''), tab_depth);
        return export_json;
    }

    static function tabs(_s:String, _count:Int) { for(i in 0 ..._count) { _s = '\t' + _s; }  return _s; }
    static function insert( _target:String, _kind:String, _tabs:Int ) {
        _target += tabs(_kind, _tabs) + '\n';
        return _target;
    }   


} //JSON