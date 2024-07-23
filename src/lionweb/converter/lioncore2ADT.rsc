module lionweb::converter::lioncore2ADT

import lionweb::m3::lioncore;
import lionweb::pointer;
import lionweb::m3::lionspace;

import Type;
import String;

import IO;
import vis::Text;

/*
 * Inheritance imlementation in Rascal (in the form of ADTs) requires propogating all features of 
 * a parent classifier to its children.
 */

Language flattenInheritance(Language lang) {
    for(Classifier class <- [c | le <- lang.entities, LanguageEntity(Classifier c) := le]) {
        set[Classifier] extensions = collectExtensions(class, lang);
        lang = visit(lang) {
            case Classifier subclass => flatclass 
                when subclass in extensions, flatclass := propogateFeaturesToChild(subclass, class)
        };
    };
    return lang;
}

Classifier propogateFeaturesToChild(Classifier(Concept child), Classifier parent) {
    child.features += parent.features;
    return Classifier(child);
}

Classifier propogateFeaturesToChild(Classifier(Interface child), Classifier parent) {
    child.features += parent.features;
    return Classifier(child);
}

Classifier propogateFeaturesToChild(Classifier(Annotation child), Classifier parent) {
    child.features += parent.features;
    return Classifier(child);
}

/* 
 * Mapping Lion Core to Rascal ADT (Symbols and Productions) 
 */

public list[str] BUILTIN_TYPES = ["Integer", "String", "Boolean"]; 

map[Symbol, Production] language2adt(Language lang, LionSpace lionspace = defaultSpace(lang)) {
    map[Symbol, Production] langADT = ();
    lang = flattenInheritance(lang);    //TODO: we might need to store all languages in the lionspace in the flattened form
    for(LanguageEntity entity <- lang.entities) {
        tuple[Symbol symb, Production prod] entADT = entity2production(entity, lang, lionspace = lionspace);
        langADT[entADT.symb] = entADT.prod;
    };
    return langADT;
}

// Abstract concept only wraps inheritance: choice over its extensions
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(cpt:Concept(abstract = true))), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol cptADT = adt(cpt.name, []);
    set[Production] alts = {wrapInheritance(Classifier(cpt), cptADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(cpt), lang)};
    return <cptADT, choice(cptADT, alts)>;
}

// Not abstract concept can be instantiated as it is or can be extended by other concepts: it has its own
//      constructor and alternative constructors for its extensions
// Features of a concept are added to parameters or keyword parameters, depending on whether its type
//      has a default value for it.
// TODO: order parameters/fields that don't have default value (to ensure a unique order of parameters)
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(cpt: Concept(abstract = false))), 
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

// Primitive type is a single constructor with no parameters
tuple[Symbol, Production] entity2production(LanguageEntity(DataType(PrimitiveType primType)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol primADT = adt(primType.name, []);
    return <primADT, choice(primADT, {\cons(label(primType.name, primADT), [], [], {})})>;
}

// Interface cannot be instantiated, it only wraps inheritance: choice over its extensions and implementations
// TODO: the features of the interface should be a common subset for all its extensions <- we should check it!
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(Interface interface)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol intrfADT = adt(interface.name, []);

    set[Production] alts = {wrapInheritance(Classifier(interface), intrfADT, ext, lang, lionspace) | 
                                                ext <- collectExtensions(Classifier(interface), lang)};
    return <intrfADT, choice(intrfADT, alts)>;
}

// TODO: entity2production for Annotation is a dummy constructor for now
tuple[Symbol, Production] entity2production(LanguageEntity(Classifier(Annotation annotation)), 
                             Language lang, 
                             LionSpace lionspace = defaultSpace(lang)) {
    Symbol annoADT = adt(annotation.name, []);
    return <annoADT, \cons(label(annotation.name, annoADT), [], [], {})>;
}

// Inheritance in Rascal:
// - extending classifier appears in the constructor of the parent classifier as a field
// - features of the extending classifier are inserted into the parent constructor as keyword parameters
//          whose values are delegated to the extending classifier
// - features of the parent classifier are already propogated/copied to the extending classifier
Production wrapInheritance(Classifier parent, Symbol parentADT, Classifier child, Language lang, LionSpace lionspace) {
    list[tuple[Symbol, bool]] childParameters = [feature2parameter(f, lang, lionspace) | f <- child.features];
    return cons(label(parent.name, parentADT), 
                [label(field(child.name), adt(child.name, []))],
                [param | <param, _> <- childParameters] + [identifierField()],  
                {\tag("subtype")});
}

// Extensions are both relations of `extends` and `implements`
set[Classifier] collectExtensions(Classifier class, Language lang) {
    set[Classifier] extensions = {};
    Id classId = class.key;

    // `implements` and `Interface.extends` can have many targets, 
    // `Annotation.extends` and `Concept.extends` only one target
    // that's why we use different patterns for their lists
    visit(lang) {
        case e:Concept(extends = [*L1, Pointer(classId)]): extensions += Classifier(e);
        case e:Concept(implements = [*L1, Pointer(classId), *L2]): extensions += Classifier(e);
        case e:Interface(extends = [*L1, Pointer(classId), *L2]): extensions += Classifier(e);
        case e:Annotation(extends = [*L1, Pointer(classId)]): extensions += Classifier(e);
        case e:Annotation(implements = [*L1, Pointer(classId), *L2]): extensions += Classifier(e);
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

