##scribe
---
###A haxe xml documentation conversion library.

---

[Haxe](http://haxe.org) features an -xml flag to export current compilation class information, to an xml file.

[View the haxe documentation generator docs](http://haxe.org/manual/documentation#writing-a-custom-generator).

This output can be used for many things, but the output format is rather dense and confusing to parse.   

---

scribe steps in between you and the xml file - and hosts a `HaxeDoc` class, which lists all the class names and each class definition (including `properties`, `members`, `methods` and any unknown elements that it finds).

With these elements, you can parse and export them to any language you wish, or implement the class as an API **WIP** embedded in your own library/project.

---
###Example input 

	from scribe.json. allowed_packages can be :
		-a comma delimeted string "package,package2"
		-an array of strings ["package", "package2"]
		-a single class (see below for example)
		-leave the allowed_packages flag out, 
		to parse every class in the input xml

	{ 
		"input":"docs.xml", 
		"output":"docs.json", 
		"allowed_packages":"luxe.utils.GeometryUtils" 
	}

###Example output
---
See example_output.json for an example class output from the current version.

###Usage
---
Note the library is WIP (see roadmap) but is usable already.

    usage : 
      scribe <options>

    options list :
      version, generate, display, input, config 

    options :

      -version
          displays the version number

      -generate <optional output file>
          generate an output file, specified in config.output or 
          specified as an optional output file argument.

      -display
          if display is set and generate is set, output will be 
          printed to stdout instead of saved to the file.

      -input haxedoc.xml
          generate documentation from this file (config.input), if the file is a special value of "scribe.types.xml" in config or here, the project will attempt to make use of the lime_project config or argument in order to generate the "scribe.types.xml" file directly from the source lime project xml file.

      -config config.json
          when run without this flag, scribe will look for a scribe.json in the same folder.
      

---
###Roadmap

- support different export options (some form of plugin or similar)
- be able to specify a haxe project build file or arguments to haxe, to directly feed from the doc generator
- make per-platform binaries
- submit to haxelib with run script

---
###History

**0.9.0** 

- updating to include haxe_doc values
- changing the type of delimeter for the --flag to be -flag
- making it run as a haxelib rather than as a standalone tool
- and running from the correct path
- so the scribe.json and other data can be project specific
- changing the lime project to be the project file path
- instead of folder (this allows usage for any project etc)
- bumping version to 0.9.0 before finalising the api and usage for 1.0.0 release on haxelib

**0.1.0** 

- Initial version with basic import/export to JSON

---
License : MIT


