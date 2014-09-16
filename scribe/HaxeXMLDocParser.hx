
package scribe;

import haxe.rtti.CType;
import haxe.rtti.CType.Abstractdef;
import haxe.rtti.CType.Classdef;
import haxe.rtti.CType.ClassField;
import haxe.rtti.CType.Enumdef;
import haxe.rtti.CType.MetaData;
import haxe.rtti.CType.PathParams;
import haxe.rtti.CType.Platforms;
import haxe.rtti.CType.Typedef;
import haxe.rtti.CType.TypeParams;
import haxe.rtti.CType.TypeRoot;
import haxe.rtti.CType.TypeTree;

import scribe.ScribeTypes;

class HaxeXMLDocParser {

    public static var result : HaxeDoc;
    public static var unfiltered : HaxeDoc;

    static var allowed_packages : Array<String>;
    static var allowed_root_types : Array<String>;

    public static function parse( root:Xml, config:Dynamic, platform:String='cpp' ) : HaxeDoc {

        result = {
            names : [],
            package_roots : [],
            packages : new Map(),
            classes : new Map(),
            typedefs : new Map(),
            enums : new Map(),
            abstracts : new Map(),
        };

        unfiltered = {
            names : [],
            package_roots : [],
            packages : new Map(),
            classes : new Map(),
            typedefs : new Map(),
            enums : new Map(),
            abstracts : new Map(),
        };

        _verbose('parsing ...');

        pre_parse(root, config, platform);
        post_parse(config, platform);

        return result;

    } //parse

    static function pre_parse( root:Xml, config:Dynamic, platform:String ) : HaxeDoc {

        allowed_packages = cast config.allowed_packages;
        allowed_root_types = cast config.allowed_from_empty_package;

        if(allowed_root_types == null) {
            allowed_root_types = [];
        }

            //add the empty package for types that are empty
        var _empty_package_doc = {
            name : '_empty_',
            full : '_empty_',
            isPrivate : false,
            packages : [],
            classes : [],
            typedefs : [],
            enums : [],
            abstracts : []
        } //_empty_package_doc

        result.packages.set('_empty_', _empty_package_doc);
        unfiltered.packages.set('_empty_', _empty_package_doc);

        var xml = new haxe.rtti.XmlParser();

        xml.process( root, platform );

        for(entry in xml.root) {

            switch(entry) {
                default:
                case TPackage( name, full, subs ):
                    unfiltered.package_roots.push(name);
                    if(allowed_packages.indexOf(name) != -1) {
                        result.package_roots.push(name);
                    }

            } //switch

            parse_type(entry);

        } //each entry

        return result;

    } //pre_parse

    static function dosort(a:String,b:String) {
        if(a < b) return -1;
        if(a > b) return 1;
        return 0;
    }

    static function field_sort(a:ClassFieldDoc,b:ClassFieldDoc) {
        if(a.name < b.name) return -1;
        if(a.name > b.name) return 1;
        return 0;
    }

    static function post_parse(config:Dynamic, platform:String ) {

            //merge inherited fields into child fields
        for(_class in result.classes) {
            inherit_fields(_class, config);
        }

        for(_typedef in result.typedefs) {
            result.names.push(_typedef.path);
        }
        for(_class in result.classes) {
            result.names.push(_class.path);
        }
        for(_enum in result.enums) {
            result.names.push(_enum.path);
        }
        for(_abstract in result.abstracts) {
            result.names.push(_abstract.path);
        }

        for(_package in result.packages) {
            _package.abstracts.sort(dosort);
            _package.typedefs.sort(dosort);
            _package.classes.sort(dosort);
            _package.enums.sort(dosort);
            _package.packages.sort(dosort);
        }

        result.names.sort(dosort);

        for(_class in result.classes) {
            _class.members.sort(field_sort);
            _class.methods.sort(field_sort);
            _class.properties.sort(field_sort);
        }

    } //post_parse

