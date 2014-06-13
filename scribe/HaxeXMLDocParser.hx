
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


typedef PackageDoc = {

        /** The name of this package */
    var name : String;
        /** The full package path name */
    var full : String;
        /** If this is an internal package ( like for a generated my.package._AbstractType ) */
    var isPrivate : Bool;

        /** The list of sub packages, for fetching from doc.packages */
    var packages : Array<String>;
        /** The list of classes names in this package, for fetching from doc.classes */
    var classes : Array<String>;
        /** The list of typedef names in this package, for fetching from doc.typedefs */
    var typedefs : Array<String>;
        /** The list of enum names in this package, for fetching from doc.enums */
    var enums : Array<String>;
        /** The list of abstract names in this package, for fetching from doc.abstracts */
    var abstracts : Array<String>;

} //PackageDoc

    //helper for PathParams
typedef PathParamDoc = {

    var path : String;
    var params : Array<CType>;

} //PathParamDoc

typedef ClassDoc = {

        /** The doc parsed from the class declaration, if any */
    var doc : String;
        /** The full class path including package */
    var path : String;
        /** The module (file) in which this definition originated, null if standalone */
    var module : String;
        /** The source file on disk */
    var file : String;

        /** The meta data attached to this class, if any */
    var meta : MetaData;
        /** The class type parameters, if any */
    var params : TypeParams;
        /** The list of platforms this was generated for, if any */
    var platforms : Array<String>;

        /** The parent super class */
    var superClass : PathParamDoc;
        /** The interfaces this class implements if any */
    var interfaces : Array<PathParamDoc>;
        /** Not sure what this is yet */
    var tdynamic : Null<CType>;

        /** If this is an external class */
    var isExtern : Bool;
        /** If this is a private class */
    var isPrivate : Bool;
        /** If this is an interface declaration */
    var isInterface : Bool;

        /** The static fields of this class */
    var statics : Array<ClassFieldDoc>;
        /** The fields of this class, like members, methods */
    var fields : Array<ClassFieldDoc>;

} //ClassDoc

typedef TypedefDoc = {

    var doc : String;

    var path : String;

    var file : Null<String>;

    var module : String;

    var types : Map<String, Dynamic>;

    var isPrivate : Bool;
        /** The meta data attached to this typedef, if any */
    var meta : MetaData;
        /** The typedef type parameters, if any */
    var params : TypeParams;
        /** The list of platforms this was generated for, if any */
    var platforms : Array<String>;

    var type : Dynamic;

} //TypedefDoc

typedef EnumArgDoc = {
    var name : String;
    var t : Dynamic;
    var opt : Bool;
}

typedef EnumFieldDoc = {
    var platforms : Array<String>;
    var name : String;
    var meta : MetaData;
    var doc : String;
    var args : Array<EnumArgDoc>;
}

typedef EnumDoc = {

    var doc : String;

    var path : String;

    var file : Null<String>;

    var module : String;

    var isExtern : Bool;
    var isPrivate : Bool;
        /** The meta data attached to this typedef, if any */
    var meta : MetaData;
        /** The typedef type parameters, if any */
    var params : TypeParams;
        /** The list of platforms this was generated for, if any */
    var platforms : Array<String>;

    var constructors : Array<EnumFieldDoc>;

} //EnumDoc

typedef ClassFieldDoc = {

    var doc : String;
    var name : String;
    var type : Dynamic;

    var line : Null<Int>;
    var meta : MetaData;
    var params : TypeParams;
    var platforms : Array<String>;

    var get : String;
    var set : String;

    var isPublic : Bool;
    var isOverride : Bool;

    // var overloads : Null<Array<ClassFieldDoc>>;

} //ClassFieldDoc

typedef CAbstractDoc = {
    var type:String;
    var name : String;
    var params : Array<Dynamic>;
}

typedef CClassDoc = {
    var type:String;
    var name : String;
    var params : Array<Dynamic>;
}

typedef CEnumDoc = {
    var type:String;
    var name : String;
    var params : Array<Dynamic>;
}

typedef CTypedefDoc = {
    var type:String;
    var name : String;
    var params : Array<Dynamic>;
}

typedef CAnonymousDoc = {
    var type:String;
    var fields:Array<ClassFieldDoc>;
}

typedef CDynamicDoc = {
    var type:String;
}

typedef FunctionArgumentDoc = {
    var value : String;
    var t : Dynamic;
    var opt : Bool;
    var name : String;
}
typedef CFunctionDoc = {
    var type:String;
    var return_type : Dynamic;
    var args : Array<FunctionArgumentDoc>;
}


typedef HaxeDoc = {

    var packages : Map<String, PackageDoc>;
    var classes : Map<String, ClassDoc>;
    var typedefs : Map<String, TypedefDoc>;
    var enums : Map<String, EnumDoc>;
    // var abstracts : Map<String, AbstractDoc>;

} //HaxeDoc

class HaxeXMLDocParser {

    static var result : HaxeDoc;

    public static function parse( root:Xml, config:Dynamic ) : Dynamic {

        var xml = new haxe.rtti.XmlParser();

        xml.process(root, 'cpp');

        result = {
            packages : new Map(),
            classes : new Map(),
            typedefs : new Map(),
            enums : new Map(),
        };

        _verbose('parsing ...');

        for(entry in xml.root) {
            parse_type(entry);
        }

        return result;

    } //parse

