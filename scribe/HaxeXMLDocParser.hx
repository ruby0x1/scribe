
package scribe;

typedef PropertyDoc = { 
    var isread : Bool;
    var iswrite : Bool;

    var signature : String;
    var type : String;
    var type_desc : String;
    var name : String;
};

typedef MemberDoc = {
    var ispublic : Bool;
    var isstatic : Bool;
    var isinline : Bool;

    var signature : String;
    var type : String;
    var name : String;
};

typedef UnknownDoc = {
    var name : String;
    var node : Xml;    
};

typedef Argument = {
    var name : String;
    var type : String;
};

typedef MethodDoc = { 
    var ispublic : Bool;
    var isstatic : Bool;
    var isinline : Bool;

    var signature : String;
    var args : Array<Argument>;
    var returntype : String;
    var name : String;
};

typedef ClassDoc = {
    var ispublic : Bool;

    var meta : Map<String, Dynamic>;
    var extend : Array<String>;
    var implement : Array<String>;
    var members : Map<String, MemberDoc>;
    var methods : Map<String, MethodDoc>;
    var properties : Map<String, PropertyDoc>;
    var name : String;
};

typedef PackageDoc = {
    var classes : Map<String, ClassDoc>;
};

typedef HaxeDoc = {
    var classnames : Array<String>;
    var classes : Map<String, ClassDoc>;
};

//Internal typedefs

private typedef InternalMethodInfo = {
    var name : String;
    var args : Array<Argument>;
    var return_type : String;
}; 

class HaxeXMLDocParser {

    public static function parse( root:Xml, config:Dynamic ) : HaxeDoc {

        var _classnames : Array<String> = [];
        var _classes : Map<String, ClassDoc> = new Map<String,ClassDoc>();
        var _start_time = haxe.Timer.stamp();

        for(_class in root.elementsNamed('class')) {

            var _package = _class.get('path');          

                //check that the class is in the allowed packages,
                //and if so add it to the list
            var _allowed = false;
            if(config.allowed_packages != null) {
                if(Std.is(config.allowed_packages, String)) {
                    config.allowed_packages = config.allowed_packages.split(',');
                }
                var _allowed_packages : Array<String> = config.allowed_packages;
                for(_allowed_package in _allowed_packages) {
                    var regex_term = '^'+ _allowed_package +'.*$';
                    var regex = new EReg(regex_term, 'gim');
                    if(regex.match(_package)) {
                        _allowed = true;                
                    } //if there is a match
                } //for each allowed package
            } else { //config.allowed_packages
                _allowed = true;
            }

            if(_allowed) {

                    //store the class in the list of names
                _classnames.push( _package );

                    //finally store the ClassDoc in the list
                _classes.set( _package, parse_class( _class, config ) );
            }

        } //for each class

        Sys.println( haxe.Timer.stamp() - _start_time );

        return { classnames:_classnames, classes:_classes };

    } //parse

