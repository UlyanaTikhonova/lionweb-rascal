module lionweb::converter::json2model

import Type;
import IO;

import lionweb::pointer;
import lionweb::converter::lionjson;
import lionweb::converter::lioncore2ADT;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

// Where to store langADT? Should it be in the lionspace too?
list[value] jsonlang2model(SerializationChunk json, LionSpace lionspace,  map[Symbol, Production] langADT) {
    list[value] models = [];
    map[Id, value] builtNodes = ();

    // mixture of recursion (depth-first) and traversing the list of nodes => we store the visited nodes in the list
    for(Node jsonnode <- [n | Node n <- json.nodes]) {
        if (!(jsonnode.id in builtNodes)) {
            tuple[IKeyed ikeyed, Language lang] nodeType = lionspace.findType(jsonnode.classifier.language, jsonnode.classifier.key);
            // TODO: check what we get here?
            println(nodeType.ikeyed);
            value nodeValue = lion2value(nodeType.ikeyed, nodeType.lang, lionspace, langADT, jsonnode);
            println(nodeValue);
            builtNodes[jsonnode.id] = nodeValue;
        };
    };

    return models;
}

value lion2value(IKeyed(LanguageEntity(Classifier(Concept cpt, abstract = false, name="Literal"))), 
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
}

// &T<:node lion2value(type[&T<:node] langType, str constructorName, 
//                     list[value] paramValues, map[str, value] keywordParamValues) {
//     return make(langType, constructorName, paramValues, keywordParamValues);
// }