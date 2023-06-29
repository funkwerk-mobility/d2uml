D to UML
========

[![Build Status](https://github.com/funkwerk-mobility/d2uml/workflows/CI/badge.svg)](https://github.com/funkwerk-mobility/d2uml/actions?query=workflow%3ACI)

UML diagrams can be helpful for code maintenance.
But, drawing these diagrams with mouse and keyboard is a tedious task.
And popular UML tools don't support reverse engineering for the
[D programming language].

This tool uses [libdparse] to parse the given D source code
and it extracts class outlines in the [PlantUML] language.
Not only a `class`, but also a `struct`, and even a `module` is turned into a class outline.

A good arrangement of the classes is essential for creating effective UML diagrams.
The means for tweaking the arrangement is to explicitly specify the direction of arrows:
[Class Diagram](https://plantuml.com/class-diagram)>Changing arrows orientation.
Such an artistic design, however, is beyond the capabilities of this pragmatic tool.
So, this tool does not even try to extract relations between classes.

Usage
-----

Use [dub] to build the tool:

    dub build --build=release

Use the tool to extract the class outlines from D source code.

For example:

    ./d2uml src/*.d > model/classes.puml

Create another file and explicitly specify the relations between the classes.
Use the `!include` directive to include the generated file.

For example:
[model/diagram.puml](model/diagram.puml)

    @startuml
    hide empty attributes
    hide empty methods

    !include classes.plantuml

    main .> Outliner
    ASTVisitor <|-- Outliner
    Outliner -> "*" Classifier
    Classifier --> "*" Field
    Classifier --> "*" Method
    Outliner ..> outliner
    @enduml

Use [plantuml.jar] to generate the image of the diagram:

    java -jar path/to/plantuml.jar model/diagram.puml

Finally, have a look at the resulting image:

![image](https://github.com/funkwerk-mobility/d2uml/assets/2083772/7d605072-1249-47a7-8c3c-69ca537bfea0)


Related Projects
----------------

- [Duml](https://github.com/rikkimax/Duml):
  a similar tool based on a different approach (CTFE)
- [depend](https://github.com/funkwerk-mobility/depend):
  a tool to check actual import dependencies
  against a UML model of target dependencies

[D programming language]: http://dlang.org
[dub]: http://code.dlang.org
[libdparse]: https://github.com/dlang-community/libdparse
[PlantUML]: http://plantuml.com
[plantuml.jar]: https://github.com/plantuml/plantuml/releases
