module lionweb::converter::model2json

import Type;
import IO;
import String;
import Set;
import Map;
import List;
import Node;
import util::UUID;

import lionweb::m3::lioncore;
import lionweb::m3::lionspace;
import lionweb::pointer;
import lionweb::converter::lionjson;
import lionweb::converter::lioncore2json;
import lionweb::converter::lioncore2ADT;

SerializationChunk ast2jsonmodel(node astRoot, LionSpace lionspace, Language language) {
    // Collect all nodes that we build, with their original AST nodes and Lioncore types
    map[Id, tuple[lionweb::converter::lionjson::Node jsonNode, node astNode, Classifier lionType]] builtNodes = ();
    // Collect all additional languages used in the node instantiation
    set[Language] usedLanguages = {language, lionspace.lookup(Pointer("LionCore-builtins")).language};

    // println(intercalate(", ", [le.name | le <- language.entities]));
    // println(intercalate(", ", [le.key | le <- language.entities]));

    // Visit AST and generate json nodes out of its nodes
    // Nodes are created only for the instances of classifiers
    // Pointer is our built-in type for managing references in Rascal and doesn't live in the lionspace
    visit (astRoot) {
        case node astNode: {
            if (typeOf(astNode).name != "Pointer") {
                println("Instantiate model node for the AST node <astNode> of type <typeOf(astNode)>");
                tuple[INamed, Language] nodeMetaType = lionspace.findByName(typeOf(astNode).name, language);
                if (INamed(IKeyed(LanguageEntity(Classifier classifier))) := nodeMetaType[0]){
                    Node jsonNode = instantiateLangEntity(classifier, astNode, nodeMetaType[1], lionspace);
                    builtNodes[jsonNode.id] = <jsonNode, astNode, classifier>;
                    usedLanguages += nodeMetaType[1];
                };
            }
        }
    };

    // Get rid of the fake nodes
    builtNodes = delete(builtNodes, "");

    // Visit AST and fill in the properties and cross references between the json nodes
    // ...
    
    
    // Check that the used languages are exceeding the set of languages this one depends on
    // println("Used languages: <[l.name | l <- usedLanguages]>");
    // println("Should be subset of: <[lionspace.lookup(l).language.name | l <- language.dependsOn] + language.name>");
    assert(usedLanguages <= toSet([lionspace.lookup(l).language | l <- language.dependsOn] + language));    

    return SerializationChunk(languages = [lang2json(l) | l <- usedLanguages], 
                                nodes = setNodesFeatures(builtNodes, language, lionspace));
}

Node instantiateLangEntity(Classifier(concept: Concept(abstract = false)), 
                            node astNode, Language language, LionSpace lionspace)
    = Node(langEntity2metapointer(LanguageEntity(Classifier(concept)), language),
                id = assignId(astNode),
                parent = "null");

// Node instantiateLangEntity(LanguageEntity(Classifier(pointer: Concept(name = "Pointer"))), 
//                             node astNode, LionSpace lionspace, Language language) {
//     return Node(MetaPointer());
// }

// An abstract concept should not be instantiated: in Rascal it wraps a concrete concept, so we skip it
Node instantiateLangEntity(Classifier(concept: Concept(abstract = true)), 
                            node astNode, Language language, LionSpace lionspace) 
    = Node(MetaPointer(), id = "");

// An interface should not be instantiated: in Rascal it wraps a concrete concept, so we skip it
Node instantiateLangEntity(Classifier(Interface interface), 
                            node astNode, Language language, LionSpace lionspace) 
    = Node(MetaPointer(), id = "");

Node instantiateLangEntity(Classifier(Annotation annotation), 
                            node astNode, Language language, LionSpace lionspace) 
    = Node(langEntity2metapointer(LanguageEntity(Classifier(annotation)), language),
            id = assignId(astNode),
            parent = "null");

list[Node] setNodesFeatures(map[Id, tuple[lionweb::converter::lionjson::Node jsonNode, 
                                                        node astNode, Classifier lionType]] builtNodes,
                            Language language, LionSpace lionspace) {
    for (Id i <- domain(builtNodes)) {
        list[value] astNonameChildren = getChildren(builtNodes[i].astNode);
        map[str, value] astLabeledChildren = getKeywordParameters(builtNodes[i].astNode);
        // println("Children of the node <builtNodes[i].astNode> are: <astChildren>");
        int nonameChildIndex = 0;
        for (Feature feature <- builtNodes[i].lionType.features) {
            value featureValue;
            if (feature.name in domain(astLabeledChildren)) {
                featureValue = astLabeledChildren[feature.name];            
            } else {
                featureValue = astNonameChildren[nonameChildIndex];
                nonameChildIndex += 1;
            };
            println("Value for the feature <feature.name> is <featureValue>");

            switch (feature) {
                case Feature(Property property): 
                    builtNodes[i].jsonNode.properties += [instantiateProperty(featureValue, property, language, lionspace)];
                case Feature(Link(Reference)): ;
                case Feature(Link(Containment)): ;
            };

        };
    };

    return toList({n.jsonNode | n <- range(builtNodes)});
}

// TODO: Annotation.annotates should be transformed into Node.annotations

lionweb::converter::lionjson::Property instantiateProperty(value val, 
                                                           lionweb::m3::lioncore::Property property, 
                                                           Language language, LionSpace lionspace)
    = lionweb::converter::lionjson::Property(langEntity2metapointer(lionspace.lookupInScope(property.\type, language).languageentity, language), 
                                                \value = "<val>");

Id assignId(node object) {
    try return getId(object);
    catch: return typeOf(object).name + "_" + getName(object) + "<uuidi()>";
}