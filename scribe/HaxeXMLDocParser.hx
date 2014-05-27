
package scribe;

typedef PropertyDoc = { 

    var isread : Bool;
    var iswrite : Bool;
    var ispublic : Bool;
    var isstatic : Bool;

    var doc : String;
    var meta : Map<String, MetaDoc>;
    var signature : String;
    var type : TypeDoc;
    var access : String;
    var name : String;
        
        //whether this is an inherited property
    var inherited : Bool;
        //the place this was inherited from, if any
    var inherit_source : String;

} //PropertyDoc

typedef TypeDoc = {

        //the base name of the type, like "Map" or com.package.Blah
    var name : String;  
        //if this type has parameters, they are in here
    var params : Array<TypeDoc>;
        //if this type is a function declaration, 
        //it's set to true, and params stores the type information
        //and name holds the function signature instead
    var func : Bool;

} //TypeDoc

typedef MemberDoc = {

    var ispublic : Bool;
    var isstatic : Bool;
    var isinline : Bool;

    var doc : String;
    var meta : Map<String, MetaDoc>;
    var signature : String;
    var type : TypeDoc;
    var name : String;
        //this is only set if it's a typedef with optional ? var
    var optional : Bool;

        //whether this is an inherited property
    var inherited : Bool;
        //the place this was inherited from, if any
    var inherit_source : String;

} //MemberDoc

typedef UnknownDoc = {

    var name : String;
    var node : Xml; 

} //UnknownDoc

typedef MetaDoc = {

    var name : String;
    var value : String;

} //MetaDoc

typedef Argument = {

    var name : String;
    var type : TypeDoc;
    var value : String;

} //Argument

typedef EnumInfo = {

    var name : String;
    var doc : String;

} //EnumInfo

typedef MethodDoc = { 

    var ispublic : Bool;
    var isstatic : Bool;
    var isinline : Bool;    

    var doc : String;
    var meta : Map<String, MetaDoc>;
    var signature : String;
    var args : Array<Argument>;
    var return_type : TypeDoc;
    var name : String;

        //whether this is an inherited property
    var inherited : Bool;
        //the place this was inherited from, if any
    var inherit_source : String;

} //MethodDoc

typedef EnumDoc = {

    var name : String;
    var type_name : String;
    var type : String;

    var ispublic : Bool;
    var doc : String;
    var meta : Map<String, MetaDoc>;
    var values : Array<EnumInfo>;

} //EnumDoc

typedef TypedefDoc = {
    
    var name : String;
    var type_name : String;
    var type : String;

    var ispublic : Bool;
    var doc : String;
    var meta : Map<String, MetaDoc>;
    var members : Array<MemberDoc>;
    
    var alias : TypeDoc;

} //TypedefDoc

typedef ClassDoc = {

    var name : String;
    var type_name : String;
    var type : String;

    var ispublic : Bool;
    var doc : String;
    var meta : Map<String, MetaDoc>;
    var extend : Array<TypeDoc>;
    var implement : Array<TypeDoc>;
    var members : Array<MemberDoc>;
    var methods : Array<MethodDoc>;
    var properties : Array<PropertyDoc>;    

} //ClassDoc

typedef HaxeDoc = {

        //the list of typed items for 
    var classes : Map<String, ClassDoc>;
    var typedefs : Map<String, TypedefDoc>;
    var enums : Map<String, EnumDoc>;
        //the list of names for each type
    var class_list : Array<String>;
    var typedef_list : Array<String>;
    var enum_list : Array<String>;

        //full list for export convenience,
        //populated last to avoid disparity
    var types : Map<String, Dynamic>;
    var typelist : Array<String>;

} //HaxeDoc

//Internal typedefs

private typedef InternalMethodInfo = {

    var name : String;
    var args : Array<Argument>;
    var return_type : TypeDoc;
    var params : Array<String>;

}

class HaxeXMLDocParser {