    static function parse_class( _class:Xml, config:Dynamic ) : ClassDoc {

        var _members = new Map<String, MemberDoc>();
        var _methods = new Map<String, MethodDoc>();
        var _properties = new Map<String, PropertyDoc>();
        var _unknowns = new Map<String, UnknownDoc>();
        var _meta = new Map<String, Dynamic>();
        var _extends = new Array<String>();
        var _implements = new Array<String>();
        var _meta_tags = _class.elementsNamed('meta');

        var _isprivate : Bool = (_class.get('private') != null);

        if(_meta_tags != null) {
            _meta.set('meta', _meta_tags.next());
        }

            //for each member, parse it and store it
        for(_member in _class.elements()) {

                //for reusing the name
            var _member_name = _member.nodeName;

            if(_member_name == 'extends') {
                var _base = _member.get('path');
                
                var _type_params = _member.elements();                
                if(_type_params.hasNext()) {
                    var _types = '<';
                    for(_param in _type_params) {
                        if(_param.nodeName != 'd') {
                            _types += _param.get('path') + ',';
                        } else {
                            _types += 'Dynamic,';
                        }
                    }
                    _types = _types.substring(0, _types.length-1);
                    _types += '>';

                    _extends.push(_base + _types);
                } else {
                    _extends.push(_base);
                }

            } else 
            if(_member_name == 'implements') {

                 var _base = _member.get('path');                    

                var _type_params = _member.elements();                
                if(_type_params.hasNext()) {
                    var _types = '<';
                    for(_param in _type_params) {
                        if(_param.nodeName != 'd') {
                            _types += _param.get('path') + ',';
                        } else {
                            _types += 'Dynamic,';
                        }
                    }
                    _types = _types.substring(0, _types.length-1);
                    _types += '>';

                    _implements.push(_base + _types);
                } else {
                    _implements.push(_base);
                }

            } else {
                    //we use these to determine the type
                var _set = _member.get('set');
                var _get = _member.get('get');

                    //without any set/get, it is a regular variable
                if(_set == null && _get == null) {
                        //store in the member list
                    _members.set( _member_name, parse_member(_member, config) );
                } else 
                    //with "method" it is a function
                if(_set == 'method') {
                        //store in the method list
                    _methods.set( _member_name, parse_method(_member, config) );
                } else 
                    //this is a property 
                if(_set == 'accessor' || _get == 'accessor' ) {
                        //store in the properties list
                    _properties.set( _member_name, parse_property(_member, config) );
                } 
                    //any unknowns 
                else {
                    _unknowns.set( _member_name, parse_unknown(_member, config) );
                }
            } //not specifically parsed            

        } //for each element in the class

        return { 
            name:_class.get('path'), 
            meta:_meta, 
            extend:_extends, 
            implement:_implements, 
            members:_members,
            methods:_methods,
            properties:_properties, 
            ispublic:!_isprivate 
        };

    } //parse_class

    static function parse_member( _member:Xml, config:Dynamic ) : MemberDoc {

            var _ispublic : Bool = false;
            var _isstatic : Bool = false;
            var _isinline : Bool = false;

            var _signature : String = '';
            var _type : String = '';
            var _name : String = _member.nodeName;

                    //access flags
                _isstatic = (_member.get('static') != null);
                _ispublic = (_member.get('public') != null);
                _isinline = (_member.get('get') == 'inline');

                    //type
                var _type_node = _member.firstElement();
                var _membertype = 'Dynamic';
                if(_type_node != null) {
                    var _thetype = _type_node.get('path');
                    if(_thetype != null) {
                        
                            //Type Parameter types have child elements
                        var _type_params = _type_node.elements();
                        var _has_type_params = _type_params.hasNext();
                        if(_has_type_params) {
                                //for each child element, append it
                            var _member_type_params = '<';
                            for(_type_param in _type_params) {
                                if(_type_param.nodeName != 'd') {
                                    _member_type_params += _type_param.get('path') + ',';
                                } else {
                                    _member_type_params += 'Dynamic,';
                                }
                            }
                            _member_type_params = _member_type_params.substring(0, _member_type_params.length-1);
                            _member_type_params += '>';

                            _membertype = _thetype + _member_type_params;

                        } else {
                            _membertype = _thetype;
                        }
                    } //!= null

                }

                    //store 
                _signature = _member.nodeName + ' : ' + _membertype;
                _type = _membertype;
                _name = _member.nodeName;

        return { 
            ispublic : _ispublic,
            isstatic : _isstatic,
            isinline : _isinline,

            signature : _signature,
            type : _type,
            name : _name
        };

    } //parse_member

    static function parse_method( _member:Xml, config:Dynamic ) : MethodDoc {

        var _ispublic : Bool = false;
        var _isstatic : Bool = false;
        var _isinline : Bool = false;

        var _signature : String = '';
        var _args : Array<Argument> = [];
        var _returntype : String = '';
        var _name : String = '';

                    //access flags
                _isstatic = (_member.get('static') != null);
                _ispublic = (_member.get('public') != null);
                _isinline = (_member.get('get') == 'inline');

                    //fetch from a helper function for clarity.
                var _finfo = parse_function_node( _member );
                    //Append a easier on the eyes function return type for the signature
                var _rtype = ': ' + _finfo.return_type;
                    //constructor has no return type
                if(_finfo.name == 'new') _rtype = '';
                    
            var _shortargs : Array<String> = [];
            for(_arg in _finfo.args) { _shortargs.push(_arg.name + ':' + _arg.type); }

            //Store the final values
        _signature = _finfo.name + '(' + _shortargs.join(', ') + ') ' +  _rtype;
        _args = _finfo.args;
        _returntype = _rtype;
        _name = _member.nodeName;

        return { 
            ispublic : _ispublic,
            isstatic : _isstatic,
            isinline : _isinline,

            args : _args,
            signature : _signature,
            returntype : _returntype,
            name : _name
        };

    } //parse_method

