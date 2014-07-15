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

typedef HaxeDoc = {

    var names : Array<String>;
    var package_roots : Array<String>;
    var packages : Map<String, PackageDoc>;
    var classes : Map<String, ClassDoc>;
    var typedefs : Map<String, TypedefDoc>;
    var enums : Map<String, EnumDoc>;
    var abstracts : Map<String, AbstractDoc>;

} //HaxeDoc

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
        /** The short name only */
    var name : String;
        /** The type only */
    var type : String;
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

        /** The fields of this class */
    var members : Array<ClassFieldDoc>;
    var methods : Array<ClassFieldDoc>;
    var properties : Array<ClassFieldDoc>;

} //ClassDoc

typedef TypedefDoc = {

    var doc : String;

    var path : String;
    var name : String;
    var type : String;

    var file : Null<String>;

    var module : String;

    var types : Map<String, CTypeDoc>;

    var isPrivate : Bool;
        /** The meta data attached to this typedef, if any */
    var meta : MetaData;
        /** The typedef type parameters, if any */
    var params : TypeParams;
        /** The list of platforms this was generated for, if any */
    var platforms : Array<String>;

    var members : Array<ClassFieldDoc>;

} //TypedefDoc

typedef EnumArgDoc = {
    var name : String;
    var t : CTypeDoc;
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
    var name : String;
    var type : String;

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


typedef AbstractNodeDoc = {
    var t : CTypeDoc;
    var field : Null<String>;
}

typedef AbstractDoc = {

    var doc : String;
    var path : String;
    var name : String;
    var type : String;
    var file : Null<String>;
    var module : String;

        /** The meta data attached to this typedef, if any */
    var meta : MetaData;
        /** The typedef type parameters, if any */
    var params : TypeParams;
        /** The list of platforms this was generated for, if any */
    var platforms : Array<String>;

    var to : Array<AbstractNodeDoc>;
    var from : Array<AbstractNodeDoc>;
    var athis : CTypeDoc;
    var impl : ClassDoc;

} //AbstractDoc

typedef ClassFieldDoc = {

    var doc : String;
    var name : String;
    var type : CTypeDoc;

    var line : Null<Int>;
    var meta : MetaData;
    var params : TypeParams;
    var platforms : Array<String>;

    var get : String;
    var set : String;

    var isPublic : Bool;
    var isOverride : Bool;
    var isStatic : Bool;

    // var overloads : Null<Array<ClassFieldDoc>>;

} //ClassFieldDoc

typedef FunctionArgumentDoc = {
    var value : String;
    var t : CTypeDoc;
    var opt : Bool;
    var name : String;
}

typedef CTypeDoc = {

        //these are common
    var type:String;
    @:optional var name : String;
    @:optional var params : Array<CTypeDoc>;
        //for anonymous types only
    @:optional var fields:Array<ClassFieldDoc>;
        //for function types only
    @:optional var return_type:CTypeDoc;
    @:optional var args : Array<FunctionArgumentDoc>;

} //CTypeDoc

enum ClassFieldType {
    member;
    method;
    property;
}

typedef ScribeTypes = {};