    static function parse_type(type:TypeTree, _depth:Int = 0) {

        switch(type) {

            case TPackage( name, full, subs ):
                parse_package( name, full, subs, _depth );

            case TClassdecl( _class ):
                parse_class( _class, false, _depth );

            case TTypedecl( _type ):
                parse_typedef( _type, _depth );

            case TEnumdecl( _enum ):
                parse_enum( _enum, _depth );

            case TAbstractdecl( _abstract ):
                parse_abstract( _abstract, _depth );

            default:

        } //switch

    } //parse_type

    static function parse_package( name:String, full:String, subs:TypeRoot, _depth:Int = 0 ) {

        _verbose( tabs(_depth) + 'package ' + name + ' / ' + full);

            //private/internal packages have a _ in front of their last type name
        var _isPrivate = full.split('.').pop().charAt(0) == '_';

            //packages, classes etc will add themselves to this object
            //when they are being parsed, so empty is all for now
        var packagedoc = {
            name : name,
            full : full,
            isPrivate : _isPrivate,
            packages : [],
            classes : [],
            typedefs : [],
            enums : [],
            abstracts : []
        }

            //store it in the full packages root map
        unfiltered.packages.set( full, packagedoc );
        if(in_allowed_package(full) || allowed_packages.indexOf(name) != -1) {
            result.packages.set( full, packagedoc );
        }

            //add it to the parent package list of package names
        var parent_name = get_package_root(full);
        var parent_package = unfiltered.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.packages.push(full);
        }

