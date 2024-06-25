module lionweb::converter::json2lioncore

import lionweb::converter::lionjson;
import lionweb::m3::lioncore;
import lionweb::pointer;

list[Language] jsonlang2lioncore(SerializationChunk json) {
    // langChunk = json;

    // Lionweb built-in data types
    // Language lionBuiltinLanguage = Language(
    //         name = "Built-in DataTypes", 
    //         key = "LionCore-builtins", 
    //         version = "2023.1",
    //         entities = [LanguageEntity(DataType(PrimitiveType(name = "String", key = "LionCore-builtins-String"))),
    //                     LanguageEntity(DataType(PrimitiveType(name = "Boolean", key = "LionCore-builtins-Boolean"))),
    //                     LanguageEntity(DataType(PrimitiveType(name = "Integer", key = "LionCore-builtins-Integer")))]);

    list[Language] langs = [];
    for(Node langnode <- [n | Node n <- json.nodes, n.classifier.key == "Language"]) {
        langs = langs + lionweb::m3::lioncore::Language(
                    name = getName(langnode), 
                    key = getKey(langnode), 
                    version = getStrValue(langnode, "Language-version"), 
                    entities = [node2entity(n, json) | 
                        Node n <- collectNodes(getContainments(langnode, "Language-entities"), json)], 
                    dependsOn = [Pointer(l.key, info = l.version) | l <- json.languages]);
    }

    return langs;
}

/* TODO: the following requirement is not taken care of for now: 
    The children node can be contained in the processed document, but also can be _outside_ the processed document 
    (i.e. not contained in the processed document). */
list[Node] collectNodes(list[Id] nodeIds, SerializationChunk langChunk) 
    = [n | Node n <- langChunk.nodes, Id nodeid <- nodeIds, n.id == nodeid];


// ------------------------------ Getters from json for lioncore attributes ----------------------------

str getStrValue(Node jsonnode, str propertyName)
    = [p | Property p <- jsonnode.properties, p.property.key == propertyName][0].\value;

str getName(Node jsonnode) 
    = getStrValue(jsonnode, "LionCore-builtins-INamed-name");

Id getKey(Node jsonnode)
    = getStrValue(jsonnode, "IKeyed-key");

bool getBoolValue(Node jsonnode, str propertyName)
    = [p | Property p <- jsonnode.properties, p.property.key == propertyName][0].\value == "true";

list[Id] getContainments(Node jsonnode, str propertyName)
    = [c | Containment c <- jsonnode.containments, c.containment.key == propertyName][0].children;

list[ReferenceTarget] getReferences(Node jsonnode, str propertyName)
    = [r | Reference r <- jsonnode.references,  r.reference.key == propertyName][0].targets;

// ------------------------- Unfold abstract classes and generate concrete types ----------------------------

LanguageEntity node2entity(Node jsonnode, SerializationChunk langChunk) {
    LanguageEntity entity;    
    switch (jsonnode.classifier.key) {
        case "Concept": entity = LanguageEntity(Classifier(node2concept(jsonnode, langChunk)));
        case "Interface": entity = LanguageEntity(Classifier(node2interface(jsonnode, langChunk)));
        case "Annotation": entity = LanguageEntity(Classifier(node2annotation(jsonnode, langChunk)));
        case "PrimitiveType": entity = LanguageEntity(DataType(node2primitivetype(jsonnode)));
        case "Enumeration": entity = LanguageEntity(DataType(node2enumeration(jsonnode, langChunk)));
    }
    return entity;
}