    public static function parse( root:Xml, config:Dynamic ) : HaxeDoc {

            //first we parse the base types into the lists,
        var doc = pre_parse(root, config);

            //and then we post process them to merge inheritance, aliases etc
        doc = post_parse(doc, config);

            //and finally we merge them all into the final list
        for(_class in doc.classes) {
            doc.types.set(_class.name, _class);
        }

        for(_typedef in doc.typedefs) {
            doc.types.set(_typedef.name, _typedef);
        }

        for(_enum in doc.enums) {
            doc.types.set(_enum.name, _enum);
        }

            //and merge the names
        doc.typelist = doc.typelist.concat(doc.class_list);
        doc.typelist = doc.typelist.concat(doc.enum_list);
        doc.typelist = doc.typelist.concat(doc.typedef_list);

            //sort them
        doc.typelist.sort(sort_plain);

        return doc;

    } //parse

    static function _clone_method(_method:MethodDoc) : MethodDoc {
        return {
            ispublic : _method.ispublic,
            isstatic : _method.isstatic,
            isinline : _method.isinline,

            inherited : _method.inherited,
            inherit_source : _method.inherit_source,

            doc : _method.doc,
            meta : _method.meta,
            signature : _method.signature,
            args : _method.args.copy(),
            return_type : _method.return_type,
            name : _method.name
        };
    } //_clone_method

    static function _clone_member(_member:MemberDoc) : MemberDoc {

        return {
            ispublic : _member.ispublic,
            isstatic : _member.isstatic,
            isinline : _member.isinline,

            optional : _member.optional,
            inherited : _member.inherited,
            inherit_source : _member.inherit_source,

            doc : _member.doc,
            meta : _member.meta,
            signature : _member.signature,
            type : _member.type,
            name : _member.name
        };
    } //_clone_member

    static function _clone_property(_property:PropertyDoc) : PropertyDoc {

        return {
            isread : _property.isread,
            iswrite : _property.iswrite,
            isstatic : _property.isstatic,
            ispublic : _property.ispublic,

            inherited : _property.inherited,
            inherit_source : _property.inherit_source,

            doc : _property.doc,
            meta : _property.meta,
            signature : _property.signature,
            type : _property.type,
            access : _property.access,
            name : _property.name
        };
    } //_clone_property

    static function inherit_fields(_class:ClassDoc, doc:HaxeDoc, config:Dynamic) {
            
        //for each class this one inherits
        for(_parent_type in _class.extend) {
                //obtain its info
            var _parent = doc.classes.get(_parent_type.name);

                //classes from the std lib and 
                //excluded packages don't exist here
                //so we skip them entirely
            if(_parent == null) {
                continue;
            }
            
                //now, for each method, member and property
                //we want to selectively merge things down into 
                //this class, if the parent has a method this
                //class does not, we push it in here, and flag it inherited.
                //if this class has it, we just flagged it as inherited and set the source.
                //This happens recursively, so that parents at the top tier are set as the source
            if(_parent.extend.length == 0) {
                    //for each method
                for(_method in _parent.methods) {
                        //if exists in the child, flag it as inherited
                    var _in_child = Lambda.exists(_class.methods, function(m){ 
                        return m.name == _method.name;
                    });

                    if( _in_child ) {
                        Lambda.filter(_class.methods, function(m){
                            if(m.name == _method.name) {
                                m.inherited = true;
                                m.inherit_source = _parent.name;
                                return true;
                            }
                            return false;
                        });
                    } else {
                            //if it doesn't exist in the child, we need to add it
                        var _cm = _clone_method(_method);
                            _cm.inherited = true;
                            _cm.inherit_source = _parent.name;
                        _class.methods.push(_cm);
                    }
                } //for each method
        
                    //for each members
                for(_member in _parent.members) {
                        //if exists in the child, flag it as inherited
                    var _in_child = Lambda.exists(_class.members, function(m){ 
                        return m.name == _member.name;
                    });

                    if( _in_child ) {
                        Lambda.filter(_class.members, function(m){
                            if(m.name == _member.name) {
                                m.inherited = true;
                                m.inherit_source = _parent.name;
                                return true;
                            }
                            return false;
                        });
                    } else {
                            //if it doesn't exist in the child, we need to add it
                        var _cm = _clone_member(_member);
                            _cm.inherited = true;
                            _cm.inherit_source = _parent.name;
                        _class.members.push(_cm);
                    }
                } //for each member

                    //for each property
                for(_property in _parent.properties) {
                        //if exists in the child, flag it as inherited
                    var _in_child = Lambda.exists(_class.properties, function(m){ 
                        return m.name == _property.name;
                    });

                    if( _in_child ) {
                        Lambda.filter(_class.properties, function(m){
                            if(m.name == _property.name) {
                                m.inherited = true;
                                m.inherit_source = _parent.name;
                                return true;
                            }
                            return false;
                        });
                    } else {
                            //if it doesn't exist in the child, we need to add it
                        var _cm = _clone_property(_property);
                            _cm.inherited = true;
                            _cm.inherit_source = _parent.name;
                        _class.properties.push(_cm);
                    }
                } //for each property

            } else {
                inherit_fields(_parent, doc, config);
            }
        }
    }

