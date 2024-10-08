module lionweb::converter::lionADT2rsc

import lionweb::converter::lioncore2ADT;
import lionweb::m3::lioncore;
import lionweb::pointer;

import IO;
import DateTime;
import Type;
import List;
import String;
import Map;

void writeLionADTModule(Language lionlang, map[Symbol, Production] langADT) 
  = writeFile(moduleLocation(lionlang.name),
                "module <moduleName(lionlang.name)>
                '
                '// Code generated from lionweb language.
                '// Date: <now()>
                '
                'import DateTime;
                'import lionweb::pointer;
                'import lang::json::ast::JSON;
                '
                '<lion2rsc(lionlang, langADT)>");

str moduleName(str langName)
    = intercalate("::", split(".", langName));

loc moduleLocation(str langName)
    = |project://lionweb-rascal/src/<intercalate("/", split(".", langName)[..-1])>| + (last(split(".", langName)) + ".rsc");  

str lion2rsc(Language lionlang, map[Symbol, Production] langADT)
    = langDependencies(lionlang.dependsOn) + langADTs(langADT);

str langDependencies(list[Pointer[Language]] langDependencies)
    = "";

str langADTs(map[Symbol, Production] langADT) 
    = intercalate("\n\n", [production2rsc(prod) | prod <- range(langADT)]);


// --------------------------- Serialize Rascal ADT in Rascal syntax --------------------------------------

str production2rsc(choice(Symbol typeDef, set[Production] alterns)) 
  = "data <typeDef.name>\n  = <intercalate("\n  | ", [ alternative2rsc(p) | Production p <- alterns ])>
    '  ;";

// The case of a classifier with an extension (wrapped inheritance)
// TODO: change this patternt to really recognize wrapped inheritance 
// (as we can have parameters without default values in usual cases too)
str alternative2rsc(cons(label(str c, _), [label(str x, adt(str sub, []))], [*subs], {\tag("subtype")}))
  = "<c>(<intercalate("\n      , ", args)>)"
  when field(sub) == x,
    args := [
      "<sub> \\<x>",
      *[ default4sub(s, x) | s <- subs ]
    ];

str default4sub(label(str fld, Symbol s), str kid)
  = "<symbol2rsc(s)> \\<fld> = <kid>.\\<fld>";

// The default case of the classifier (itself)
default str alternative2rsc(cons(label(str c, _), list[Symbol] ps, list[Symbol] kws, _))
  = "<c>(<intercalate("\n      , ", args)>)"
  when
    list[str] args := [ param2rsc(p) | p <- ps ] + [ keywordparam2rsc(k) | k <- kws ];
    
str param2rsc(label(str name, Symbol s)) = "<symbol2rsc(s)> \\<name>";

str keywordparam2rsc(label(str name, Symbol s)) = "<symbol2rsc(s)> \\<name> = <default4symbol(s)>";

str symbol2rsc(\int()) = "int";

str symbol2rsc(\bool()) = "bool";

str symbol2rsc(\real()) = "real";

str symbol2rsc(\str()) = "str";

str symbol2rsc(\datetime()) = "datetime";

str symbol2rsc(\list(Symbol s)) = "list[<symbol2rsc(s)>]";

str symbol2rsc(\tuple(list[Symbol] ss)) = "tuple[<intercalate(", ", [ symbol2rsc(s) | s <- ss])>]";

str symbol2rsc(label(str n, Symbol s)) = "<symbol2rsc(s)> \\<n>";

str symbol2rsc(adt(str n, list[Symbol] ps)) 
  = "<qualify(n)><ps != [] ? "[" + intercalate(", ", [ symbol2rsc(p) | p <- ps ]) + "]" : "">";
  
// str qualify("Maybe") = "util::Maybe::Maybe";
  
str qualify("Pointer") = "lionweb::pointer::Pointer";

str qualify("Id") = "lionweb::pointer::Id";

str qualify("Node") = "node";

str qualify("JSON") = "JSON";
  
default str qualify(str x) = x;
  
str default4symbol(\int()) = "0";

str default4symbol(\bool()) = "false";

str default4symbol(\real()) = "0.0";

str default4symbol(\str()) = "\"\"";

str default4symbol(\datetime()) = "DateTime::now()"; 

str default4symbol(\list(Symbol s)) = "[]";

str default4symbol(\label(str _, Symbol s)) = default4symbol(s);

str default4symbol(\tuple(list[Symbol] ss)) 
  = "\<<intercalate(", ", [ default4symbol(s) | s <- ss])>\>";

str default4symbol(adt("Pointer", list[Symbol] ps)) 
  = "null()";

str default4symbol(adt("Id", list[Symbol] ps)) 
  = "\"\"";

// str default4symbol(adt("Maybe", list[Symbol] ps)) 
//   = "nothing()";

// default for enumeration
// we need to find the production that 
// str default4symbol(adt(str x, [*L, cons(label(str y, adt(str x, [])), [], [], {})])) 
//    = "<y>()";
// str default4symbol(adt(str x, [cons(adt(str x, _), str y, [])])) {
//     // = "<y>()";
//     println("Matched the enumeration ADT!");
//     return "<y>()";
// }

// default str default4symbol(adt(str x, list[Symbol] ps)) { throw "No default value for ADT <x>"; }
default str default4symbol(adt(str x, list[Symbol] ps)) 
   = "No default value for ADT <x>";
