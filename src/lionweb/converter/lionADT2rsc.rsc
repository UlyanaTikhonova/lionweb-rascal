module lionweb::converter::lionADT2rsc

import lionweb::converter::lioncore2ADT;
import lionweb::m3::lioncore;
import lionweb::pointer;

import IO;
import DateTime;
import Type;
import List;
import String;

void writeLionADTModule(Language lionlang) 
  = writeFile(|project://lionweb-rascal/output/<lionlang.name>.rsc|,
                "module <lionlang.name>
                '
                '// Code generated from lionweb language.
                '// Date: <now()>
                '
                'import lionweb::pointer;
                'import DateTime;
                '
                '<lion2rsc(lionlang)>");

str lion2rsc(Language lionlang)
    = langDependencies(lionlang.dependsOn) + langEntities(lionlang.entities, lionlang);

str langDependencies(list[Pointer[Language]] langDependencies)
    = "";

str langEntities(list[LanguageEntity] langEntities, Language lang) 
    = intercalate("\n\n", [production2rsc(entity2production(entity, lang)) | entity <-langEntities]);


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
      "<sub> <x>",
      *[ default4sub(s, x) | s <- subs ]
    ];

str default4sub(label(str fld, Symbol s), str kid)
  = "<symbol2rsc(s)> <fld> = <kid>.<fld>";

// The default case of the classifier (itself)
default str alternative2rsc(cons(label(str c, _), list[Symbol] ps, list[Symbol] kws, _))
  = "<c>(<intercalate("\n      , ", args)>)"
  when
    list[str] args := [ param2rsc(p) | p <- ps ] + [ keywordparam2rsc(k) | k <- kws ];
    
str param2rsc(label(str name, Symbol s)) = "<symbol2rsc(s)> <name>";

str keywordparam2rsc(label(str name, Symbol s)) = "<symbol2rsc(s)> <name> = <default4symbol(s)>";

str symbol2rsc(\int()) = "int";

str symbol2rsc(\bool()) = "bool";

str symbol2rsc(\real()) = "real";

str symbol2rsc(\str()) = "str";

str symbol2rsc(\datetime()) = "datetime";

str symbol2rsc(\list(Symbol s)) = "list[<symbol2rsc(s)>]";

str symbol2rsc(\tuple(list[Symbol] ss)) = "tuple[<intercalate(", ", [ symbol2rsc(s) | s <- ss])>]";

str symbol2rsc(label(str n, Symbol s)) = "<symbol2rsc(s)> <n>";

str symbol2rsc(adt(str n, list[Symbol] ps)) 
  = "<qualify(n)><ps != [] ? "[" + intercalate(", ", [ symbol2rsc(p) | p <- ps ]) + "]" : "">";
  
str qualify("Maybe") = "util::Maybe::Maybe";
  
str qualify("Ref") = "lang::ecore::Refs::Ref";

str qualify("Id") = "lang::ecore::Refs::Id";
  
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

str default4symbol(adt("Ref", list[Symbol] ps)) 
  = "null()";

str default4symbol(adt("Id", list[Symbol] ps)) 
  = "noId()";

str default4symbol(adt("Maybe", list[Symbol] ps)) 
  = "nothing()";

// default str default4symbol(adt(str x, list[Symbol] ps)) { throw "No default value for ADT <x>"; }

default str default4symbol(adt(str x, list[Symbol] ps)) 
   = "No default value for ADT <x>";