    static function alias_fields( _typedef:TypedefDoc, doc:HaxeDoc, config:Dynamic ) : Void {
    
        // trace("found typedef " + _typedef.name + ' to ' + type_doc_to_string(_typedef.alias));

        //check if the type is found as a class, typedef or enum
        var _class = doc.classes.get(_typedef.alias.name);
        var _td = doc.enums.get(_typedef.alias.name);
        var _enum = doc.enums.get(_typedef.alias.name);

        if(_class != null) {
            //alias the class info
            doc.classes.set(_typedef.name, {
                name:_typedef.name,
                type_name:_typedef.type_name,
                type:'class',
                doc: _class.doc,
                meta: _typedef.meta,
                extend:_class.extend,
                implement:_class.implement, 
                members:_class.members,
                methods:_class.methods,
                properties:_class.properties, 
                ispublic:_typedef.ispublic
            });
        }
        
        if(_td != null) {
            trace('its a typedef! todo!');
        }
        
        if(_enum != null) {
            trace('its an enum! todo!');
        }
    }

    static function post_parse( doc:HaxeDoc, config:Dynamic ) : HaxeDoc {

        //for classes, if they inherit something, they should be merged in.
        //this happens first, because aliases to classes will get full details then

        for(_class in doc.classes) {
            inherit_fields(_class, doc, config);
        }

        //typedefs can be complete aliases to a different type, so we populate the aliases 
        //with the information from the target type, so that the documentation information is complete on that 
        //class without logic (i.e data)

        for(_typedef in doc.typedefs) {
            if(_typedef.alias != null) {
                    //copy the type and reinsert
                alias_fields(_typedef, doc, config);
                    //if the typedef is an alias, we remove this typedef out entirely, and place an instance
                    //of it's alias in the correct place, like if T aliases a _class_ T1, classes['T'] becomes a copy of T1
                doc.typedefs.remove(_typedef.name);
            }
        }

        return doc;

    } //post_parse

