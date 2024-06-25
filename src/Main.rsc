module Main

import IO;
import Type;
import Map;
import lang::json::IO;
import vis::Text;

import lionweb::converter::lionjson;
import lionweb::converter::json2lioncore;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;
import lionweb::converter::lioncore2ADT;
import lionweb::converter::lionADT2rsc;
import lionweb::converter::json2model;

import Pipeline;

int main(int testArgument=0) {
    // Deserialize json files into lionjson AST:
    // SerializationChunk langChunk = loadLionJSON(|project://lionweb-rascal/input/ExprLanguageLW.json|);
    //readJSON(#SerializationChunk, |project://lionweb-rascal/input/ExprLanguageLW.json|);
    // println(prettyNode(langChunk));
    // SerializationChunk instanceChunk = readJSON(#SerializationChunk, |project://lionweb-rascal/input/ExprInstanceLW.json|);
    // println(prettyNode(instanceChunk));

    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExprLanguageLW.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    
    // Convert lionjson AST into lioncore AST 
    println(prettyNode(lionlangs[0]));
    // Generate Rascal ADT for the imported lioncore language
    map[Symbol, Production] langADT = language2adt(lionlangs[0]);
    print("Language ADT is: ");
    println(domain(langADT));
    writeLionADTModule(lionlangs[0], langADT);

    // Dynamically instantiate model from the lionjson using newly generated ADT
    SerializationChunk instanceChunk = loadLionJSON(|project://lionweb-rascal/input/ExprInstanceLW.json|);
    list[value] model = jsonlang2model(instanceChunk, lionspace, langADT);

    // back-up
    // start[JSONText] jsonTree = parse(#start[JSONText], |project://lionweb-rascal/input/ExprLanguageLW.json|);
    // iprintln(buildAST(jsonTree));

    return testArgument;
}

