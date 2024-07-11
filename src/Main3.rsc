module Main3

import IO;
import vis::Text;
import ParseTree;
import Type;

import Pipeline;

import lionweb::m3::lioncore;
import lionweb::m3::lionspace;
import lionweb::converter::lionjson;
import lionweb::converter::json2model;
// import lionweb::converter::json2modelGen;
// import lionweb::converter::lioncore2ADT;

import f1re::lionweb::examples::expression::lang;
import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::translators;

int main3(int testArgument=0) {
    // Try out dynamic instantiation with make
    f1re::lionweb::examples::expression::lang::Literal lit1 = 
            make(#f1re::lionweb::examples::expression::lang::Literal, "Literal", [], ("value": 30));

    f1re::lionweb::examples::expression::lang::Literal lit2 = 
            make(#f1re::lionweb::examples::expression::lang::Literal, "Literal", [], ("value": 20));

    f1re::lionweb::examples::expression::lang::BinaryExpression expr1 =
            make(#f1re::lionweb::examples::expression::lang::BinaryExpression, "BinaryExpression", 
                    [plus(), Expression(lit1), Expression(lit2)]);

    println(prettyNode(expr1));
    // f1re::lionweb::examples::expression::\syntax::Expr expr2 = adt2expr(Expression(expr1));
    // println(prettyTree(expr2));
    // println(expr2);

    // Now instantiate a model from the json file
    // TODO: move all language construction into a separate file and function that takes it
    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExprLanguageLW_2.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    
    // // import an m1-model using the constructed language
    SerializationChunk instanceChunk = loadLionJSON(|project://lionweb-rascal/input/ExprInstanceLW_2.json|);
    map[str, value] model = jsonlang2model(instanceChunk, lionspace, #ExpressionsFile.definitions);
    println(prettyNode(model["1109945625693563396"]));

    // variable definition node
    f1re::lionweb::examples::expression::\syntax::Stmnt expr3 = adt2statement(model["8320936306973980740"], model["1109945625693563396"]);
    println(prettyTree(expr3));
    println(expr3);

    // binary expression node
    f1re::lionweb::examples::expression::\syntax::Expr expr4 = adt2expr(model["1109945625693563562"], model["1109945625693563396"]);
    println(prettyTree(expr4));
    println(expr4);

    // Try out implode --> doesn't work and shall not
    // str demoExprs = "10 + 20";

    // f1re::lionweb::examples::expression::\syntax::BinaryExpression exprTree = 
    //         parse(#f1re::lionweb::examples::expression::\syntax::BinaryExpression, demoExprs);
    // println(exprTree);

    // f1re::lionweb::examples::expression::lang::BinaryExpression exprAST = 
    //         implode(#f1re::lionweb::examples::expression::lang::BinaryExpression, exprTree);
    // println(prettyNode(exprAST));

//     f1re::lionweb::examples::expression::\syntax::Literal exprTree = 
//             parse(#f1re::lionweb::examples::expression::\syntax::Literal, "100");
//     println(prettyNode(exprTree));

//     f1re::lionweb::examples::expression::lang::Literal exprAST = 
//             implode(#f1re::lionweb::examples::expression::lang::Literal, exprTree);
//     println(prettyNode(exprAST));

    // Try out unparse
//     f1re::lionweb::examples::expression::lang::Literal demoAST = 
//                     f1re::lionweb::examples::expression::lang::Literal(\value = 10);

    // Question: this function is defined in the clair package, is it generic or C-specific?
    // str serializedAST = treesToPrettyPrinter({demoAST}, #f1re::lionweb::examples::expression::\syntax::Literal);
    // println(serializedAST);

    return testArgument;
}