    static function parse_property( _member:Xml, config:Dynamic ) : PropertyDoc {

            //default to write/read
        var _isread : Bool = true;
        var _iswrite : Bool = true;

        var _signature : String = '';
        var _type : String = '';
        var _type_desc : String = 'read/write';
        var _name : String = '';

                //type
            var _type_node = _member.firstElement();
            var _membertype = 'Dynamic';
            if(_type_node != null) {
                var _thetype = _type_node.get('path');
                if(_thetype != null) _membertype = _thetype;
            }

                //we use these to determine the type
            var _set = _member.get('set');
            var _get = _member.get('get');

                //What type of access does it allow?            
            if((_get == 'never' || _get == 'null') && (_set == 'accessor' || _set == 'inline') ) {
                _type_desc = '(write only)';
                _isread = false;
            } else if( (_set == 'never' || _set == 'null') && (_get == 'accessor' || _get == 'inline') ) {
                _type_desc = '(read only)';
                _iswrite = false;
            }

            _name = _member.nodeName;
            _type = _membertype;
            _signature = _member.nodeName  + ' : ' + _membertype;

        return {
            isread : _isread,
            iswrite : _iswrite,

            signature : _signature,
            type : _type,
            type_desc : _type_desc,
            name : _name
        };

    } //parse_property

    static function parse_unknown( _member:Xml, config:Dynamic ) : UnknownDoc {
        return { name:_member.nodeName, node:_member };
    } //parse_unknown


//internal functions
    static function parse_internal_function_type(_f:Xml){
            
        var _final = '';
            //Just brute force them into a list with -> at the end
        for(_arg in _f.elements()) {
            _final += _arg.get('path') + '->';
        }

            //And remove the final -> (... I know.)
        _final = _final.substr(0,_final.length-2);

        return _final;

    } //parse_internal_function_type

    static function parse_function_node( _member:Xml ) : InternalMethodInfo {
            
            //the first element has the arguments in
        var _node = _member.firstElement(); 
        var _args_list : String = _node.get('a');
        var _args = [];
            //if there are any, split and store them
        if(_args_list.length > 0) {
            _args = _args_list.split(':');
        }

            //the types are stored separately... (oh but we are parsing xml...ok)
        var _arg_types = [];
        var _return_type = '';

            //for each of the node elements in the argument node
        for(_arg_info in _node.elements()) {      

            if(_arg_info.nodeName == 'f') {
                    //if it's a function, there is a more complex approac hander
                _arg_types.push( parse_internal_function_type(_arg_info) );
            } else {
                    
                    //Type Parameter types have child elements
                var _type_params = _arg_info.elements();
                var _has_type_params = _type_params.hasNext();
                if(_has_type_params) {
                        //for each child element, append it
                    var _arg_type_params = '<';
                    for(_type_param in _type_params) {
                        if(_type_param.nodeName != 'd') {
                            _arg_type_params += _type_param.get('path') + ',';
                        } else {
                            _arg_type_params += 'Dynamic,';
                        }
                    }
                    _arg_type_params = _arg_type_params.substring(0, _arg_type_params.length-1);
                    _arg_type_params += '>';
                    _arg_types.push( _arg_info.get('path') + _arg_type_params );
                } else {
                        //all others just store the type 
                    _arg_types.push( _arg_info.get('path') );
                }                
            }

        } //for each argument info node elements

            //return type is the last item in the _arg_types
        _return_type = _arg_types.pop();

            //Now recombine these into a list by name:Type
            //If no type is specified, insert Dynamic (this could be something else? Null<?>)
        var _args_final : Array<Argument> = [];
        for(i in 0 ... _args.length) {

            var _atype = _arg_types[i];
                //check if there is no type defined
            if(_atype == null || _atype == 'null') {
                _atype = 'Dynamic';
            }

            _args_final.push({ name:_args[i], type:_atype });

        } //for each collected argument

        return {
            name : _member.nodeName,
            args : _args_final,
            return_type : _return_type
        };

    } //parse_function_node



} //HaxeXMLDocParser