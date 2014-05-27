
    var api = {};

    var helper   = require('./generate_helper'),
        path     = require('path');

    var haxe_types = ['String', 'Float', 'Null', 'Void', 'Int', 'Bool', 'Dynamic', 'Array', 'Map' ];
    var haxe_link = 'http://api.haxe.org/';


    api.generate = function(config) {

            helper.log('- parsing json api description');

        api.generate_md_files( config );

    } //generate

        //helper to the get the class name from a full package name
    api._get_class_name = function( _full_name ) {
        return _full_name.split('.').pop();
    }
        //helper to the get the package root from a full package name
    api._get_package_root = function( _full_name ) {
        return _full_name.split('.').shift();
    }
        //helper to the get the package sub (root.sub) from a full package name
    api._get_package_sub = function( _full_name ) {
        var _items = _full_name.split('.');
            //remove the class
        _items.pop();
            //return the path or ||
        return _items[1] || '';
    }

    api._get_type_link = function(config, _t) {
        
        if(!config.api_packages) {
            return '';
        }

            //get the type root
        var tr = api._get_package_root(_t);
            //if this is a type params type, split that out
        if(tr.indexOf('<') != -1) {
            tr = tr.substr(0, tr.indexOf('<'));
        }

            //if found in the list of acceptable packages, 
            //we return that type value
        if( config.api_packages.indexOf(tr) != -1) {
            return '#'+_t;
        } else {
                //check if its in the haxe type list
            if(haxe_types.indexOf(tr) != -1) {
                return haxe_link + tr + '.html';
            }

            if(tr == 'haxe') {
                var _p = _t.split('->');
                var _l = _p[0].replace(/\./gi,'/');
                return haxe_link + _l + '.html';
            }
        }

        return '';

    } //_get_type_link

    api._add_type_links = function(config, t) {

        var _tl = api._get_type_link(config, t.name);

        if(t.params && t.params.length) {
            for(_k in t.params) {
                api._add_type_links(config, t.params[_k]);
            }
        }

        if(_tl) {
            t.type_link = _tl;
        }
        
    }

    api.generate_md_files = function( config ) {

        helper.bars.registerHelper('escape_markdown', function(data) {
            return data.replace(/_/gi, '\\_');
        });

        helper.bars.registerHelper('type_path', function(data) {
            return data.replace(/\./gi, '/');
        });
 
        helper.bars.registerHelper('is_visible', function(obj, options) {

                //hide if private
            var show = obj.ispublic;
                //hide if @:noCompletion
            if(obj.meta["@:noCompletion"]) {
                show = false;
            }

                //run the block only if not hidden
            if(show) {
                return options.fn(this);
            } else {
                return options.inverse(this);
            }

        });

        var _api_index_template = helper.read_file( config.template_path + config.api_index_template );
        var _api_partials = {};
        var doc = helper.json( config.api_source_json );

        var _partial_list = config.api_partials || [];
        for(_i in _partial_list) {
            var p = _partial_list[_i];
            var p_templ =  helper.read_file( config.template_path + p.path );
            _api_partials[p.name] = p_templ;
        }

            //This is the list of sorted packages, by {root}.{sub} basically.
            //this is an assumption that may give way later.
        var _package_list = [];
        var _package_items = {};

        if(doc) {

            var _type_count = doc.names.length;
            var _blacklist = config.api_exclude || [];

            for(var i = 0; i < _type_count; ++i) {

                var _type_name = doc.names[i];
                var _type_info = doc.types[_type_name];

                if(!_type_name || !_type_info) {
                    continue;
                }

                var _root = api._get_package_root(_type_info.name);
                var _sub = api._get_package_sub(_type_info.name);
                var _full = _type_info.name;

                var _package_parent = _root + ( _sub ? ('.'+_sub) : '' );

                var _skip = false;

                if(_blacklist.length) {
                    for(k = 0; k < _blacklist.length; ++k) {
                        if(_full.indexOf(_blacklist[k]) != -1) {
                            _skip = true;
                        }
                    }
                }

                if(_skip) {
                    continue;
                }

                    //if this package isn't yet added to the list,
                    //we add it and fill it with the name and blank list
                if(!_package_items[_package_parent]) {
                        //new list
                    _package_items[_package_parent] = [];
                        //store it in the root list
                    _package_list.push({ 
                        name:_package_parent, 
                        items:_package_items[_package_parent]
                    });
                }


                if(!_type_info.meta['@:noCompletion'] && _type_info.ispublic) {

                        //a short name removing the root+sub package
                    _type_info.name_short = _type_info.name.replace(_package_parent+'.','');

                        //we make a type link for each item that has one, provided it's from our package
                    if(_type_info.type == 'class' || _type_info.type == 'typedef') {
                        
                        for(_m in _type_info.members) {

                            var t = _type_info.members[_m];
                            api._add_type_links(config, t.type);

                        } //for each member

                        if(_type_info.type == 'class') {
                            for(_m in _type_info.methods) {

                                var _method = _type_info.methods[_m];
                                    //add links for method args
                                for(_a in _method.args) {
                                    var a = _method.args[_a];
                                    api._add_type_links(config, a.type);
                                }
                                    //add links for return type
                                api._add_type_links(config, _method.return_type);

                            } //for each method
                        } //classes only have methods
                        
                    } //if typedef/class


                        //push this class into the list 
                    _package_items[_package_parent].push( _type_info );
                }

            } //for all classes

                //sort the package list items by alphabeticalness
            for(k = 0; k < _package_list.length; ++k) {
                _package_list[k].items.sort(function(a,b){
                    if(a.name < b.name) return -1;
                    if(a.name >= b.name) return 1;
                    return 0;
                });

                for(j in _package_list[k].items) {
                    api._generate_md_for_type(config, _package_list[k].items[j], _api_partials);
                }                
            }


                //work out the end file for the index itself
            var _out_dest = config.api_out_md_path + config.api_index_out;
            var _rel_test = _out_dest.replace('.md','.html');
            var _index_context = { 
                package_list : _package_list,
                api_types : doc.types, 
                api_list : doc.names, 
                rel_path : helper.get_rel_path_count(_rel_test) 
            };

                //make sure the api folder exists
            helper.create_folder_path( config.md_path + config.api_out_md_path );

                //template the index file with the list
            var _template_out = helper.render( _api_index_template, _index_context, _api_partials );
                //write the correct file to the correct location
            _out_dest = config.md_path + config.api_out_md_path + config.api_index_out;        
                //write out to the destination
            helper.write_file( _out_dest , _template_out );
                //debug
            helper.log("\t - wrote api index file " + _out_dest);

            helper.log("- generated api files complete");


        } //_doc_json

    } //generate_md_files

    api._generate_md_for_type = function(config, _type, _api_partials) {

        var _api_page_template = helper.read_file( config.template_path + config.api_template );

        var _page_context = {  item : _type  };

            //write out a single file per class, into it's package folder
        var packages = _type.name.split('.');
            //remove the class name from the end
        var class_name = packages.pop();
            //find the output file name
        var package_path = config.md_path + config.api_out_md_path + packages.join('/') + '/';
            //create the paths if necessary
        helper.create_folder_path( package_path );
            //the end resulting file
        var _api_file_dest = package_path + class_name + '.md';
            //the relative path from the destination for calculating the rel_path helper
        var _api_rel_dest = _type.name.split('.').join('/') + '/' + class_name + '.html';
            //work out the rel path helper
        _page_context.rel_path = helper.get_rel_path_count(_api_rel_dest);
            //complete the generated template md
        var _template_out = helper.render( _api_page_template, _page_context, _api_partials );
            //log the details
        helper.verbose("\t - generating file " + _api_file_dest);
            //save it
        helper.write_file( _api_file_dest , _template_out );
    }

    // var _api_replacement = function( _content ) {
        
    //     var _replacements = config.replacements;

    //     var _count = _replacements.length;
    //     var _output = _content;

    //     for(var i = 0; i < _count; i++) {

    //         var _item = _replacements[i];
    //         var _replace = new RegExp( "(\\b" + _item.key + "\\b)(?!.*</a>)", 'g');

    //         _output = _output.replace( _replace, '<a href="'+_item.link+'">'+_item.key+'</a>' );

    //     } //each replacement

    //     return _output;

    // } //_api_replacement


    module.exports = api;

