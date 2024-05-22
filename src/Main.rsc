module Main

import IO;
import lang::json::ast::JSON;
import lang::json::ast::Implode;
import lang::json::IO;
import ParseTree;
import lang::json::\syntax::JSON;
import lionweb::converter::lionjson;


// SerializationChunk json2lion(JSON json)
//   = SerializationChunk(json["serializationFormatVersion"],
//         [ json2lion(l) | list[JSON] objs := json["languages"], JSON l <- objs ],
//         [ json2lion(n) | list[JSON] objs := json["nodes"], JSON n <- nodes]);


int main(int testArgument=0) {

    // println(readFile(|project://input/ExprLanguageLW.json|));
    //SerializationChunk json = readJSON(#SerializationChunk, |project://lionweb-rascal-0.1/input/ExprLanguageLW.json|);
    start[JSONText] jsonTree = parse(#start[JSONText], |project://lionweb-rascal-0.1/input/ExprLanguageLW.json|);
    iprintln(buildAST(jsonTree));

    println("argument: <testArgument>");
    return testArgument;
}
