D to UML
========

This tool parses the given D source code
and outputs corresponding [PlantUML](http://plantuml.com/) class descriptions.
Also `struct`s and `module`s are represented as classes.

The renderer allows some tweaking for the directions of arrows,
so that this tool does not even try to extract relations between classes.

Usage
-----

Use [dub](http://code.dlang.org/) to build the tool:

    dub build --build=release

Use the _d2uml_ tool to extract the class descriptions from D source code.
For example:

    ./d2uml src/*.d > classes.plantuml

In another file, use the `!include` directive to include the generated file.
Add the relations between the classes.
For example:

[model/diagram.plantuml](https://github.com/funkwerk/d2uml/blob/master/model/diagram.plantuml)

Use the _plantuml.jar_ to generate the image of the diagram:

    java -jar path/to/plantuml.*.jar model/diagram.plantuml

Have a look at the resulting image _model/diagram.png_:

![model/diagram.png](https://raw.githubusercontent.com/wiki/funkwerk/d2uml/images/diagram.png)

Related Projects
----------------

- [Duml](https://github.com/rikkimax/Duml):
  a similar tool based on a different approach (CTFE)
- [depend](https://github.com/funkwerk/depend):
  a tool to check actual import dependencies
  against a UML model of target dependencies
