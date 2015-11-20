//          Copyright Mario Kröplin 2015.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module outliner;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.typecons;
import std.d.ast;
import std.d.formatter;
import std.d.lexer;

class Outliner : ASTVisitor
{
    private File output;

    private string fileName;

    private Classifier classifier;

    private string visibility = "+";

    private string[] modifiers;

    private Classifier[] classifiers = null;

    alias visit = ASTVisitor.visit;

    public this(File output, string fileName)
    {
        this.output = output;
        this.fileName = fileName;
    }

    public override void visit(const AttributeDeclaration attributeDeclaration)
    {
        const attributes = protectionAttributes(attributeDeclaration.attribute);
        if (!attributes.empty)
            visibility = attributes.back.attribute.toVisibility;
    }

    public override void visit(const ClassDeclaration classDeclaration)
    {
        auto qualifiedName = classifier.qualifiedName;
        auto outliner = scoped!Outliner(output, fileName);
        with (outliner)
        {
            classifier.type = "class";
            classifier.qualifiedName = qualifiedName ~ classDeclaration.name.text;
            classDeclaration.accept(outliner);
        }
        classifiers ~= outliner.classifier ~ outliner.classifiers;
    }

    public override void visit(const Constructor constructor)
    {
        Method method;
        method.visibility = visibility;
        method.name = "this";
        auto app = appender!(char[]);
        app.format(constructor.parameters);
        method.parameters = app.data.to!string;
        classifier.methods ~= method;
    }

    public override void visit(const Declaration declaration)
    {
        string visibility = this.visibility;
        const attributes = protectionAttributes(declaration);
        if (!attributes.empty)
            this.visibility = attributes.back.attribute.toVisibility;
        this.modifiers = declaration.modifiers;
        super.visit(declaration);
        if (!attributes.empty)
            this.visibility = visibility;
    }

    public override void visit(const Destructor destructor)
    {
        Method method;
        method.visibility = visibility;
        method.name = "~this";
        classifier.methods ~= method;
    }

    public override void visit(const EnumDeclaration enumDeclaration)
    {
        auto qualifiedName = classifier.qualifiedName;
        auto outliner = scoped!Outliner(output, fileName);
        with (outliner)
        {
            classifier.type = "enum";
            classifier.qualifiedName = qualifiedName ~ enumDeclaration.name.text;
            enumDeclaration.accept(outliner);
        }
        classifiers ~= outliner.classifier ~ outliner.classifiers;
    }

    public override void visit(const EnumMember enumMember)
    {
        Field field;
        field.name = enumMember.name.text;
        classifier.fields ~= field;
    }

    public override void visit(const FunctionDeclaration functionDeclaration)
    {
        Method method;
        method.visibility = visibility;
        method.modifiers = modifiers.dup;
        method.name = functionDeclaration.name.text;
        if (functionDeclaration.hasAuto)
            method.modifiers ~= "auto";
        if (functionDeclaration.hasRef)
            method.modifiers ~= "ref";
        if (functionDeclaration.returnType !is null)
        {
            auto app = appender!(char[]);
            app.format(functionDeclaration.returnType);
            method.type = app.data.to!string;
        }
        auto app = appender!(char[]);
        app.format(functionDeclaration.parameters);
        method.parameters = app.data.to!string;
        classifier.methods ~= method;
    }

    public override void visit(const InterfaceDeclaration interfaceDeclaration)
    {
        auto qualifiedName = classifier.qualifiedName;
        auto outliner = scoped!Outliner(output, fileName);
        with (outliner)
        {
            classifier.type = "interface";
            classifier.qualifiedName = qualifiedName ~ interfaceDeclaration.name.text;
            interfaceDeclaration.accept(outliner);
        }
        classifiers ~= outliner.classifier ~ outliner.classifiers;
    }

    public override void visit(const Invariant invariant_)
    {
        // skip
    }

    public override void visit(const Module module_)
    {
        import std.string : toLower;
        super.visit(module_);
        string name;
        if (module_.moduleDeclaration is null)
        {
            import std.path : baseName, stripExtension;
            name = fileName.stripExtension.baseName;
        }
        else
            name = module_.moduleDeclaration.moduleName.identifiers.back.text;
        name = name.toLower;  // XXX workaround for module Foo; class Foo;
        if (!classifier.fields.empty || !classifier.methods.empty)
        {
            classifier.type = "class";
            classifier.qualifiedName = [name];
            classifier.stereotype = "<<(M,gold)>>";
            classifier.write(output.lockingTextWriter);
            hide(classifier.qualifiedName);
        }
        foreach (classifier; classifiers)
        {
            classifier.write(output.lockingTextWriter);
            hide(classifier.qualifiedName);
        }
    }

    public override void visit(const SharedStaticConstructor sharedStaticConstructor)
    {
        Method method;
        method.visibility = visibility;
        method.modifiers = ["{static}", "shared"];
        method.name = "this";
        classifier.methods ~= method;
    }