    static function pre_parse( root:Xml, config:Dynamic ) : HaxeDoc {

        var _class_list : Array<String> = [];
        var _typedef_list : Array<String> = [];
        var _enum_list : Array<String> = [];

        var _classes : Map<String, ClassDoc> = new Map<String,ClassDoc>();
        var _typedefs : Map<String, TypedefDoc> = new Map<String, TypedefDoc>();
        var _enums : Map<String, EnumDoc> = new Map<String, EnumDoc>();

        for(_class in root.elementsNamed('class')) {

            var _package = _class.get('path');
            
                //check that the class is in the allowed packages,
                //and if so add it to the list
            var _allowed = package_allowed(config, _package);

            if(_allowed) {
                    //store the class in the list of names
                _class_list.push( _package );
                    //finally store the ClassDoc in the list
                _classes.set( _package, parse_class( _class, config ) );
            }

        } //for each class      

        for(_typedef in root.elementsNamed('typedef')) {

            var _package = _typedef.get('path');

                //check that the class is in the allowed packages,
                //and if so add it to the list
            var _allowed = package_allowed(config, _package);

            if(_allowed) {
                    //store the class in the list of names
                _typedef_list.push( _package );
                    //finally store the Doc in the list
                _typedefs.set( _package, parse_typedef( _typedef, config ) );
            }

        } //for each typedef 

        for(_enum in root.elementsNamed('enum')) {

            var _package = _enum.get('path');

                //check that the class is in the allowed packages,
                //and if so add it to the list
            var _allowed = package_allowed(config, _package);

            if(_allowed) {
                    //store the class in the list of names
                _enum_list.push( _package );
                    //finally store the Doc in the list
                _enums.set( _package, parse_enum( _enum, config ));
            }

        } //for each enum

        return { 
            class_list :_class_list, 
            classes :_classes,

            typedef_list :_typedef_list,
            typedefs :_typedefs,

            enum_list :_enum_list,
            enums :_enums,

            types : new Map(),
            typelist : []
        };        

    } //pre_parse

    static function package_allowed(config:Dynamic, _package:String) {
        
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

        return _allowed;

    } //package_allowed

    static function parse_meta_for_item( _meta_tags:Iterator<Xml> ) {

        var _meta = new Map<String, MetaDoc>();

        if(_meta_tags != null) {
            for(_child in _meta_tags) {
                var _meta_elements = _child.elements();
                for(_meta_item in _meta_elements) {

                    var _meta_value = '';
                    var _value_node = _meta_item.elementsNamed("e");

                    if(_value_node.hasNext()) {
                        _meta_value = Std.string( _value_node.next().firstChild() );
                    }
                        //for now we have to remove the quotes from strings, 
                        //not sure if that's gonna cause possible headaches but 
                        //worth looking into

                    var _meta_name = Std.string(_meta_item.get('n'));
                    _meta.set( '@'+_meta_name, {
                        name : _meta_name, 
                        value : StringTools.replace(_meta_value, '"','')
                    });

                } //for meta in _meta_elements
            } //for child in meta_tags
        } //if meta tags != null

        return _meta;

    } //parse_meta_for_item

    static function parse_enum( _enum:Xml, config:Dynamic ) : EnumDoc {

        var _values : Array<EnumInfo> = [];
        var _meta_tags = _enum.elementsNamed('meta');
        
        var _isprivate : Bool = (_enum.get('private') != null);
        var _meta = parse_meta_for_item( _meta_tags );
        var _doc : String = '';

        for(_value in _enum.elements()) {
            if(_value.nodeName != 'meta' && _value.nodeName != 'haxe_doc') {

                var _value_doc = '';
                var _doc_root = _value.elementsNamed('haxe_doc');
                if(_doc_root != null) {
                    for(child in _doc_root) {
                        _value_doc = Std.string( child.firstChild() );
                        _value_doc = StringTools.replace(_value_doc,'\n','\\n');
                    }
                }

                _values.push( { name : _value.nodeName, doc: _value_doc } );
            }
        }

        var _doc_root = _enum.elementsNamed('haxe_doc');
        if(_doc_root != null) {
            for(child in _doc_root) {
                _doc = Std.string( child.firstChild() );
                _doc = StringTools.replace(_doc,'\n','\\n');
            }
        }

        _values.sort(sort);

        return {
            name : _enum.get('path'),
            type_name : _enum.get('path').split('.').pop(),
            type : 'enum',
            ispublic : !_isprivate,
            doc : _doc,
            meta : _meta,
            values : _values,
        };

    } //parse_enum

