module lionweb::converter::json2model

import Type;
import IO;
import String;
import Map;
import List;

import lionweb::pointer;
import lionweb::converter::lionjson;
import lionweb::converter::lioncore2ADT;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

// TODO: Where to store langADT? Should it be in the lionspace too?
map[Id, value] jsonlang2model(SerializationChunk json, LionSpace lionspace,  map[Symbol, Production] langADT) {
    map[Id, value] builtNodes = ();

    value lion2value(IKeyed(LanguageEntity(Classifier(Concept cpt, abstract = false))),
                        Language lang,
                        lionweb::converter::lionjson::Node modelNode) {
        // Get the rascal (ADT) type of the lion language entity
        Symbol cptADT = adt(cpt.name, []);
        Production prod = langADT[cptADT];
        type[value] cptType = type(cptADT, (cptADT : prod));

        // Construct values of the parameters
        paramValues = [];
        keywordParamValues = ();

        for(Feature feature <- cpt.features) {
            println("Get the value for the feature: <feature.name>");
            value featureValue = getFeatureValue(feature, lang, modelNode);
            println("     the value for the feature is: <featureValue>");
            // determine to which list of parameters this one belongs
            tuple[Symbol smbl, bool hasDefault] child = feature2parameter(feature, lang, lionspace);
            if (child.hasDefault) {
                keywordParamValues[field(feature.name)] = featureValue;
            } else {
                paramValues += featureValue; // here the order might be wrong!!!
            };
        };        
        
        println("Constructed parameters: <paramValues>");
        println("Constructed keyword parameters: <keywordParamValues>");
        // Instantiate the type with the values
        return make(cptType, cpt.name, paramValues, keywordParamValues);
    };

    value property2value(IKeyed(LanguageEntity(DataType dataType)), Language lang,
                        str propertyValue) {
        if (dataType.name in lionweb::converter::lioncore2ADT::BUILTIN_TYPES) {
            switch (dataType.name) {
                case "Integer": return toInt(propertyValue);
                case "String": return propertyValue;
                case "Boolean": return propertyValue == "true";
            }
        };
        // If not a built-in type then get the rascal (ADT) type of the lion language entity
        Symbol datatypeADT = adt(dataType.name, []);
        Production prod = langADT[datatypeADT];
        type[value] datatypeType = type(datatypeADT, (datatypeADT : prod));

        // Find the name of the constructor using the key in the child value
        tuple[IKeyed ikeyed, Language lang] enumLiteral = lionspace.findType(lang.key, propertyValue);
        if (IKeyed(EnumerationLiteral el) := enumLiteral.ikeyed) {
            return make(datatypeType, el.name, [], ());
        };

        return 20000;
    };

    // For property - also find the proper ADT by its key, and add default conversions for the built-in types
    value getFeatureValue(Feature(Property propertyFeature), Language lang,
                            lionweb::converter::lionjson::Node parentNode) {
        value childValue;   // In our json of the instance model we miss operation property!!
        
        // search for the corresponding property in the json node
        for(lionweb::converter::lionjson::Property jsonProperty <- parentNode.properties) {
            if(jsonProperty.property.key == propertyFeature.key) {
                println("Search the lion type for the property: <jsonProperty>");
                tuple[IKeyed ikeyed, Language lang] lionProperty = lionspace.findType(jsonProperty.property.language, jsonProperty.property.key);
                if (IKeyed(Feature(Property lp)) := lionProperty.ikeyed) {
                    println("Search the lion type for the property: <lp.\type.uid>");
                    IKeyed childType = lionspace.findTypeInAll(lp.\type.uid); // TODO: refactor this!!
                    // this is the key for the not-built-in types
                    println("Invoke property2value for the node: <jsonProperty>");
                    childValue = property2value(childType, lang, jsonProperty.\value);
                    break;
                };                
            };
        };
        // convert string into the type of the feature
        // Question: how?? we need to parse here or so? --> looks like a generator of a translator is needed for these cases
        if (propertyFeature.optional == true)
            return [childValue];
        return childValue;
    }

    value getFeatureValue(Feature(Link(Containment containmentFeature)), Language lang,
                            lionweb::converter::lionjson::Node parentNode) {
        list[Id] jsonChildren = [];
        // search for the corresponding containment in the json node
        for(jsonContainment <- parentNode.containments) {
            if(jsonContainment.containment.key == containmentFeature.key) {
                jsonChildren = jsonContainment.children;
                break;
            };
        };
        // Construct values from the json nodes
        list[value] childValues = [];
        for(Id childId <- jsonChildren) {
            if (!(childId in builtNodes)) {
                lionweb::converter::lionjson::Node childnode = getJsonNode(childId);
                tuple[IKeyed ikeyed, Language lang] childType = lionspace.findType(childnode.classifier.language, childnode.classifier.key);
                println("Invoke lion2value for the node: <childnode>");
                value childValue = lion2value(childType.ikeyed, lang, childnode);
                // The original feature type (parameter) might be an inherited type of the declared feature type (argument)
                // then we need to wrap it into the chain of the corresponding constructors.
                println("Wrap inheritance for <childValue>");
                childValue = wrapInheritance(childValue, childType.ikeyed, lionspace.lookup(containmentFeature.\type)[0]);
                // ... store the resulting value in the built nodes
                builtNodes[childId] = childValue;
            };
            childValues += builtNodes[childId];
        }; 

        // if the feature is multiple or optional - return list
        if (containmentFeature.multiple == true || containmentFeature.optional == true)
            return childValues;                
        return childValues[0];
    }

    // TODO: add getFeatureValue for the reference

    // TODO: generalize the following for interface and annotation
    value wrapInheritance(value childValue, 
                            IKeyed(LanguageEntity(Classifier(Concept childType))),  
                            IKeyed(LanguageEntity(Classifier(Concept parentType)))) {
        if (childType == parentType || size(childType.extends) == 0) return childValue;
        println("Wrap inheritance for <childValue> up to the parent type: <parentType>");

        // Construct one layer of extension and wrap again
        // (concept can extend only one another concept)
        IKeyed extendedType = lionspace.lookup(childType.extends[0])[0];
        Symbol cptADT = adt(extendedType.name, []);
        Production prod = langADT[cptADT];
        type[value] cptType = type(cptADT, (cptADT : prod));
        // this make doesn't work: empty keyword parameters are not good?

        println("Preparing for make with: <childType.name> and <[childValue]>");
        value extendedValue = make(cptType, extendedType.name, [childValue]);
        
        return wrapInheritance(extendedValue, extendedType, IKeyed(LanguageEntity(Classifier(parentType))));
    }

    lionweb::converter::lionjson::Node getJsonNode(Id nodeId) {
        lionweb::converter::lionjson::Node result = Node(MetaPointer(), id = "json node not found");
        for (n <- json.nodes) {
            if (n.id == nodeId) {
                result = n;
                break;
            }
        }
        // if ([L*, n:Node(_, id = nodeId)] := json.nodes) result = n;
        return result;
    }

    // Actual body of the transformation:
    // mixture of recursion (depth-first) and traversing the list of nodes => we store the visited nodes in the list
    for(Node jsonnode <- json.nodes) {
        if (!(jsonnode.id in builtNodes)) {
            tuple[IKeyed ikeyed, Language lang] nodeType = lionspace.findType(jsonnode.classifier.language, jsonnode.classifier.key);
            // check what we get here?
            println(nodeType.ikeyed);
            value nodeValue = lion2value(nodeType.ikeyed, nodeType.lang, jsonnode);
            println(nodeValue);
            builtNodes[jsonnode.id] = nodeValue;
        };
    };

    return builtNodes;
}

