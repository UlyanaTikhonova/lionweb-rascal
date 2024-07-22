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

// This example uses already imported LionWeb language to instantiate its M1 model into a Rascal AST
// and to unparse it using concrete syntax grammar, manually created for the language in Rascal
import f1re::lionweb::examples::expression::lang;
import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::translators;

int main3(int testArgument=0) {
    // Try out dynamic instantiation with make
    // f1re::lionweb::examples::expression::lang::Literal lit1 = 
    //         make(#f1re::lionweb::examples::expression::lang::Literal, "Literal", [], ("value": 30));

    // f1re::lionweb::examples::expression::lang::Literal lit2 = 
    //         make(#f1re::lionweb::examples::expression::lang::Literal, "Literal", [], ("value": 20));

    // f1re::lionweb::examples::expression::lang::BinaryExpression expr1 =
    //         make(#f1re::lionweb::examples::expression::lang::BinaryExpression, "BinaryExpression", 
    //                 [plus(), Expression(lit1), Expression(lit2)]);

    // println(prettyNode(expr1));
    // f1re::lionweb::examples::expression::\syntax::Expr expr2 = adt2expr(Expression(expr1));
    // println(prettyTree(expr2));
    // println(expr2);

    // To instantiate a model from the json file, we need to have its language in the context (aka lionspace)
    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExprLanguageLW_2.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    
    // Import an m1-model using the imported language and the previously generated Rascal ADT of this language 
    map[str, value] model = instantiateM1Model(|project://lionweb-rascal/input/ExprInstanceLW_2.json|, lionspace, #ExpressionsFile.definitions);
    
    // Id of the root node ExpressionsFile: 1109945625693563396
    println(prettyNode(model["1109945625693563396"]));

    // Unparse the instantiated model (AST)
    println(adt2text(model["1109945625693563396"]));
    f1re::lionweb::examples::expression::\syntax::File exprFile = adt2parsetree(model["1109945625693563396"]);
    println(prettyTree(exprFile));
    
    // Check separately: variable definition node
    f1re::lionweb::examples::expression::\syntax::Stmnt expr3 = adt2statement(model["8320936306973980740"], model["1109945625693563396"]);
    println(prettyTree(expr3));
    println(expr3);

    // Check separately: binary expression node
    f1re::lionweb::examples::expression::\syntax::Expr expr4 = adt2expr(model["1109945625693563562"], model["1109945625693563396"]);
    println(prettyTree(expr4));
    println(expr4);

    return testArgument;
}