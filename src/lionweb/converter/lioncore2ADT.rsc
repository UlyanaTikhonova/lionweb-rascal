module lionweb::converter::lioncore2ADT

import lionweb::m3::lioncore;
import lionweb::pointer;
import lionweb::m3::lionspace;

import IO;
import Type;
import List;
import String;

/* 
 * Mapping Lion Core to Rascal ADT (Symbols and Productions) 
 */

list[str] BUILTIN_TYPES = ["Integer", "String", "Boolean"]; 

// Abstract concept only wraps inheritance: choice over its extensions
Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = true)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    set[Production] alts = {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

// Not abstract concept has its own features and might be extended by other concepts
// Features of a concept are added to parameters or keyword parameters, depending on whether its type
// has a default value for it.
Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = false)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    list[tuple[Symbol, bool]] entityParameters = [feature2parameter(f, lang, lionspace) | f <- cpt.features];
    Production definition = cons(label(cpt.name, cptADT),
                                 [param | <param, hasDefault> <- entityParameters, hasDefault == false],
                                 [param | <param, hasDefault> <- entityParameters, hasDefault == true], 
                                 {});

    set[Production] alts = {definition} + 
                {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

// Enumeration is a choice over its literals
Production entity2production(LanguageEntity(DataType(Enumeration enum)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol enumADT = adt(enum.name, []);
    set[Production] alts = {cons(label(el.name, enumADT), [], [], {}) | el <- enum.literals};
    return choice(enumADT, alts);
}

// TODO: entity2production for Interface and Annotation

// Inheritance in Rascal:
// - extending classifier appears in the constructor of the parent classifier as a field
// - features of the extending classifier are inserted into the parent constructor
Production wrapInheritance(Classifier parent, Symbol parentADT, Classifier child, Language lang, LionSpace lionspace) {
    list[tuple[Symbol, bool]] childParameters = [feature2parameter(f, lang, lionspace) | f <- child.features];
    return cons(label(parent.name, parentADT), 
                [label(field(child.name), adt(child.name, []))],
                [param | <param, _> <- childParameters],  
                {\tag("subtype")});
}

str field(str x) = "\\<uncapitalize(x)>";

set[Classifier] collectExtensions(Classifier class, Language lang) {
    set[Classifier] extensions = {};
    Id classId = class.key;

    visit(lang) {
        case e:Concept(extends = [*L, Pointer(classId)]): extensions = extensions + {Classifier(e)};
        case e:Interface(extends = [*L, Pointer(classId)]): extensions = extensions + {Classifier(e)};
        case e:Annotation(extends = [*L, Pointer(classId)]): extensions = extensions + {Classifier(e)};
    };

    return extensions;
}

// Unfold features into parameters of the constructor
// - An optional feature is represented by rascal list (default = []).
// - A multiple link is represented by a rascal list too (default = []).
// - Whether the feature has a default value depends on its type, so it is also calculated here.
// Question: why is it not possible to pick up `optional` from a Feature directly (I have to unfold it into a Link and Property) 

tuple[Symbol, bool] feature2parameter(Feature(Link l, optional = true), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(l.\type, lang, lionspace));    
    return <label(field(l.name), \list(type2symbol(featureType))), true>;
}

tuple[Symbol, bool] feature2parameter(Feature(Link l, optional = false), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(l.\type, lang, lionspace));
    return <label(field(l.name), type2symbol(featureType)), false>;
}

tuple[Symbol, bool] feature2parameter(Feature(l:Link(_, multiple = true)), Language lang, LionSpace lionspace)  {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(l.\type, lang, lionspace));
    return <label(field(l.name), \list(type2symbol(featureType))), true>;
} 

tuple[Symbol, bool] feature2parameter(Feature(l:Link(_, optional = true, multiple = true)), Language lang, LionSpace lionspace)  {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(l.\type, lang, lionspace));
    return <label(field(l.name), \list(type2symbol(featureType))), true>;
}

tuple[Symbol, bool] feature2parameter(Feature(Property p, optional = false), Language lang, LionSpace lionspace)  {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(p.\type, lang, lionspace));
    return <label(field(p.name), type2symbol(featureType)), featureType.name in BUILTIN_TYPES>;
} 

tuple[Symbol, bool] feature2parameter(Feature(Property p, optional = true), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = LanguageEntity(findReferencedElement(p.\type, lang, lionspace));
    return <label(field(p.name), \list(type2symbol(featureType))), true>;
}

// TODO: change above to use Maybe and proper reference
// (including the default value)

// Transform type into a rascal symbol
Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "Integer", key="LionCore-builtins-Integer")))
    = \int();

Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "String", key="LionCore-builtins-String")))
    = \str();   

Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "Boolean", key="LionCore-builtins-Boolean")))
    = \bool();

default Symbol type2symbol(LanguageEntity le)
    = adt(le.name, []);

// Find the referenced type or the used language 
&T findReferencedElement(Pointer[&T] pointer, Language lang, LionSpace lionspace) {
    list[&T] elements = [];

    if (pointer != null()) {
        Id elemId = pointer.uid;
        visit(lang) {
            // only concrete classes are possible here
            // Question: is there a smarter way to do this using &T?
            case e:Concept(key = elemId): elements = elements + [Classifier(e)];
            case e:Interface(key = elemId): elements = elements + [Classifier(e)];
            case e:Annotation(key = elemId): elements = elements + [Classifier(e)];
            case e:PrimitiveType(key = elemId):  elements = elements + [DataType(e)];
            case e:Enumeration(key = elemId): elements = elements + [DataType(e)];
            case e:Language(key = elemId): elements = elements + [e];
        };

        // TODO: if not in this language, search only in the languages that this language depends on (now we look in the whole lion space)
        if (size(elements) == 0) {
            println("lion space: <lionspace>");
            &T elem = lionspace.lookup(pointer)[0];
            println("Found the element: <elem>");
            elements = elements + [elem];
        }
    }
    // TODO: validate that the found element is actually of type &T

    // if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
    if (size(elements) == 0) elements = [DataType(PrimitiveType(name = "not found type"))];
    if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";
    
    return elements[0];
}

// -------------------------------- Tests -------------------------------------------------------------
