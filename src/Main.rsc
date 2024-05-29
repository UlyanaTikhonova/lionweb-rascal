module Main

import IO;
import lang::json::IO;
import vis::Text;

import lionweb::converter::lionjson;
import lionweb::converter::json2lioncore;
// import lionweb::m3::lioncore;
import lionweb::converter::lioncore2ADT;

test bool inOutTest(SerializationChunk x)
  = parseJSON(#SerializationChunk, asJSON(x)) == x
  when bprintln(x);

int main(int testArgument=0) {
  
    SerializationChunk langChunk = readJSON(#SerializationChunk, |project://lionweb-rascal/input/ExprLanguageLW.json|);
    // println(prettyNode(langChunk));
    // SerializationChunk instanceChunk = readJSON(#SerializationChunk, |project://lionweb-rascal/input/ExprInstanceLW.json|);
    // println(prettyNode(instanceChunk));
    
    // println(langChunk);

    println(prettyNode(jsonlang2lioncore(langChunk)[0]));
    writeLionADTModule(jsonlang2lioncore(langChunk)[0]);

    // start[JSONText] jsonTree = parse(#start[JSONText], |project://lionweb-rascal/input/ExprLanguageLW.json|);
    // iprintln(buildAST(jsonTree));

    return testArgument;
}