    public override void visit(const SharedStaticDestructor sharedStaticDestructor)
    {
        Method method;
        method.visibility = visibility;
        method.modifiers = ["{static}", "shared"];
        method.name = "~this";
        classifier.methods ~= method;
    }

    public override void visit(const StaticConstructor staticConstructor)
    {
        Method method;
        method.visibility = visibility;
        method.modifiers = ["{static}"];
        method.name = "this";
        classifier.methods ~= method;
    }

    public override void visit(const StaticDestructor staticDestructor)
    {
        Method method;
        method.visibility = visibility;
        method.modifiers = ["{static}"];
        method.name = "~this";
        classifier.methods ~= method;
    }

    public override void visit(const StructDeclaration structDeclaration)
    {
        auto qualifiedName = classifier.qualifiedName;
        auto outliner = scoped!Outliner(output, fileName);
        with (outliner)
        {
            classifier.type = "class";
            classifier.qualifiedName = qualifiedName ~ structDeclaration.name.text;
            classifier.stereotype = "<<(S,silver)>>";
            structDeclaration.accept(outliner);
        }
        classifiers ~= outliner.classifier ~ outliner.classifiers;
    }

    public override void visit(const Unittest unittest_)
    {
        // skip
    }

    public override void visit(const VariableDeclaration variableDeclaration)
    {
        Field field;
        field.visibility = visibility;
        field.modifiers = modifiers.dup;
        if (variableDeclaration.type !is null)
        {
            auto app = appender!(char[]);
            app.format(variableDeclaration.type);
            field.type = app.data.to!string;
        }
        foreach (declarator; variableDeclaration.declarators)
        {
            field.name = declarator.name.text;
            classifier.fields ~= field;
        }
    }

    private void hide(in string[] qualifiedName)
    {
        output.writeln("!ifdef HIDE");
        output.writefln("hide %-(%s.%)", qualifiedName);
        output.writeln("!endif");
    }
}

struct Classifier
{
    const string indent = "  ";

    string type;

    string[] qualifiedName = null;

    string stereotype;

    Field[] fields;

    Method[] methods;

    void write(Sink)(Sink sink) const
    {
        sink.put(type);
        sink.put(' ');
        foreach (index, name; qualifiedName)
        {
            if (index > 0)
                sink.put('.');
            sink.put(name);
        }
        sink.put(' ');
        if (!stereotype.empty)
        {
            sink.put(stereotype);
            sink.put(' ');
        }
        sink.put("{");
        sink.put('\n');
        foreach (field; fields)
        {
            sink.put(indent);
            field.write(sink);
            sink.put('\n');
        }
        foreach (method; methods)
        {
            sink.put(indent);
            method.write(sink);
            sink.put('\n');
        }
        sink.put("}");
        sink.put('\n');
    }
}

struct Field
{
    string visibility;

    string[] modifiers;

    string type;

    string name;

    void write(Sink)(Sink sink) const
    {
        // override check for parenthesis to choose between methods and fields
        sink.put("{field} ");
        sink.put(visibility);
        foreach (modifier; modifiers)
        {
            sink.put(modifier);
            sink.put(' ');
        }
        if (!type.empty)
        {
            sink.put(type);
            sink.put(' ');
        }
        sink.put(name);
    }
}

struct Method
{
    string visibility;

    string[] modifiers;

    string type;

    string name;

    string parameters = "()";

    void write(Sink)(Sink sink) const
    {
        sink.put(visibility);
        foreach (modifier; modifiers)
        {
            sink.put(modifier);
            sink.put(' ');
        }
        if (!type.empty)
        {
            sink.put(type);
            sink.put(' ');
        }
        sink.put(name);
        sink.put(escape(parameters));
    }
}

private string escape(string source) pure
{
    return source.replace(`\`, `\\`);
}

private const(Attribute[]) protectionAttributes(const Declaration declaration) pure
{
    const(Attribute)[] attributes = null;
    foreach (attribute; declaration.attributes)
        attributes ~= protectionAttributes(attribute);
    return attributes;
}

private const(Attribute[]) protectionAttributes(const Attribute attribute) pure
{
    return (attribute.attribute.type.isProtection) ? [attribute] : null;
}

private string toVisibility(const Token token) pure
in
{
    assert(token.type.isProtection);
}
body
{
    switch (token.type)
    {
    case tok!"package":
        return "~";
    case tok!"private":
        return "-";
    case tok!"protected":
        return "#";
    case tok!"public":
        return "+";
    default:
        return "+";
    }
}

private string[] modifiers(const Declaration declaration) pure
{
    string[] modifiers = null;
    if (declaration.attributes.any!(a => a.attribute == tok!"abstract"))
        modifiers ~= "{abstract}";
    if (declaration.attributes.any!(a => a.attribute == tok!"static"))
        modifiers ~= "{static}";
    return modifiers;
}
