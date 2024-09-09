module Main4

import IO;
import vis::Text;
import ParseTree;
import Type;

import Pipeline;

import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

// This example uses already imported LionWeb language to import a Rascal AST into LionWen M1 model
import f1re::lionweb::examples::expression::lang;
import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::translators;

int main4(int testArgument=0) {
    str text = "x = 5;
               '(10 + x)";

    f1re::lionweb::examples::expression::\syntax::File parseTree = parse(#File, text);
    println(prettyTree(parseTree));
    f1re::lionweb::examples::expression::lang::ExpressionsFile abstractTree = file2lion(parseTree);
    println(prettyNode(abstractTree));

    return testArgument;
}