    static function parse_type(type:TypeTree, _depth:Int = 0) {

        switch(type) {
            case TPackage( name, full, subs ):
                parse_package( name, full, subs, _depth );
            case TClassdecl( _class ):
                parse_class( _class, _depth );
            case TTypedecl( _type ):
                parse_typedef( _type, _depth );
            case TEnumdecl( _enum ):
                parse_enum( _enum, _depth );
            case TAbstractdecl( _abstract ):
                parse_abstract( _abstract, _depth );
            default:
        }

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
        result.packages.set( full, packagedoc );

            //add it to the parent package list of package names
        var parent_name = get_package_root(full);
        var parent_package = result.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.packages.push(full);
        }

            //keep parsing it's sub items
        for(entry in subs) {
            parse_type(entry, _depth+1);
        }

    } //parse_package

    static function parse_class( _class:Classdef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'class ' + _class.path + ' / ' + _class.platforms);

            //add it to the parent package list of class names
        var parent_name = get_package_root(_class.path);
        var parent_package = result.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.classes.push(_class.path);
        }

        var classdoc = {

            doc : _class.doc,
            path : _class.path,
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

            fields : parse_classfields(_class.fields),
            statics : parse_classfields(_class.statics),

        }

            //store in the full classes root map
        result.classes.set( _class.path, classdoc );

    } //parse_class

    static function parse_typedef( _typedef:Typedef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'typedef ' + _typedef.path);

            //add it to the parent package list of typedef names
        var parent_name = get_package_root(_typedef.path);
        var parent_package = result.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.typedefs.push(_typedef.path);
        }

        var _typemap = new Map();

        for(_tname in _typedef.types.keys()) {
            var _current = _typedef.types.get(_tname);
            _typemap.set(_tname, parse_ctype(_current));
        }

        var typedefdoc = {

            doc : _typedef.doc,
            path : _typedef.path,
            module : _typedef.module,
            file : _typedef.file,

            meta : _typedef.meta,
            params : _typedef.params,
            platforms : Lambda.array(_typedef.platforms),

            isPrivate : _typedef.isPrivate,

            type : parse_ctype(_typedef.type),
            types : _typemap
        }

            //store in the full typedefs root map
        result.typedefs.set( _typedef.path, typedefdoc );

    } //parse_typedef

    static function parse_enum( _enum:Enumdef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'enum ' + _enum.path);

            //add it to the parent package list of enums names
        var parent_name = get_package_root(_enum.path);
        var parent_package = result.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.classes.push(_enum.path);
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
        result.enums.set( _enum.path, enumdoc );

    } //parse_enum

    static function parse_abstract( _abstract:Abstractdef, _depth:Int = 0 ) {

        _verbose(tabs(_depth) + 'abstract ' + _abstract.path);

            //add it to the parent package list of abstract names
        var parent_name = get_package_root(_abstract.path);
        var parent_package = result.packages.get(parent_name);
        if(parent_package != null) {
            parent_package.abstracts.push(_abstract.path);
        }

    } //parse_abstract

    static function parse_classfields( fields : List<ClassField> ) : Array<ClassFieldDoc> {

        if(fields.length == 0) {
            return [];
        }

        var _res = [];

        for(_field in fields) {

            var _fielddoc = {
                doc : _field.doc,
                name : _field.name,
                type : parse_ctype(_field.type),

                line : _field.line,
                meta : _field.meta,
                params : _field.params,
                platforms : Lambda.array(_field.platforms),

                get : parse_rights(_field.get),
                set : parse_rights(_field.set),

                isPublic : _field.isPublic != null,
                isOverride : _field.isOverride != null
            }

            _res.push(_fielddoc);

        }

        return _res;

    } //parse_classfields

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

    static function parse_ctype( _type:CType ) : Dynamic {

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

    static function parse_ctype_list( list:List<CType> ) : Array<Dynamic> {

        if(list.length == 0) {
            return [];
        }

        var _res = [];

            for(type in list) {
                _res.push( parse_ctype(type) );
            }

        return _res;
    } //parse_ctype_list


    static function parse_cabstract( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CAbstractDoc {
        return {
            type : 'CAbstract',
            name : name,
            params : parse_ctype_list(params)
        };
    } //parse_cabstract

    static function parse_cclass( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CClassDoc {
        return {
            type:'CClass',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_cclass

    static function parse_cenum( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CEnumDoc {
        return {
            type:'CEnum',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_cenum

    static function parse_ctypedef( name : haxe.rtti.Path , params : List<haxe.rtti.CType> ) : CTypedefDoc {
        return {
            type:'CTypedef',
            name:name,
            params : parse_ctype_list(params)
        };
    } //parse_ctypedef

    static function parse_canonymous( fields : List<haxe.rtti.ClassField> ) {
        return {
            type:'CAnonymous',
            fields : parse_classfields(fields)
        };
    } //parse_canonymous

    static function parse_cfunction( args : List<haxe.rtti.FunctionArgument> , ret : CType ) {

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

    static function parse_cunknown( _type:CType ) : CType {

        return _type;
    } //parse_cunknown

    static function parse_cdynamic(  ?t : CType ) {

        return parse_ctype(t);
    } //parse_cdynamic


//Helpers


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