module Main

import IO;
import Type;
import Map;
import vis::Text;

import lionweb::converter::lionjson;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

import Pipeline;

// This example imports a LionWeb language and instantiates its M1 model into a Rascal AST
int main(int testArgument=0) {    
    // Import LionWeb language from json
    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExprLanguageLW_2.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    println(prettyNode(lionlangs[0]));
    
    // Generate Rascal ADT for the imported lioncore language
    map[Symbol, Production] langADT = generateRascalADTFile(lionlangs[0], lionspace);

    // Dynamically instantiate model from the lionjson using newly generated ADT 
    map[str, value] model = instantiateM1Model(|project://lionweb-rascal/input/ExprInstanceLW_2.json|, lionspace, langADT);
    for(value val <- [v | <_, v> <- toList(model)])
        println(prettyNode(val));

    return testArgument;
}