            //keep parsing it's sub items
        for(entry in subs) {
            parse_type(entry, _depth+1);
        }

    } //parse_package

        //internal means we are parsing a class for a type, not parsing the type itself
    static function parse_class( _class:Classdef, _internal:Bool, _depth:Int = 0 ) : ClassDoc {

        _verbose(tabs(_depth) + 'class ' + _class.path + ' / ' + _class.platforms);

            //add it to the parent package list of class names
        var parent_name = get_package_root(_class.path);
        var parent_package = unfiltered.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.classes.push(_class.path);
        }

            //add to the root package if it's an empty package
        if(in_empty_package(_class.path)) {
            unfiltered.packages.get('_empty_').classes.push(_class.path);
            if(in_allowed_types(_class.path)) {
                trace('adding ${_class.path} to _empty_');
                result.packages.get('_empty_').classes.push(_class.path);
            }
        }

        var classdoc = {

            doc : _class.doc,
            path : _class.path,
            name : _class.path.split('.').pop(),
            type : 'class',
            module : _class.module,
            file : _class.file,

            meta : _class.meta,
            params : _class.params,
            platforms : Lambda.array(_class.platforms),

            interfaces : get_pathparams_list(_class.interfaces),
            superClass : get_pathparams(_class.superClass),
            tdynamic : _class.tdynamic,

            isExtern : _class.isExtern,
            isPrivate : _class.isPrivate,
            isInterface : _class.isInterface,

            members    : parse_class_members(_class.fields, _class.statics),
            methods    : parse_class_methods(_class.fields, _class.statics),
            properties : parse_class_properties(_class.fields)

        }

        if(!_internal) {
                //store in the full classes root map
            unfiltered.classes.set( _class.path, classdoc );

            if(in_allowed_package(_class.path) || in_allowed_types(_class.path)) {
                result.classes.set( _class.path, classdoc );
            }
        }

        return classdoc;

    } //parse_class

    static function parse_typedef( _typedef:Typedef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'typedef ' + _typedef.path);

            //add it to the parent package list of typedef names
        var parent_name = get_package_root(_typedef.path);
        var parent_package = unfiltered.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.typedefs.push(_typedef.path);
        }

            //add to the root package if it's an empty package
        if(in_empty_package(_typedef.path)) {
            unfiltered.packages.get('_empty_').typedefs.push(_typedef.path);
            if(in_allowed_types(_typedef.path)) {
                result.packages.get('_empty_').typedefs.push(_typedef.path);
            }
        }

        var _typemap = new Map();

        for(_tname in _typedef.types.keys()) {
            var _current = _typedef.types.get(_tname);
            _typemap.set(_tname, parse_ctype(_current));
        }

        var _type_info = parse_ctype(_typedef.type);

        var typedefdoc = {

            doc : _typedef.doc,
            path : _typedef.path,
            name : _typedef.path.split('.').pop(),
            type : 'typedef',
            module : _typedef.module,
            file : _typedef.file,

            meta : _typedef.meta,
            params : _typedef.params,
            platforms : Lambda.array(_typedef.platforms),

            isPrivate : _typedef.isPrivate,

            members : (_type_info == null) ? [] : _type_info.fields,
            types : _typemap

        } //typedefdoc

            //store in the full typedefs root map
        unfiltered.typedefs.set( _typedef.path, typedefdoc );
        if(in_allowed_package(_typedef.path)) {
            result.typedefs.set( _typedef.path, typedefdoc );
        }

    } //parse_typedef

    static function parse_enum( _enum:Enumdef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'enum ' + _enum.path);

            //add it to the parent package list of enums names
        var parent_name = get_package_root(_enum.path);
        var parent_package = unfiltered.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.enums.push(_enum.path);
        }
            //add to the root package if it's an empty package
        if(in_empty_package(_enum.path)) {
            unfiltered.packages.get('_empty_').enums.push(_enum.path);
            if(in_allowed_types(_enum.path)) {
                result.packages.get('_empty_').enums.push(_enum.path);
            }
        }

        var _constructors = [];

        if(_enum.constructors.length > 0) {

            for(_c in _enum.constructors) {

                var _args = [];

                if(_c.args != null && _c.args.length > 0) {
                    for(_arg in _c.args) {
                        _args.push({
                            name : _arg.name,
                            t : parse_ctype(_arg.t),
                            opt : _arg.opt
                        });
                    } //each arg
                } //args ! null && > 0

                _constructors.push({
                    platforms : Lambda.array(_c.platforms),
                    name : _c.name,
                    meta : _c.meta,
                    doc : _c.doc,
                    args : _args
                });

            } //each constructor

        } //_constructors.length > 0

        var enumdoc = {

            doc : _enum.doc,
            path : _enum.path,
            name : _enum.path.split('.').pop(),
            type : 'enum',
            module : _enum.module,
            file : _enum.file,

            meta : _enum.meta,
            params : _enum.params,
            platforms : Lambda.array(_enum.platforms),

            isPrivate : _enum.isPrivate,
            isExtern : _enum.isExtern,

            constructors : _constructors
        }

            //store in the full enums root map
        unfiltered.enums.set( _enum.path, enumdoc );
        if(in_allowed_package(_enum.path)) {
            result.enums.set( _enum.path, enumdoc );
        }

    } //parse_enum

    static function parse_abstract( _abstract:Abstractdef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'abstract ' + _abstract.path);

            //add it to the parent package list of abstract names
        var parent_name = get_package_root(_abstract.path);
        var parent_package = unfiltered.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.abstracts.push(_abstract.path);
        }
            //add to the root package if it's an empty package
        if(in_empty_package(_abstract.path)) {
            unfiltered.packages.get('_empty_').abstracts.push(_abstract.path);
            if(in_allowed_types(_abstract.path)) {
                result.packages.get('_empty_').abstracts.push(_abstract.path);
            }
        }

        var to : Array<AbstractNodeDoc>;
        var from : Array<AbstractNodeDoc>;

        var _to = [];
        var _from = [];

        if(_abstract.to.length > 0) {
            for(_dest in _abstract.to) {
                _to.push({
                    t : parse_ctype(_dest.t),
                    field : _dest.field,
                });
            }
        } //to.length > 0

        if(_abstract.from.length > 0) {
            for(_source in _abstract.from) {
                _from.push({
                    t : parse_ctype(_source.t),
                    field : _source.field,
                });
            } //each from
        } //from.length > 0

        var abstractdoc = {

            doc : _abstract.doc,
            path : _abstract.path,
            name : _abstract.path.split('.').pop(),
            type : 'abstract',
            module : _abstract.module,
            file : _abstract.file,

            meta : _abstract.meta,
            params : _abstract.params,
            platforms : Lambda.array(_abstract.platforms),

            athis : parse_ctype(_abstract.athis),
            impl : (_abstract.impl == null) ? null : parse_class(_abstract.impl, true, _depth+1),
            to : _to,
            from : _from

        }

            //store in the full abstracts root map
        unfiltered.abstracts.set( _abstract.path, abstractdoc );
        if(in_allowed_package(_abstract.path)) {
            result.abstracts.set( _abstract.path, abstractdoc );
        }

    } //parse_abstract

    static function parse_class_members( fields : List<ClassField>, ?statics:List<ClassField>=null ) : Array<ClassFieldDoc> {

        var _res = [];

        if(fields.length > 0) {
            for(_field in fields) {

                var get_rights = parse_rights(_field.get);
                var set_rights = parse_rights(_field.set);

                if(get_rights != 'normal') {
                    continue;
                }
                if(set_rights != 'normal') {
                    continue;
                }

                var _fielddoc = {

                    doc : _field.doc,
                    name : _field.name,
                    type : parse_ctype(_field.type),

                    inherited : false,
                    inherit_source : null,

                    line : _field.line,
                    meta : _field.meta,
                    params : _field.params,
                    platforms : Lambda.array(_field.platforms),

                    get : get_rights,
                    set : set_rights,

                    isPublic : _field.isPublic,
                    isOverride : _field.isOverride,
                    isStatic : false
                }

                _res.push(_fielddoc);

            } //fields
        } //length > 0

        if(statics != null) {
            if(statics.length > 0) {
                for(_static in statics) {

                    var get_rights = parse_rights(_static.get);
                    var set_rights = parse_rights(_static.set);

                    if(get_rights != 'normal') {
                        continue;
                    }
                    if(set_rights != 'normal') {
                        continue;
                    }

                    var _staticdoc = {

                        doc : _static.doc,
                        name : _static.name,
                        type : parse_ctype(_static.type),

                        inherited : false,
                        inherit_source : null,

                        line : _static.line,
                        meta : _static.meta,
                        params : _static.params,
                        platforms : Lambda.array(_static.platforms),

                        get : get_rights,
                        set : set_rights,

                        isPublic : _static.isPublic,
                        isOverride : _static.isOverride,
                        isStatic : true
                    }

                    _res.push(_staticdoc);

                } //statics
            } //length > 0
        } //statics != null

        return _res;

    } //parse_class_members

    static function parse_class_methods( fields : List<ClassField>, ?statics:List<ClassField>=null ) : Array<ClassFieldDoc> {

        var _res = [];

        if(fields.length > 0) {
            for(_field in fields) {

                var set_rights = parse_rights(_field.set);

                if(set_rights != 'method') {
                    continue;
                }

                var _fielddoc = {

                    doc : _field.doc,
                    name : _field.name,
                    type : parse_ctype(_field.type),

                    inherited : false,
                    inherit_source : null,

                    line : _field.line,
                    meta : _field.meta,
                    params : _field.params,
                    platforms : Lambda.array(_field.platforms),

                    get : parse_rights(_field.get),
                    set : set_rights,

                    isPublic : _field.isPublic,
                    isOverride : _field.isOverride,
                    isStatic : false
                }

                _res.push(_fielddoc);

            } //fields
        } //length > 0

        if(statics != null) {
            if(statics.length > 0) {
                for(_static in statics) {

                    var set_rights = parse_rights(_static.set);

                    if(set_rights != 'method') {
                        continue;
                    }

                    var _staticdoc = {

                        doc : _static.doc,
                        name : _static.name,
                        type : parse_ctype(_static.type),

                        inherited : false,
                        inherit_source : null,

                        line : _static.line,
                        meta : _static.meta,
                        params : _static.params,
                        platforms : Lambda.array(_static.platforms),

                        get : parse_rights(_static.get),
                        set : set_rights,

                        isPublic : _static.isPublic,
                        isOverride : _static.isOverride,
                        isStatic : true
                    }

                    _res.push(_staticdoc);

                } //statics
            } //length > 0
        } //statics != null

        return _res;

    } //parse_class_members

    static function parse_class_properties( fields : List<ClassField> ) : Array<ClassFieldDoc> {

        var _res = [];

        if(fields.length > 0) {
            for(_field in fields) {

                var get_rights = parse_rights(_field.get);
                var set_rights = parse_rights(_field.set);

                if(set_rights == 'method') {
                    continue;
                }

                if(get_rights == 'normal' && set_rights == 'normal') {
                    continue;
                }

                var _fielddoc = {

                    doc : _field.doc,
                    name : _field.name,
                    type : parse_ctype(_field.type),

                    inherited : false,
                    inherit_source : null,

                    line : _field.line,
                    meta : _field.meta,
                    params : _field.params,
                    platforms : Lambda.array(_field.platforms),

                    get : get_rights,
                    set : set_rights,

                    isPublic : _field.isPublic,
                    isOverride : _field.isOverride,
                    isStatic : false
                }

                _res.push(_fielddoc);

            } //fields
        } //length > 0

        return _res;

    } //parse_class_properties


    static function parse_rights( _rights:Rights ) : String {

        switch(_rights) {

            case Rights.RNormal:
                return 'normal';
            case Rights.RNo:
                return 'no';
            case Rights.RMethod:
                return 'method';
            case Rights.RDynamic:
                return 'dynamic';
            case Rights.RCall( m ) :
                return m;
            default:

        } //switch rights

        return '';

    } //parse_rights

    static function parse_ctype( _type:CType ) : CTypeDoc {

        if(_type == null) {
            return null;
        }

        switch(_type) {
            case CType.CAbstract( name, params ):
                return parse_cabstract(name,params);
            case CType.CClass( name, params ):
                return parse_cclass(name,params);
            case CType.CEnum( name, params ):
                return parse_cenum(name,params);
            case CType.CTypedef( name, params ):
                return parse_ctypedef(name,params);

            case CType.CAnonymous( fields ):
                return parse_canonymous( fields );
            case CType.CDynamic( t ):
                return parse_cdynamic( t );
            case CType.CFunction( args, ret ):
                return parse_cfunction( args, ret );
            case CType.CUnknown: //:todo:?
                return parse_cunknown( _type );

            default:
        }

        return null;

    } //parse_ctype

    static function parse_ctype_list( list:List<CType> ) : Array<CTypeDoc> {

        if(list.length == 0) {
            return [];
        }

        var _res = [];

            for(type in list) {
                _res.push( parse_ctype(type) );
            }

        return _res;
    } //parse_ctype_list


    static function parse_cabstract( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CTypeDoc {
        return {
            type : 'CAbstract',
            name : name,
            params : parse_ctype_list(params)
        };
    } //parse_cabstract

    static function parse_cclass( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CTypeDoc {
        return {
            type:'CClass',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_cclass

    static function parse_cenum( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CTypeDoc {
        return {
            type:'CEnum',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_cenum

    static function parse_ctypedef( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CTypeDoc {
        return {
            type:'CTypedef',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_ctypedef

    static function parse_canonymous( fields : List<haxe.rtti.ClassField> ) : CTypeDoc {
        return {
            type:'CAnonymous',
            fields : parse_class_members(fields)
        };
    } //parse_canonymous

    static function parse_cfunction( args : List<haxe.rtti.FunctionArgument> , ret : CType ) : CTypeDoc {

        var _args = [];

        if(args.length > 0) {
            for(arg in args) {
                _args.push({
                    name : arg.name,
                    opt : arg.opt,
                    t : parse_ctype(arg.t),
                    value : arg.value
                });
            }
        }

        return {
            type:'CFunction',
            args: _args,
            return_type : parse_ctype(ret)
        };

    } //parse_cfunction

    static function parse_cunknown( _type:CType ) : CTypeDoc {

        return {
            type:'CUnknown'
        };

    } //parse_cunknown

    static function parse_cdynamic(  ?t : CType ) : CTypeDoc {

        return {
            type : 'CDynamic'
        }

    } //parse_cdynamic


    static function inherit_fields(_class:ClassDoc, config:Dynamic) {

        if(_class.superClass == null) return;

        var _parent_type = _class.superClass.path;
            //obtain its info
        var _parent = result.classes.get(_parent_type);

            //classes from the std lib and
            //excluded packages don't exist here
            //so we skip them entirely
        if(_parent == null) {
            return;
        }

            //now, for each method, member and property
            //we want to selectively merge things down into
            //this class, if the parent has a method this
            //class does not, we push it in here, and flag it inherited.
            //if this class has it, we just flagged it as inherited and set the source.
            //This happens recursively, so that parents at the top tier are set as the source
        if(_parent.superClass != null) {

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
                            m.inherit_source = _parent.path;
                            return true;
                        }
                        return false;
                    });
                } else {
                        //if it doesn't exist in the child, we need to add it
                    var _cm = _clone_classfield(_method);
                        _cm.inherited = true;
                        _cm.inherit_source = _parent.path;
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
                            m.inherit_source = _parent.path;
                            return true;
                        }
                        return false;
                    });
                } else {
                        //if it doesn't exist in the child, we need to add it
                    var _cm = _clone_classfield(_member);
                        _cm.inherited = true;
                        _cm.inherit_source = _parent.path;
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
                            m.inherit_source = _parent.path;
                            return true;
                        }
                        return false;
                    });
                } else {
                        //if it doesn't exist in the child, we need to add it
                    var _cm = _clone_classfield(_property);
                        _cm.inherited = true;
                        _cm.inherit_source = _parent.path;
                    _class.properties.push(_cm);
                }
            } //for each property

        } else {
            inherit_fields(_parent, config);
        }

    } //inherit_fields

    static function _clone_classfield(_field:ClassFieldDoc) : ClassFieldDoc {
        return {
            isPublic : _field.isPublic,
            isStatic : _field.isStatic,
            isOverride : _field.isOverride,

            inherited : _field.inherited,
            inherit_source : _field.inherit_source,

            doc : _field.doc,
            type : _field.type,
            params : _field.params,
            set : _field.set,
            get : _field.get,
            platforms : _field.platforms,
            line : _field.line,
            meta : _field.meta,
            name : _field.name
        };
    } //_clone_method