    static function parse_typedef( _typedef:Xml, config:Dynamic ) : TypedefDoc {

        var _members = [];
        var _meta_tags = _typedef.elementsNamed('meta');
        var _isprivate : Bool = (_typedef.get('private') != null);

        var _meta = parse_meta_for_item( _meta_tags );
        var _doc = '';
        var _alias : TypeDoc = null;
            
            //for each member, parse it and store it
        for(_item in _typedef.elements()) {
            if(_item.nodeName == 'a') {
                for(_member in _item.elements()) {
                    var _parsed_member = parse_member(_member, config);
                    _parsed_member.ispublic = true;
                    
                        //if the member is a Null<Type> it's optional
                    if(_parsed_member.type.name == 'Null') {
                            //the type becomes it's params[0]
                        _parsed_member.type = _parsed_member.type.params[0];
                        _parsed_member.optional = true;
                    }

                    _members.push( _parsed_member );
                }
            } else if(_item.nodeName == 'c') {
                _alias = parse_type(_item);
            }
        }

        var _doc_root = _typedef.elementsNamed('haxe_doc');
        if(_doc_root != null) {
            for(child in _doc_root) {
                _doc = Std.string( child.firstChild() );
                _doc = StringTools.replace(_doc,'\n','\\n');
            }
        }

        _members.sort(sort);

        return {
            name : _typedef.get('path'),
            type_name : _typedef.get('path').split('.').pop(),
            type : 'typedef',

            ispublic : !_isprivate,
            doc : _doc,
            alias : _alias,
            meta : _meta,
            members : _members
        };

    } //parse_typedef

    public static function sort(a:Dynamic,b:Dynamic) {
        if(Std.string(a.name).toLowerCase() < Std.string(b.name).toLowerCase()) return -1;
        if(Std.string(a.name).toLowerCase() >= Std.string(b.name).toLowerCase()) return 1;
        return 0;
    }

    public static function sort_plain(a:String,b:String) {
        if(Std.string(a).toLowerCase() < Std.string(b).toLowerCase()) return -1;
        if(Std.string(a).toLowerCase() >= Std.string(b).toLowerCase()) return 1;
        return 0;
    }

    static function parse_class( _class:Xml, config:Dynamic ) : ClassDoc {

        var _members = [];
        var _methods = [];
        var _properties = [];
        var _unknowns = new Map<String, UnknownDoc>();        
        var _extends = new Array<TypeDoc>();
        var _implements = new Array<TypeDoc>();

            //for each member, parse it and store it
        for(_member in _class.elements()) {

                //for reusing the name
            var _member_name = _member.nodeName;

            if(_member_name == 'extends') {
                
                _extends.push( parse_type(_member) );
                
            } else if(_member_name == 'implements') {

                _implements.push( parse_type(_member) );

            } else {

                //we use these to determine the type
                var _set = _member.get('set');
                var _get = _member.get('get');
                var _is_method = _member.elementsNamed('f').hasNext(); 

                    //without any set/get, it is a regular variable
                if(_set == null && _get == null && _member_name != 'haxe_doc' && _member_name != 'meta') {
                        //store in the member list
                    _members.push( parse_member(_member, config) );
                } else 
                    //with "method" it is a function
                if(_is_method) {
                        //store in the method list
                    _methods.push( parse_method(_member, config) );
                } else 
                    //this is a property 
                if( _set == 'accessor' || _get == 'accessor' || _get == 'null' || _set == 'null') {
                        // store in the properties list
                    _properties.push( parse_property(_member, config) );
                } 
                    //any unknowns 
                else {
                    // _unknowns.set( _member_name, parse_unknown(_member, config) );
                }

            } //not specifically parsed            

        } //for each element in the class

        //sort 
        _members.sort(sort);
        _methods.sort(sort);
        _properties.sort(sort);

        return { 
            name:_class.get('path'), 
            type_name:_class.get('path').split('.').pop(),
            type:'class',
            doc: parse_doc(_class, config),
            meta: parse_meta_for_item( _class.elementsNamed('meta') ),
            extend:_extends, 
            implement:_implements, 
            members:_members,
            methods:_methods,
            properties:_properties, 
            ispublic:!(_class.get('private') != null) 
        };

    } //parse_class

