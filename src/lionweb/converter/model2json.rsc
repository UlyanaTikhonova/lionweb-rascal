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

// Collect all nodes that we build, with their original AST nodes and Lioncore types
map[Id, lionweb::converter::lionjson::Node] builtNodes = ();
// Collect all additional languages used in the node instantiation
set[Language] usedLanguages = {};

SerializationChunk ast2jsonmodel(node astRoot, LionSpace lionspace, Language language) {
    // Collect all nodes that we build, with their original AST nodes and Lioncore types
    // map[Id, lionweb::converter::lionjson::Node jsonNode] builtNodes = ();
    // Collect all additional languages used in the node instantiation
    // set[Language] usedLanguages = {language, lionspace.lookup(Pointer("LionCore-builtins")).language};
    usedLanguages = {language, lionspace.lookup(Pointer("LionCore-builtins")).language};

    // println(intercalate(", ", [le.name | le <- language.entities]));
    // println(intercalate(", ", [le.key | le <- language.entities]));

    // Recursively visit AST and generate json nodes out of its nodes
    // Nodes are created only for the instances of classifiers
    
    instantiateLangEntity(getNodeType(astRoot, language, lionspace), astRoot, language, lionspace, "null");
    println("Build <size(builtNodes)> nodes");

    // Get rid of the fake nodes
    // builtNodes = delete(builtNodes, "");

    // Visit AST and fill in the cross references between the json nodes
    // ...
    
    
    // Check that the used languages are exceeding the set of languages this one depends on
    // println("Used languages: <[l.name | l <- usedLanguages]>");
    // println("Should be subset of: <[lionspace.lookup(l).language.name | l <- language.dependsOn] + language.name>");
    assert(usedLanguages <= toSet([lionspace.lookup(l).language | l <- language.dependsOn] + language));    

    return SerializationChunk(languages = [lang2json(l) | l <- usedLanguages], 
                                nodes = toList(range(builtNodes)));
}

Classifier getNodeType(node astNode, Language language, LionSpace lionspace) {
    tuple[INamed, Language] nodeMetaType = lionspace.findByName(typeOf(astNode).name, language);
    if (INamed(IKeyed(LanguageEntity(Classifier classifier))) := nodeMetaType[0]){
        usedLanguages += nodeMetaType[1];
        return classifier;
    }    
    else throw "No classifier type found for the node <astNode>";
}

// Nodes can be directly instantiated for concrete concepts and annotations
Node instantiateLangEntity(classifier: Classifier(Concept(abstract = false)), 
                            node astNode, Language language, LionSpace lionspace, Id parentId)
    = instantiateNode(astNode, classifier, language, lionspace, parentId);

// An abstract concept should not be instantiated: in Rascal it wraps (eventually) a concrete concept
Node instantiateLangEntity(classifier: Classifier(Concept(abstract = true)), 
                            node astNode, Language language, LionSpace lionspace, Id parentId)  
    = unwrapInheritance(astNode, classifier, language, lionspace, parentId);

// Nodes can be directly instantiated for concrete concepts and annotations
Node instantiateLangEntity(classifier: Classifier(Annotation), 
                            node astNode, Language language, LionSpace lionspace, Id parentId) 
    = instantiateNode(astNode, classifier, language, lionspace, parentId);

// An interface should not be instantiated: in Rascal it wraps (eventually) a concrete concept
Node instantiateLangEntity(classifier: Classifier(Interface), 
                            node astNode, Language language, LionSpace lionspace, Id parentId) 
    = unwrapInheritance(astNode, classifier, language, lionspace, parentId);

// Get first unlabeled child of the node and consider it as the wrapped inheritent
Node unwrapInheritance(node astNode, Classifier lionType, Language language, LionSpace lionspace, Id parentId) {
    list[value] astChildren = getChildren(astNode);
    if (size(astChildren) == 0) throw "Cannot instantiate abstract concept or interface for: <astNode>";

    value wrappedNode = astChildren[0];
    wrappedType = getNodeType(wrappedNode, language, lionspace);

    set[Classifier] typeExtensions = collectExtensions(lionType, language);
    assert(wrappedType in typeExtensions);

    // Recursively invoke the mapping that proceeds according to the Lioncore language entity type
    return instantiateLangEntity(wrappedType, wrappedNode, language, lionspace, parentId);
}

// To construct a node, we set up its metatype, parent, id, and fill in its features
// The containment links recursively invoke the instantiateLangEntity mapping
// IMPORTANT: here we assume that the order of features is preserved in the list of unlabeled parameters in the Rascal AST
Node instantiateNode(node astNode, Classifier lionType, Language language, LionSpace lionspace, Id parentId) {
    Node jsonNode = Node(langEntity2metapointer(LanguageEntity(lionType), language),
                         id = assignId(astNode),
                         parent = parentId);

    list[value] astNonameChildren = getChildren(astNode);
    map[str, value] astLabeledChildren = getKeywordParameters(astNode);
    // println("Children of the node <astNode> are: <astChildren>");
    int nonameChildIndex = 0;
    for (Feature feature <- lionType.features) {
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
                jsonNode.properties += [instantiateProperty(featureValue, property, language, lionspace)];
            // case Feature(Link(Reference)): ;    // here we need to find original nodes in the builtnodes
            case Feature(Link(Containment containment)):
                jsonNode.containments += [instantiateContainment(featureValue, containment, language, lionspace, jsonNode.id)];
        };

    };

    // Store the constructed node
    builtNodes[jsonNode.id] = jsonNode;
    return jsonNode;
}

lionweb::converter::lionjson::Property instantiateProperty(value val, 
                                                           lionweb::m3::lioncore::Property property, 
                                                           Language language, LionSpace lionspace)
    = lionweb::converter::lionjson::Property(
                    feature2metapointer(lionspace.findInScope(language.key, property.key).feature, language), 
                    \value = "<val>");

// instantiateLangEntity (but take care of optional and multiple)
lionweb::converter::lionjson::Containment instantiateContainment(value val, 
                                                           lionweb::m3::lioncore::Containment containment, 
                                                           Language language, LionSpace lionspace, Id parentId) {
    list[Id] childrenIds = [];

    void processChildNode(node astChild) {
        Classifier childType = getNodeType(astChild, language, lionspace);
        Classifier containmentType = lionspace.lookupInScope(containment.\type, language).languageentity.classifier;
        assert(childType in collectExtensions(containmentType, language) + containmentType);
        Node childNode = instantiateLangEntity(childType, astChild, language, lionspace, parentId);
        childrenIds += childNode.id;
    }

    // the value is the child node
    if (!containment.optional && !containment.multiple) {
        processChildNode(val);
    } else {  // the value is the list of child nodes
        list[node] astChildren = typeCast(#list[node], val);
        for (node astChild <- astChildren) {            
            processChildNode(astChild);
        };
    };

    return lionweb::converter::lionjson::Containment(
                    feature2metapointer(lionspace.findInScope(language.key, containment.key).feature, language),
                    children = childrenIds
    );
}

Id assignId(node object) {
    try return getId(object);
    catch: return typeOf(object).name + "_" + getName(object) + "<uuidi()>";
}



// TODO: Annotation.annotates should be transformed into Node.annotations