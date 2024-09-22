module lionweb::converter::json2model

import Type;
import IO;
import String;
import List;

import lionweb::pointer;
import lionweb::converter::lionjson;
import lionweb::converter::lioncore2ADT;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

// The language ADT doesn't need to be stored, it can be fetched from the generated type: #ADT.definitions
map[Id, value] jsonlang2model(SerializationChunk json, LionSpace lionspace,  map[Symbol, Production] langADT) {
    map[Id, value] builtNodes = ();
    // list[Language] langs = [lionspace.lookup(Pointer(l.key)).language | l <- json.languages];

    // Only lioncore classifiers are serialized as json nodes
    value classifier2value(lionweb::converter::lionjson::Node modelNode) {
        IKeyed nodeType = lionspace.findInScope(modelNode.classifier.language, modelNode.classifier.key);
        Concept cpt = nodeType.languageentity.classifier.concept;
        if(cpt.abstract) throw "Cannot instantiate abstract concept";

        // Get the rascal (ADT) type of the lion language entity
        Symbol cptADT = adt(cpt.name, []);
        Production prod = langADT[cptADT];
        type[value] cptType = type(cptADT, (cptADT : prod));

        // Construct values of the parameters
        paramValues = [];
        keywordParamValues = ();

        for(Feature feature <- cpt.features) {
            println("Get the value for the feature: <feature.name>");
            value featureValue = getFeatureValue(feature, modelNode);
            println("     the value for the feature is: <featureValue>");
            // determine to which list of parameters this one belongs, by invoking functions from the lion-to-ADT tranformation
            Language lang = lionspace.lookup(Pointer(modelNode.classifier.language)).language; // this is temporally needed
            tuple[Symbol smbl, bool hasDefault] child = feature2parameter(feature, lang, lionspace);
            if (child.hasDefault) {
                keywordParamValues[field(feature.name)] = featureValue;
            } else {
                paramValues += featureValue; // here the order might be wrong!!!
            };
        };
        // Add unique identifier to the build concept, equal to the id of the json node
        keywordParamValues["uid"] = modelNode.id;
        
        println("Constructed parameters: <paramValues>");
        println("Constructed keyword parameters: <keywordParamValues>");
        // Instantiate the type with the values
        value cptValue =  make(cptType, cpt.name, paramValues, keywordParamValues);

        return cptValue;
    };

    // Lioncore properties are serialized as json properties
    value property2value(IKeyed(LanguageEntity(DataType dataType)),
                        lionweb::converter::lionjson::Property jsonProperty) {
        if (dataType.name in lionweb::converter::lioncore2ADT::BUILTIN_TYPES) {
            switch (dataType.name) {
                case "Integer": return toInt(jsonProperty.\value);
                case "String": return jsonProperty.\value;
                case "Boolean": return jsonProperty.\value == "true";
            }
        };

        // If not a built-in type then get the rascal (ADT) type of the lion language entity
        Symbol datatypeADT = adt(dataType.name, []);
        Production prod = langADT[datatypeADT];
        type[value] datatypeType = type(datatypeADT, (datatypeADT : prod));

        // Not this: Find the name of the constructor using the key in the child value
        // But: The json value is the name of the enumeration literal.
        return make(datatypeType, jsonProperty.\value, [], ());
        // IKeyed enumLiteral = lionspace.findInScope(jsonProperty.property.language, jsonProperty.\value);
        // if (IKeyed(EnumerationLiteral el) := enumLiteral) {
        //     return make(datatypeType, el.name, [], ());
        // };
        // return "Error in property2value";
    };

    // For property - also find the proper ADT by its key, and add default conversions for the built-in types
    value getFeatureValue(Feature(Property propertyFeature),
                            lionweb::converter::lionjson::Node parentNode) {
        value childValue;   // In our json of the instance model we miss operation property!!
        
        // search for the corresponding property in the json node
        for(lionweb::converter::lionjson::Property jsonProperty <- parentNode.properties) {
            if(jsonProperty.property.key == propertyFeature.key) {
                println("Search the lion property type: <jsonProperty>");
                IKeyed lionProperty = lionspace.findInScope(jsonProperty.property.language, jsonProperty.property.key);
                if (IKeyed(Feature(Property lp)) := lionProperty) {
                    println("Search the lion type of this property: <lp.\type.uid>");
                    IKeyed childType = lionspace.findInScope(jsonProperty.property.language, lp.\type.uid); // TODO: refactor this!!
                    // this is the key for the not-built-in types
                    println("Invoke property2value for the node: <jsonProperty>");
                    childValue = property2value(childType, jsonProperty);
                    break;
                };                
            };
        };
        if (propertyFeature.optional == true)
            return [childValue];
        return childValue;
    }

    value getFeatureValue(Feature(Link(Containment containmentFeature)),
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
                value childValue = classifier2value(childnode);
                // The original feature type (parameter) might be an inherited type of the declared feature type (argument)
                // then we need to wrap it into the chain of the corresponding constructors.
                println("Wrap inheritance for <childValue>");
                childValue = wrapInheritance(childValue, 
                                            lionspace.findInScope(childnode.classifier.language, childnode.classifier.key), 
                                            lionspace.lookup(containmentFeature.\type));
                // ... store the resulting value in the built nodes
                builtNodes[childId] = childValue;
            };
            childValues += builtNodes[childId];
        }; 

        // if the feature is multiple or optional - return list
        if (containmentFeature.multiple || containmentFeature.optional)
            return childValues;                
        return childValues[0];
    }

    value getFeatureValue(Feature(Link(Reference referenceFeature)),
                            lionweb::converter::lionjson::Node parentNode) {
        list[lionweb::converter::lionjson::ReferenceTarget] jsonChildren = [];
        // search for the corresponding reference in the json node
        for(jsonReference <- parentNode.references) {
            if(jsonReference.reference.key == referenceFeature.key) {
                jsonChildren = jsonReference.targets;
                break;
            };
        };
        // Construct pointers using the ids of the referenced nodes
        list[value] childValues = [];    
        for(lionweb::converter::lionjson::ReferenceTarget refTarget <- jsonChildren) {
            childValues += lionweb::pointer::Pointer(refTarget.reference);
            // resolve info is not used yet
        };

         // if the feature is multiple or optional - return list
        if (referenceFeature.multiple || referenceFeature.optional)
            return childValues;                
        return childValues[0];
    }

    // TODO: generalize the following for interface and annotation
    // TODO: add transformation for built-in concept types (Node and INamed)
    value wrapInheritance(value childValue, 
                            IKeyed(LanguageEntity(Classifier(Concept childType))),  
                            IKeyed(LanguageEntity(Classifier(Concept parentType)))) {
        if (childType == parentType || size(childType.extends) == 0) return childValue;
        println("Wrap inheritance for <childValue> up to the parent type: <parentType>");

        // Construct one layer of extension and wrap again
        // (concept can extend only one another concept)
        IKeyed extendedType = lionspace.lookup(childType.extends[0]);
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
            value nodeValue = classifier2value(jsonnode);
            println("Build the node value: <nodeValue>");
            builtNodes[jsonnode.id] = nodeValue;
        };
    };

    return builtNodes;
}


// &T<:node lion2value(type[&T<:node] langType, str constructorName, 
//                     list[value] paramValues, map[str, value] keywordParamValues) {
//     return make(langType, constructorName, paramValues, keywordParamValues);
// }