Concept node2concept(Node jsonnode, SerializationChunk langChunk)
    = lionweb::m3::lioncore::Concept(name = getName(jsonnode),
              key = getKey(jsonnode),
              features = [node2feature(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Classifier-features"), langChunk)],
              abstract = getBoolValue(jsonnode, "Concept-abstract"),
              partition = getBoolValue(jsonnode, "Concept-partition"),
              extends = [Pointer(ext.reference, info = ext.resolveInfo) | ext <- getReferences(jsonnode, "Concept-extends")], 
              implements = [Pointer(imp.reference, info = imp.resolveInfo) | imp <- getReferences(jsonnode, "Concept-implements")]);

Interface node2interface(Node jsonnode, SerializationChunk langChunk)
    = lionweb::m3::lioncore::Interface(name = getName(jsonnode),
              key = getKey(jsonnode),
              features = [node2feature(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Classifier-features"), langChunk)],
              extends = [Pointer(ext.reference, info = ext.resolveInfo) | ext <- getReferences(jsonnode, "Interface-extends")]);

Annotation node2annotation(Node jsonnode, SerializationChunk langChunk)
    = lionweb::m3::lioncore::Annotation(name = getName(jsonnode),
              key = getKey(jsonnode),
              features = [node2feature(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Classifier-features"), langChunk)],
              annotates = [Pointer(ant.reference, info = ant.resolveInfo) | ant <- getReferences(jsonnode, "Annotation-annotates")], 
              extends = [Pointer(ext.reference, info = ext.resolveInfo) | ext <- getReferences(jsonnode, "Annotation-extends")], 
              implements = [Pointer(imp.reference, info = imp.resolveInfo) | imp <- getReferences(jsonnode, "Annotation-implements")]);

Enumeration node2enumeration(Node jsonnode, SerializationChunk langChunk)
    = lionweb::m3::lioncore::Enumeration(name = getName(jsonnode), key = getKey(jsonnode),
                literals = [node2enumliteral(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Enumeration-literals"), langChunk)]);

EnumerationLiteral node2enumliteral(Node jsonnode)
    = lionweb::m3::lioncore::EnumerationLiteral(name = getName(jsonnode), key = getKey(jsonnode));

PrimitiveType node2primitivetype(Node jsonnode)
    = lionweb::m3::lioncore::PrimitiveType(name = getName(jsonnode), key = getKey(jsonnode));

Feature node2feature(Node jsonnode) {
    Feature feature;
    switch (jsonnode.classifier.key) {
        case "Property": feature = Feature(node2property(jsonnode));
        case "Reference": feature = Feature(Link(node2reference(jsonnode)));
        case "Containment": feature = Feature(Link(node2containment(jsonnode)));
    }
    return feature;
}

Property node2property(Node jsonnode)
    = lionweb::m3::lioncore::Property(
                name = getName(jsonnode),
                key = getKey(jsonnode),
                optional = getBoolValue(jsonnode, "Feature-optional"),
                \type = Pointer(getReferences(jsonnode, "Property-type")[0].reference,
                                info = getReferences(jsonnode, "Property-type")[0].resolveInfo));
                // type is a reference that we get via getReferences(jsonnode, "Property-type")
                // here it is a reference to the Java Integer type: "LionCore-builtins-Integer" (this PrimitiveType is not within our json!)

Reference node2reference(Node jsonnode)
    = lionweb::m3::lioncore::Reference(
                name = getName(jsonnode),
                key = getKey(jsonnode),
                optional = getBoolValue(jsonnode, "Feature-optional"),
                multiple = getBoolValue(jsonnode, "Link-multiple"),
                \type = Pointer(getReferences(jsonnode, "Link-type")[0].reference,
                            info = getReferences(jsonnode, "Link-type")[0].resolveInfo));

Containment node2containment(Node jsonnode)
    = lionweb::m3::lioncore::Containment(
                name = getName(jsonnode),
                key = getKey(jsonnode),
                optional = getBoolValue(jsonnode, "Feature-optional"),
                multiple = getBoolValue(jsonnode, "Link-multiple"),
                \type = Pointer(getReferences(jsonnode, "Link-type")[0].reference,
                            info = getReferences(jsonnode, "Link-type")[0].resolveInfo));                