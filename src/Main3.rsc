module Main3

import IO;
import vis::Text;
import ParseTree;

// import analysis::m3::LearnPrettyPrinter;

import f1re::lionweb::examples::expression::lang;
import f1re::lionweb::examples::expression::\syntax;

int main3(int testArgument=0) {
    // Try out dynamic instantiation with make
    f1re::lionweb::examples::expression::lang::Literal lit = 
            make(#f1re::lionweb::examples::expression::lang::Literal, "lit", [], ("value": 30));
    println(prettyNode(lit));

    // Try out implode
    // str demoExprs = "10 + 20";

    // f1re::lionweb::examples::expression::\syntax::BinaryExpression exprTree = 
    //         parse(#f1re::lionweb::examples::expression::\syntax::BinaryExpression, demoExprs);
    // println(exprTree);

    // f1re::lionweb::examples::expression::lang::BinaryExpression exprAST = 
    //         implode(#f1re::lionweb::examples::expression::lang::BinaryExpression, exprTree);
    // println(prettyNode(exprAST));

    f1re::lionweb::examples::expression::\syntax::Literal exprTree = 
            parse(#f1re::lionweb::examples::expression::\syntax::Literal, "100");
    println(prettyNode(exprTree));

    f1re::lionweb::examples::expression::lang::Literal exprAST = 
            implode(#f1re::lionweb::examples::expression::lang::Literal, exprTree);
    println(prettyNode(exprAST));

    f1re::lionweb::examples::expression::lang::Literal demoAST = 
                    f1re::lionweb::examples::expression::lang::Literal(\value = 10);

    // Question: this function is defined in the clair package, is it generic or C-specific?
    // str serializedAST = treesToPrettyPrinter({demoAST}, #f1re::lionweb::examples::expression::\syntax::Literal);
    // println(serializedAST);

    return testArgument;
}
