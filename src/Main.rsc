module Main

import IO;
import lang::json::ast::JSON;
import lang::json::IO;
// import ParseTree;
// import lang::json::\syntax::JSON;
import lionweb::converter::lionjson;

int main(int testArgument=0) {

    // println(readFile(|project://input/ExprLanguageLW.json|));
    SerializationChunk json = readJSON(#SerializationChunk, |project://lionweb-rascal-0.1/input/ExprLanguageLW.json|);
    // JSONText jsonTree = parse(#JSONText, |home:///Documents/lionweb/ExprLanguageLW.json|);

    println("argument: <testArgument>");
    return testArgument;
}
