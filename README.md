##scribe
---
###A haxe xml documentation conversion library.

---

[Haxe](http://haxe.org) features an -xml flag to export current compilation class information, to an xml file.

[View the haxe documentation generator docs](http://haxe.org/manual/documentation#writing-a-custom-generator).

This output can be used for many things, but the output format is rather dense difficult to parse in anything other than haxe itself.   

---

scribe steps in between you and the xml file - and hosts a `HaxeDoc` class, which lists all the class names and each class definition (including `properties`, `members`, `methods` and so on).

With these elements, you can parse and export them to any language you wish, or implement the class as an API **WIP** embedded in your own library/project.


---
###Roadmap

- support different export options (some form of plugin or similar)
- be able to specify a haxe project build file or arguments to haxe, to directly feed from the doc generator
- make per-platform binaries
- submit to haxelib with run script

---
###History

**0.9.1** 

- major rewrite to use haxe xml parser directly
- changes export json structure but includes more precise mappings
- many scriber fixes and additions due to new format

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


