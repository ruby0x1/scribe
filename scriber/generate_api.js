
    var api = {};

    var helper   = require('./generate_helper'),
        path     = require('path');

    var haxe_types = ['String', 'Float', 'Null', 'Void', 'Int', 'Bool', 'Dynamic', 'Array', 'Map' ];
    var haxe_link = 'http://api.haxe.org/';


    api.generate = function(config) {

            helper.log('- parsing json api description');

        if(!config.api_input) {
            return;
        }

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

    api.sort = function(arr, key ){
        arr.sort(function(a, b) {
            a = a[key]; b= b[key];
            if(a < b) return -1;
            if(a >= b) return 1;
            return 0;
        });

        return arr;
    }

    api.generate_md_files = function( config ) {

        helper.bars.registerHelper('json', function(context) {
            return JSON.stringify(context,null,2);
        });


        helper.bars.registerHelper('escape_markdown', function(data) {
            if(!data) return data;
            return data.replace(/_/gi, '\\_');
        });

        helper.bars.registerHelper('type_path', function(data) {
            if(!data) return data;
            return data.replace(/\./gi, '/');
        });

        helper.bars.registerHelper('without_package', function(data) {
            if(!data) return data;
            return data.split('.').pop();
        });


        var _api_index_template = helper.read_file( config.template_path + config.api_index_template );
        var _api_partials = {};
        var doc = helper.json( config.api_source_json );

        helper.bars.registerHelper('member_visible', function(type, section, name, options) {

            var show = false;
            var _type_info = api.type_get_info(config, doc, type);
            var _type_info = _type_info[section];

            for(index in _type_info) {
                var item = _type_info[index];
                if(item.name == name) {
                    _type_info = item;
                    break;
                }
            }

            var show = _type_info.isPrivate != true;

            if(_type_info.isPublic == false) {
                show = false;
            }

            if(api.type_has_meta(config, doc, _type_info, ':noCompletion')){
                show = false;
            }

                //run the block only if not hidden
            return show;

        }); //member_visible

        helper.bars.registerHelper('name_visible', function(name, options) {

            var _type_info = api.type_get_info(config, doc, name);

            var show = _type_info.isPrivate != true;

            if(_type_info.isPublic == false) {
                show = false;
            }

            if(api.type_has_meta(config, doc, _type_info, ':noCompletion')){
                show = false;
            }
                //run the block only if not hidden
            if(show) {
                return options.fn(this);
            } else {
                return options.inverse(this);
            }

        });

        helper.bars.registerHelper('get_type', function(object, name) {
            return doc[object][name];
        });

        helper.bars.registerHelper('hidden_package', function(name) {
            if(!name) return true;
            var _p = doc.packages[name];
            if(!_p) return true;
            if(_p.isPrivate) return true;
            return false;
        });

        helper.bars.registerHelper('names_in_package', function(in_package) {
            // console.log('looking for names in ' + in_package);
            var res = [];
            for(index in doc.names) {
                var _name = doc.names[index];
                if(_name.indexOf(in_package) != -1) {
                    var _without_package = _name.replace(in_package+'.','');
                    if(_without_package.indexOf('.') == -1) {
                        res.push(_name);
                    }
                }
            }
            return res;
        });

        var _partial_list = config.api_partials || [];
        for(_i in _partial_list) {
            var p = _partial_list[_i];
            var p_templ =  helper.read_file( config.template_path + p.path );
            _api_partials[p.name] = p_templ;
        }

        var _package_list = {};

        if(doc) {

                //first, we want to populate the list of packages with empty objects to
                //store the types inside of, so they can be iterated on the templates

            var _name_count = doc.names.length;

            for(var i = 0; i < _name_count; ++i) {
                var _package = doc.names[i];
                var _paths = _package.split('.');
                    //remove the type
                    _paths.pop();

                    //for each package depth, see it it exists and
                    //if not add it to the object
                var _current = _package_list;
                var _current_name = '';
                for(index in _paths) {
                    var _path = _paths[index];
                    _current_name += (index>0 ? '.' : '') + _path;
                    if(!_current[_path]) {
                        _current[_path] = { root:_current_name };
                    }

                    _current = _current[_path];
                }
            } //each name

            // console.log(JSON.stringify(_package_list,null,4));
            for(index in doc.packages) {
                doc.packages[index].packages = api.sort(doc.packages[index].packages, 'full');
            }

            api._type_list = [];

                //now for each sub type, we want to push it into the package
            for(i in doc.classes) {

                var _class = doc.classes[i];
                api._push_type(config, doc, _class, _package_list);

            } //each classes

            for(i in doc.typedefs) {

                var _typedef = doc.typedefs[i];
                api._push_type(config, doc, _typedef, _package_list);

            } //each typedefs

            for(i in doc.enums) {

                var _typedef = doc.enums[i];
                api._push_type(config, doc, _typedef, _package_list);

            } //each enums

            for(i in doc.abstracts) {

                var _typedef = doc.abstracts[i];
                api._push_type(config, doc, _typedef, _package_list);

            } //each abstracts

            for(k = 0; k < api._type_list.length; ++k) {
                var _t = api._type_list[k];
                api._generate_md_for_type(config, _t, _api_partials);
            }


                //work out the end file for the index itself
            var _out_dest = config.api_out_md_path + config.api_index_out;
            var _rel_test = _out_dest.replace('.md','.html');
            var _index_context = {
                packages : _package_list,
                doc : doc,
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

            helper.log("\t - wrote api index file " + _out_dest);

            helper.log("- generated api files complete");


        } //_doc_json

    } //generate_md_files

    api._generate_md_for_type = function(config, _type, _api_partials) {

        var _api_page_template = helper.read_file( config.template_path + config.api_template );

        var _page_context = {  item : _type  };

            //write out a single file per class, into it's package folder
        var packages = _type.path.split('.');
            //remove the class name from the end
        var class_name = packages.pop();
            //find the output file name
        var package_path = config.md_path + config.api_out_md_path + packages.join('/') + '/';
            //create the paths if necessary
        helper.create_folder_path( package_path );
            //the end resulting file
        var _api_file_dest = package_path + class_name + '.md';
            //the relative path from the destination for calculating the rel_path helper
        var _api_rel_dest = _type.path.split('.').join('/') + '/' + class_name + '.html';
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

    api.type_has_meta = function(config, doc, type, meta) {
        for(index in type.meta) {
            var _meta = type.meta[index];
            if(_meta.name == meta) {
                return _meta;
            }
        }
    }

    api.type_get_info = function(config, doc, name) {
        return doc.classes[name] ||
               doc.typedefs[name] ||
               doc.enums[name] ||
               doc.abstracts[name];
    }

    api._is_blacklisted = function(config) {

        var _blacklist = config.api_exclude || [];
        var _skip = false;

        if(_blacklist.length) {
            for(k = 0; k < _blacklist.length; ++k) {
                if(_full.indexOf(_blacklist[k]) != -1) {
                    _skip = true;
                }
            }
        }

        return _skip;

    } //_is_blacklisted

    api._push_type = function(config, doc, _typeitem, _package_list) {

        var _full_path = _typeitem.path;
        var _paths = _full_path.split('.');
        var _type = _paths.pop();

        if(api._is_blacklisted(_full_path)) {
            return;
        }

        var _package = _package_list;
            //hunt down the one we want
        for(index in _paths) {
            _package = _package[_paths[index]];
        }

            //now we store the class definition in here
            //under the type name
        // console.log(_type);
        // console.log(_full_path);

        _package[_type] = _typeitem;
        api._type_list.push( _typeitem );

    } //_push_type


    module.exports = api;

