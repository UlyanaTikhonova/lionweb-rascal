module demoM1FromRascal

import IO;
import vis::Text;
import ParseTree;

import Pipeline;

import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

// This example uses already imported LionWeb language to export a Rascal AST into LionWen M1 model (json)
import f1re::lionweb::examples::expression::lang;
import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::translators;

int mainM1FromRascal(int testArgument=0) {

    f1re::lionweb::examples::expression::\syntax::File parseTree = parse(#File, |project://lionweb-rascal/input/ExampleExpressionsFile.model|);
    println(prettyTree(parseTree));
    f1re::lionweb::examples::expression::lang::ExpressionsFile abstractTree = file2lion(parseTree, filename = "ExampleExpressionsFile");
    println(prettyNode(abstractTree));

    // To instantiate a model from the json file, we need to have its language in the context (aka lionspace)
    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExpressionsLanguageLW.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    
    // println("Type of the AST: <#f1re::lionweb::examples::expression::lang::ExpressionsFile>");

    // Export an m1-model using the imported language and the previously generated Rascal ADT of this language 
    loc jsonfile = |project://lionweb-rascal/output/ExampleExpressionsFile.json|;
    exportM1Model(abstractTree, lionspace, lionlangs[0].key, jsonfile);


    return testArgument;
}