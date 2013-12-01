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
**WIP***   
The library is brand new, see the roadmap below for goals. 

---
###Roadmap
- finish command line args implementation
- convert output in such a way multiple types can be added (custom output formats)
- make the API includable as a haxelib
- submit to haxelib
- properly document features and make per-platform binaries

---
License : MIT