/*
value lion22value(IKeyed(LanguageEntity(Classifier(Concept cpt, abstract = false, name="Literal"))), 
                    Language lang, LionSpace lionspace, map[Symbol, Production] langADT, 
                    lionweb::converter::lionjson::Node modelNode) {
    Symbol cptADT = adt(cpt.name, []);
    // type[&T<:node] cptType = type(cptADT, (cptADT : entity2production(LanguageEntity(Classifier(cpt)), lang, lionspace)));
    // Production prod = entity2production(LanguageEntity(Classifier(cpt)), lang); //, lionspace);
    // Production prod = choice(adt("Literal",[]),{cons(label("Literal",adt("Literal",[])),[], [label("\\value",int())], {})});
    Production prod = langADT[cptADT];
    println("production: <prod>");
    type[value] cptType = type(cptADT, (cptADT : prod));
    println("type: <cptType>");
    paramValues = [];
    keywordParamValues = ( "<f.name>": 0 | f <- cpt.features);
    // Below we might need an actual list of definitions for this symbol (its productions), 
    // we get them using functions from lioncore2ADT
    // Or: the question is will #(plain_name) work? how will it find the concrete Expression type?
    return make(cptType, cpt.name, paramValues, keywordParamValues);
}


default value lion2value(IKeyed _, Language lang, LionSpace lionspace, map[Symbol, Production] langADT, lionweb::converter::lionjson::Node modelNode) {
    return "not supported yet";
}*/

// &T<:node lion2value(type[&T<:node] langType, str constructorName, 
//                     list[value] paramValues, map[str, value] keywordParamValues) {
//     return make(langType, constructorName, paramValues, keywordParamValues);
// }