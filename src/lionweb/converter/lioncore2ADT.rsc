module lionweb::converter::lioncore2ADT

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


// ---------------------------- Mapping Lion Core to Rascal ADT (Symbols and Productions) ----------------------

// Question: can we query the values of attributes here: abstract = true ?
Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = true)), Language lang) {
    Symbol cptADT = adt(cpt.name, []);
    set[Production] alts = {wrapInheritance(Classifier(cpt), cptADT, ext) | 
                                                            ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = false)), Language lang) {
    Symbol cptADT = adt(cpt.name, []);
    Production definition = cons(label(cpt.name, cptADT), 
                                 [feature2parameter(f) | f <- cpt.features], [],
                                //  [], [feature2parameter(f) | f <- cpt.features], 
                                 {});

    set[Production] alts = {definition} + 
                {wrapInheritance(Classifier(cpt), cptADT, ext) | ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

Production entity2production(LanguageEntity(DataType(Enumeration enum)), Language lang) {
    Symbol enumADT = adt(enum.name, []);
    set[Production] alts = {cons(label(el.name, enumADT), [], [], {}) | el <- enum.literals};
    return choice(enumADT, alts);
}

Production wrapInheritance(Classifier parent, Symbol parentADT, Classifier child) {
    return cons(label(parent.name, parentADT), 
                [label(field(child.name), adt(child.name, []))], // extending classifier appears in the constructor of the parent classifier as a field
                [], // features of the extending classifier are inserted into the parent constructor 
                {});
}

// Question: can I generalize here? (not Concept but classifier)
set[Classifier] collectExtensions(Classifier class, Language lang) {
    return {};
}

// TODO: if the feature is optional, use rascal Maybe
Symbol feature2parameter(Feature f) {
    // Classifier featureType = findNode(f.\type, lang);
    return label(f.name, adt("reference to type", []));
}

str field(str x) = "\\<uncapitalize(x)>";

// --------------------------- Serialize Rascal ADT in Rascal syntax --------------------------------------

str production2rsc(choice(Symbol typeDef, set[Production] alterns)) 
  = "data <typeDef.name>\n  = <intercalate("\n  | ", [ alternative2rsc(p) | Production p <- alterns ])>
    '  ;";


// str default4subclass(label(str fld, Symbol s), str kid)
//   = "<symbol2rsc(s)> <fld> = <kid>.<fld>";

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

default str default4symbol(adt(str x, list[Symbol] ps)) { throw "No default value for ADT <x>"; }

// -------------------------------- Tests -------------------------------------------------------------
