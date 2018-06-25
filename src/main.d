//          Copyright Mario Kröplin 2015.
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module main;

import std.array;
import std.stdio;

int main(string[] args)
in
{
    assert(!args.empty);
}
body
{
    import std.getopt : defaultGetoptPrinter, getopt, GetOptException, GetoptResult;
    import std.path : baseName;

    GetoptResult result;
    try
    {
        result = getopt(args);
    }
    catch (GetOptException exception)
    {
        stderr.writeln("error: ", exception.msg);
        return 1;
    }
    if (result.helpWanted)
    {
        writefln("Usage: %s [option...] file...", baseName(args[0]));
        writeln("Reverse engineering of D source code into PlantUML classes.");
        writeln("If no files are specified, input is read from stdin.");
        defaultGetoptPrinter("Options:", result.options);
        return 0;
    }
    return process(args[1 .. $]);
}

int process(string[] names)
{
    import dparse.lexer : getTokensForParser, LexerConfig, StringBehavior, StringCache;
    import dparse.parser : parseModule;

    bool success = true;
    StringCache cache = StringCache(StringCache.defaultBucketCount);
    LexerConfig config;
    config.stringBehavior = StringBehavior.source;

    void outline(ubyte[] sourceCode, string name)
    {
        import dparse.rollback_allocator : RollbackAllocator;
        import outliner : Outliner;
        import std.typecons : scoped;

        config.fileName = name;
        auto tokens = getTokensForParser(sourceCode, config, &cache);
        RollbackAllocator allocator;
        auto module_ = parseModule(tokens, name, &allocator);
        auto visitor = scoped!Outliner(stdout, name);
        visitor.visit(module_);
    }

    if (names.empty)
        outline(read(), "stdin");
    else
    {
        import std.file : FileException, read;

        foreach (name; names)
        {
            try
            {
                outline(cast(ubyte[]) read(name), name);
            }
            catch (FileException exception)
            {
                stderr.writeln("error: ", exception.msg);
                success = false;
            }
        }
    }
    return success ? 0 : 1;
}

ubyte[] read()
{
    auto content = appender!(ubyte[])();
    ubyte[4096] buffer = void;
    while (!stdin.eof)
    {
        auto slice = stdin.rawRead(buffer);
        if (slice.empty)
            break;
        content.put(slice);
    }
    return content.data;
}
