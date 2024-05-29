module lionweb::converter::json2lioncore

import IO;
import List;
import Exception;
import lionweb::converter::lionjson;
import lionweb::m3::lioncore;
import lionweb::pointer;

// Question: I use global variable here, is it ok idea?
SerializationChunk langChunk;

list[Language] jsonlang2lioncore(SerializationChunk json) {
    langChunk = json;

    list[Language] langs = [];
    for(Node langnode <- [n | Node n <- json.nodes, n.classifier.key == "Language"]) {
        langs = langs + lionweb::m3::lioncore::Language(
                    name = getName(langnode), 
                    key = getKey(langnode), 
                    version = getStrValue(langnode, "Language-version"), 
                    entities = [node2entity(n) | Node n <- collectNodes(getContainments(langnode, "Language-entities"))], 
                    dependsOn = []);
    }

    return langs;
}

/* TODO: the following requirement is not taken care of for now: 
    The children node can be contained in the processed document, but also can be _outside_ the processed document 
    (i.e. not contained in the processed document). */
list[Node] collectNodes(list[Id] nodeIds) 
    = [n | Node n <- langChunk.nodes, Id nodeid <- nodeIds, n.id == nodeid];


// ------------------------------ Getters from json for lioncore attributes ----------------------------

str getStrValue(Node jsonnode, str propertyName)
    = [p | Property p <- jsonnode.properties, p.property.key == propertyName][0].\value;

str getName(Node jsonnode) 
    = getStrValue(jsonnode, "LionCore-builtins-INamed-name");

Id getKey(Node jsonnode)
    = getStrValue(jsonnode, "IKeyed-key");

// Question: Not a nice way to parse the boolean value, can we invoke parse(#bool) or make(#bool) here?
bool getBoolValue(Node jsonnode, str propertyName)
    = [p | Property p <- jsonnode.properties, p.property.key == propertyName][0].\value == "true";

list[Id] getContainments(Node jsonnode, str propertyName)
    = [c | Containment c <- jsonnode.containments, c.containment.key == propertyName][0].children;

list[ReferenceTarget] getReferences(Node jsonnode, str propertyName)
    = [r | Reference r <- jsonnode.references,  r.reference.key == propertyName][0].targets;

// ------------------------- Unfold abstract classes and generate concrete types ----------------------------

LanguageEntity node2entity(Node jsonnode) {
    LanguageEntity entity;    
    switch (jsonnode.classifier.key) {
        case "Concept": entity = LanguageEntity(Classifier(node2concept(jsonnode)));
        case "Interface": entity = LanguageEntity(Classifier(Interface()));
        case "Annotation": entity = LanguageEntity(Classifier(Annotation()));
        case "PrimitiveType": entity = LanguageEntity(DataType(PrimitiveType()));
        case "Enumeration": entity = LanguageEntity(DataType(node2enumeration(jsonnode)));
    }
    return entity;
}

// Question: I get CallFailed for constructor Concept()
Concept node2concept(Node jsonnode)
    = lionweb::m3::lioncore::Concept(name = getName(jsonnode),
              key = getKey(jsonnode),
              features = [node2feature(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Classifier-features"))],
              abstract = getBoolValue(jsonnode, "Concept-abstract"),
              partition = getBoolValue(jsonnode, "Concept-partition"),
              extends = [], implements = []);

Enumeration node2enumeration(Node jsonnode)
    = lionweb::m3::lioncore::Enumeration(name = getName(jsonnode), key = getKey(jsonnode),
                literals = [node2enumliteral(n) | 
                    Node n <- collectNodes(getContainments(jsonnode, "Enumeration-literals"))]);

EnumerationLiteral node2enumliteral(Node jsonnode)
    = lionweb::m3::lioncore::EnumerationLiteral(name = getName(jsonnode), key = getKey(jsonnode));

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
                \type = pointer(getReferences(jsonnode, "Property-type")[0].reference));
                // type is a reference that we get via getReferences(jsonnode, "Property-type")
                // here it is a reference to the Java Integer type: "LionCore-builtins-Integer" (this PrimitiveType is not within our json!)

Reference node2reference(Node jsonnode)
    = lionweb::m3::lioncore::Reference(
                name = getName(jsonnode),
                key = getKey(jsonnode),
                optional = getBoolValue(jsonnode, "Feature-optional"),
                multiple = getBoolValue(jsonnode, "Link-multiple"));

Containment node2containment(Node jsonnode)
    = lionweb::m3::lioncore::Containment(
                name = getName(jsonnode),
                key = getKey(jsonnode),
                optional = getBoolValue(jsonnode, "Feature-optional"),
                multiple = getBoolValue(jsonnode, "Link-multiple"));                