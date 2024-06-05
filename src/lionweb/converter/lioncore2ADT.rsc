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

Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = true)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    set[Production] alts = {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

Production entity2production(LanguageEntity(Classifier(Concept cpt, abstract = false)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    Production definition = cons(label(cpt.name, cptADT),
                                 [feature2parameter(f, lang, lionspace) | f <- cpt.features, !hasDefaultValue(f)],
                                 [feature2parameter(f, lang, lionspace) | f <- cpt.features, hasDefaultValue(f)], 
                                 {});

    set[Production] alts = {definition} + 
                {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return choice(cptADT, alts);
}

Production entity2production(LanguageEntity(DataType(Enumeration enum)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol enumADT = adt(enum.name, []);
    set[Production] alts = {cons(label(el.name, enumADT), [], [], {}) | el <- enum.literals};
    return choice(enumADT, alts);
}

// Inheritance in Rascal:
// - extending classifier appears in the constructor of the parent classifier as a field
// - features of the extending classifier are inserted into the parent constructor
Production wrapInheritance(Classifier parent, Symbol parentADT, Classifier child, Language lang, LionSpace lionspace) {
    return cons(label(parent.name, parentADT), 
                [label(field(child.name), adt(child.name, []))],
                [feature2parameter(f, lang, lionspace) | f <- child.features],  
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

// To which category of parameters this feature belongs - depends on whether we can construct a default value for it
bool hasDefaultValue(Feature(Property _))
    = true;

bool hasDefaultValue(Feature(Link l))
    = l.optional || l.multiple;

// TODO: we might need a separate treatment for a reference (pointer or Id?)     

// Unfold features into parameters of the constructor
// An optional feature is represented by rascal list.
// A multiple link is represented by a rascal list too.
// Question: why is it not possible to pick up `optional` from a Feature directly (I have to unfold it into a Link and Property) 
Symbol feature2parameter(Feature(Link l, optional = true), Language lang, LionSpace lionspace) 
    = label(l.name, \list(type2symbol(LanguageEntity(findReferencedElement(l.\type, lang, lionspace)))));

Symbol feature2parameter(Feature(Link l, optional = false), Language lang, LionSpace lionspace) 
    = label(l.name, type2symbol(LanguageEntity(findReferencedElement(l.\type, lang, lionspace))));

Symbol feature2parameter(Feature(l:Link(_, multiple = true)), Language lang, LionSpace lionspace) 
    = label(l.name, \list(type2symbol(LanguageEntity(findReferencedElement(l.\type, lang, lionspace))))); 

Symbol feature2parameter(Feature(l:Link(_, optional = true, multiple = true)), Language lang, LionSpace lionspace) 
    = label(l.name, \list(type2symbol(LanguageEntity(findReferencedElement(l.\type, lang, lionspace)))));    

Symbol feature2parameter(Feature(Property p, optional = false), Language lang, LionSpace lionspace) 
    = label(p.name, type2symbol(LanguageEntity(findReferencedElement(p.\type, lang, lionspace))));  

Symbol feature2parameter(Feature(Property p, optional = true), Language lang, LionSpace lionspace) 
    = label(p.name, \list(type2symbol(LanguageEntity(findReferencedElement(p.\type, lang, lionspace)))));

// TODO: change above to use maybe and proper reference

// Find referenced type and transform it into a rascal symbol

Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "Integer", key="LionCore-builtins-Integer")))
    = \int();

Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "String", key="LionCore-builtins-String")))
    = \str();   

Symbol type2symbol(LanguageEntity(DataType(PrimitiveType pt, name = "Boolean", key="LionCore-builtins-Boolean")))
    = \bool();     

default Symbol type2symbol(LanguageEntity le)
    = adt(le.name, []);

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

        // TODO: if not in this language, search only in the languages that this language depends on.
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
