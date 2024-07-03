module lionweb::converter::lioncore2ADT

import lionweb::m3::lioncore;
import lionweb::pointer;
import lionweb::m3::lionspace;

import Type;
import String;

/* 
 * Mapping Lion Core to Rascal ADT (Symbols and Productions) 
 */

public list[str] BUILTIN_TYPES = ["Integer", "String", "Boolean"]; 

map[Symbol, Production] language2adt(Language lang, LionSpace lionspace = defaultSpace(lang)) {
    map[Symbol, Production] langADT = ();
    for(LanguageEntity entity <- lang.entities) {
        tuple[Symbol symb, Production prod] entADT = entity2production(entity, lang, lionspace = lionspace);
        langADT[entADT.symb] = entADT.prod;
    };
    return langADT;
}

// Abstract concept only wraps inheritance: choice over its extensions
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(Concept cpt, abstract = true)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    set[Production] alts = {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return <cptADT, choice(cptADT, alts)>;
}

// Not abstract concept has its own features and might be extended by other concepts
// Features of a concept are added to parameters or keyword parameters, depending on whether its type
// has a default value for it.
// TODO: order parameters/fields that don't have default value 
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(Concept cpt, abstract = false)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    list[tuple[Symbol, bool]] entityParameters = [feature2parameter(f, lang, lionspace) | f <- cpt.features];
    Production definition = cons(label(cpt.name, cptADT),
                                 [param | <param, hasDefault> <- entityParameters, hasDefault == false],
                                 [param | <param, hasDefault> <- entityParameters, hasDefault == true] + [identifierField()], 
                                 {});

    set[Production] alts = {definition} + 
                {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return <cptADT, choice(cptADT, alts)>;
}

// Enumeration is a choice over its literals
tuple[Symbol, Production] entity2production(LanguageEntity(DataType(Enumeration enum)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol enumADT = adt(enum.name, []);
    set[Production] alts = {cons(label(el.name, enumADT), [], [], {}) | el <- enum.literals};
    return <enumADT, choice(enumADT, alts)>;
}

// TODO: entity2production for Interface and Annotation

// Inheritance in Rascal:
// - extending classifier appears in the constructor of the parent classifier as a field
// - features of the extending classifier are inserted into the parent constructor
Production wrapInheritance(Classifier parent, Symbol parentADT, Classifier child, Language lang, LionSpace lionspace) {
    list[tuple[Symbol, bool]] childParameters = [feature2parameter(f, lang, lionspace) | f <- child.features];
    return cons(label(parent.name, parentADT), 
                [label(field(child.name), adt(child.name, []))],
                [param | <param, _> <- childParameters] + [identifierField()],  
                {\tag("subtype")});
}

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

str field(str x) = "<uncapitalize(x)>";

// Referencing in lionweb Rascal:
Symbol identifierField()
    = label("uid", adt("Id", []));

// type parameter here corresponds to the type of the referenced entity
Symbol referenceType(Symbol refTypeAdt)
    = \adt("Pointer", [refTypeAdt]);

// Unfold features into parameters of the constructor
// - An optional feature is represented by rascal list (default = []).
// - A multiple link is represented by a rascal list too (default = []).
// - Whether the feature has a default value depends on its type, so it is also calculated here.
// Question: why is it not possible to pick up `optional` from a Feature directly (I have to unfold it into a Link and Property) 

// TODO: the case of link should be split for Reference and Containment, to support referencing
tuple[Symbol, bool] feature2parameter(Feature(Link(Containment containmnt)), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = findReferencedElement(containmnt.\type, lang, lionspace);
    if (containmnt.optional || containmnt.multiple)  
        return <label(field(containmnt.name), \list(type2symbol(featureType))), true>;
    else 
        return <label(field(containmnt.name), type2symbol(featureType)), false>;
}

tuple[Symbol, bool] feature2parameter(Feature(Link(Reference ref)), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = findReferencedElement(ref.\type, lang, lionspace);
    Symbol refTypeAdt = type2symbol(featureType);
    if (ref.optional || ref.multiple)  
        return <label(field(ref.name), \list(referenceType(refTypeAdt))), true>;
    else 
        return <label(field(ref.name), referenceType(refTypeAdt)), false>;
}

tuple[Symbol, bool] feature2parameter(Feature(Property p, optional = false), Language lang, LionSpace lionspace)  {
    LanguageEntity featureType = findReferencedElement(p.\type, lang, lionspace);
    return <label(field(p.name), type2symbol(featureType)), featureType.name in BUILTIN_TYPES>;
} 

tuple[Symbol, bool] feature2parameter(Feature(Property p, optional = true), Language lang, LionSpace lionspace) {
    LanguageEntity featureType = findReferencedElement(p.\type, lang, lionspace);
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
LanguageEntity findReferencedElement(Pointer[&T] pointer, Language lang, LionSpace lionspace) 
    = lionspace.lookupInScope(pointer, lang).languageentity;