    static function type_doc_to_string(t:TypeDoc) {

        var _postfix = '';
        if(!t.func) {
            _postfix = type_param_to_string(t.params);
        }
        return t.name + _postfix;
    }

    static function type_param_to_string( param:Array<TypeDoc> ) {

        if(param.length == 0) {
            return '';
        }

        var s = '<';

        for(_p in param) {
            s += _p.name + ',';
        }

        s = s.substring(0, s.length-1);

        s += '>';

        return s;
    }

    static function parse_doc( _member:Xml, config:Dynamic ) : String {

        var _doc = '';
        var _doc_root = _member.elementsNamed('haxe_doc');
        if(_doc_root != null) {
            for(child in _doc_root) {
                _doc = Std.string( child.firstChild() );
                _doc = StringTools.replace(_doc,'\n','\\n');
            }
        }

        return _doc;

    } //parse_doc

    static function parse_member( _member:Xml, config:Dynamic ) : MemberDoc {

            //parse the specific meta flags
        var _type = parse_type(_member.firstElement());
            //get the signature for display convenience,
            //but if it's a function declaration type, it's already in the name
        var _signature_postfix = _type.func ? '' : type_param_to_string(_type.params);
        var _signature : String = _member.nodeName + ' : ' + type_doc_to_string(_type);

        return { 
            ispublic : (_member.get('public') != null),
            isstatic : (_member.get('static') != null),
            isinline : (_member.get('get') == 'inline'),

            optional : false,
            inherited : false,
            inherit_source : '',

            doc : parse_doc( _member, config ),
            meta : parse_meta_for_item( _member.elementsNamed('meta') ),
            signature : _signature,
            type : _type,
            name : _member.nodeName
        };

    } //parse_member

    static function parse_type( _node:Xml ) : TypeDoc {
            
        //type
        var _type_name = 'Dynamic';
        var _func = false;

        if(_node.nodeName != 'f') {
            if(_node.exists('path')) {
                _type_name = _node.get('path');
            }
        } else {//f
            _type_name = parse_internal_function_type(_node);
            _func = true;
        }

        return {
            name : _type_name,
            params : parse_type_params(_node),
            func : _func
        };

    } //parse_type

    static function parse_method( _member:Xml, config:Dynamic ) : MethodDoc {

        var _signature : String = '';
        var _args : Array<Argument> = [];

            //fetch from a helper function for clarity.
        var _finfo = parse_function_node( _member );

            //Append a easier on the eyes function return type for the signature
        var _rtype = type_doc_to_string(_finfo.return_type);
            //constructor has no return type
        if(_finfo.name == 'new') {
            _rtype = '';
        }
                    
        var _shortargs : Array<String> = [];
        for(_arg in _finfo.args) { 
            var _value = '';
            if(_arg.value != '' && _arg.value != 'null' && _arg.value != null) {
                _value = '='+_arg.value;
            }
            _shortargs.push( _arg.name + ':' + type_doc_to_string(_arg.type) + _value); 
        }

            //Store the final values
        var _params = '';

        _signature = _finfo.name + _params + '(' + _shortargs.join(', ') + ') : ' +  _rtype;
        _args = _finfo.args;

        return {

            name : _member.nodeName,
            inherited : false,
            inherit_source : '',

            ispublic : (_member.get('public') != null),
            isstatic : (_member.get('static') != null),
            isinline : (_member.get('get') == 'inline'),

            doc : parse_doc(_member, config),
            meta : parse_meta_for_item(_member.elementsNamed('meta')),
            
            args : _args,
            signature : _signature,
            return_type : _finfo.return_type
            
        };

    } //parse_method