//Helpers

    static function in_empty_package( _path:String ) : Bool {

        if(_path.indexOf('.') == -1) {
            return true;
        }

        return false;

    } //in_empty_package

    static function in_allowed_types( _path:String ) : Bool {

        if(in_empty_package(_path)) {
            for(_type in allowed_root_types) {
                if(_path == _type) {
                    return true;
                }
            }
        } //in_empty_package

        return false;

    } //in_allowed_types

    static function in_allowed_package( _path:String ) : Bool {
        var _count = 0;

            allowed_packages.map(function(_p:String){
                if(_path.indexOf('${_p}.') != -1) {
                    _count++;
                }
            });

        return _count > 0;

    } //in_allowed_package

    static function get_pathparams_list( _l : List<PathParams> ) : Array<PathParamDoc> {
        var _res = [];
            for(item in _l) {
                var _item_p = get_pathparams(item);
                if(_item_p != null) {
                    _res.push(_item_p);
                }
            }
        return _res;
    } //get_pathparams_list

        /** Converts a PathParams to digestable format for json (List doesn't seem to work for JSON) */
    static function get_pathparams( _p : PathParams ) : PathParamDoc {
        if(_p == null) return null;
        return {
            path : _p.path,
            params : Lambda.array(_p.params)
        }
    } //get_pathparams

        /** Takes a package like my.package.Class and returns my.package */
    static function get_package_root( _path:String ) : String {

        var _list = _path.split('.');
            _list.pop();
        return _list.join('.');

    } //get_package_root

    static function tabs(d:Int) {
        return StringTools.rpad('',' ',d*2);
    } //tabs

    static function _verbose(v:Dynamic) {
        trace(v);
    } //_verbose

} //HaxeXMLDocParser