    static function parse_property( _member:Xml, config:Dynamic ) : PropertyDoc {

        //default to write/read
        var _isread : Bool = true;
        var _iswrite : Bool = true;
        
        var _type = parse_type(_member.firstElement());

            //we use these to determine 
            //the property status
        var _set = _member.get('set');
        var _get = _member.get('get');
        var _access = 'read/write';

            //What type of access does it allow?
        if((_get == 'never' || _get == 'null') && (_set == 'accessor' || _set == 'inline') ) {
            _access = 'write only';
            _isread = false;
        } else if( (_set == 'never' || _set == 'null') && (_get == 'accessor' || _get == 'inline') ) {
            _access = 'read only';
            _iswrite = false;
        } else {
            _access = 'no read/write (${_get},${_set})';
            _isread = false; _iswrite = false;
        }

        var _signature_postfix = _type.func ? '' : type_param_to_string(_type.params);
        var _signature : String = _member.nodeName + ' : ' + _type.name;

        return {
            name : _member.nodeName,
            access : _access,
            type : _type,
            signature : _signature,

            isread : _isread,
            iswrite : _iswrite,
            isstatic : (_member.get('static') != null),
            ispublic : (_member.get('public') != null),

            inherited : false,
            inherit_source : '',

            doc : parse_doc(_member, config),
            meta :  parse_meta_for_item( _member.elementsNamed('meta') )
            
        };

    } //parse_property

    static function parse_unknown( _member:Xml, config:Dynamic ) : UnknownDoc {
        return { name:_member.nodeName, node:_member };
    } //parse_unknown


//internal functions
    static function parse_internal_function_type(_f:Xml){
            
        var _final = '';

            //Just push them into a list with ->
        for(_arg in _f.elements()) {
            var _type = _arg.get('path');
            if(_type == 'null' || _type == null) {
                _type = 'Dynamic';
            }

            _final += _type + '->';
        }

            //And remove the final -> (... I know.)
        _final = _final.substr(0,_final.length-2);

        return _final;

    } //parse_internal_function_type


    static function parse_type_params( _type_node:Xml ) : Array<TypeDoc> {

            //Type Parameter types have child elements
        var _type_params = _type_node.elements();
        var _has_type_params = _type_params.hasNext();

        var list = [];

        if(_has_type_params) {
                //for each child element, append it
            for(_type_param in _type_params) {

                var _node = parse_type(_type_param);
                list.push(_node);
                
            } //for each type param
        } //_has_type_params

        return list;

    } //params

    static function parse_function_node( _member:Xml ) : InternalMethodInfo {
                
        var _args_final : Array<Argument>= [];

        //the first element has the arguments in
        var _node = _member.firstElement();
            //parse the argument types using the type parser
        var args : TypeDoc = parse_type(_node);
            //get the return type from the last arg, removing it
        var _return_type = args.params.pop();

            //now fetch the names and values of the args
        var _arg_v : String = _node.get('v');
        var _arg_n : String = _node.get('a');

        var _arg_values = [];

        if(_arg_v != null) {
            
            var _av = _arg_v.split(':');
            for(_avalue in _av) {
                _arg_values.push(_avalue);
            }
        }

        var _arg_names = (_arg_n == null || _arg_n.length == 0) ? [] : _arg_n.split(':');
        
        var _index = 0;
        for(_a in _arg_names) {

            var _val = _arg_values[_index];

            if(args.params[0].name == 'Float') {
                if(_val != null && _val.length > 0) { 
                    _val = StringTools.replace(_val,'f','');
                }
            }

                //store for use in results
            _args_final.push({ 
                name:_arg_names[_index], 
                type: args.params[_index], 
                value: _val
            });

            _index++;
        }

            //parse function type params,
            //these member type params aren't like the rest
        var _params = [];
        if(_member.exists('params')) {
            var _typeparams = _member.get('params');
            _params = _typeparams.split(':');
        }

        return {
            name : _member.nodeName,
            args : _args_final,
            params : _params,
            return_type : _return_type
        };

    } //parse_function_node



} //HaxeXMLDocParser