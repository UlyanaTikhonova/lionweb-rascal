module demoM1IntoRascal

import IO;
import vis::Text;
import ParseTree;
import Type;
import Map;
import Set;

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

int mainM1IntoRascal(int testArgument=0) {
    // To instantiate a model from the json file, we need to have its language in the context (aka lionspace)
    list[lionweb::m3::lioncore::Language] lionlangs = importLionLanguages(|project://lionweb-rascal/input/ExpressionsLanguageLW.json|);
    LionSpace lionspace = addLangsToLionspace(lionlangs);
    
    // Import an m1-model using the imported language and the previously generated Rascal ADT of this language
    map[str, value] model = instantiateM1Model(|project://lionweb-rascal/input/ExampleExpressionsFile.json|, lionspace, #ExpressionsFile.definitions);
    
    // Find the root node
    value root = max(range(model));
    for(value modelNode <- range(model)) {
        if (adt("ExpressionsFile", _) := typeOf(modelNode)) {
            root = modelNode;
            break;
        }
    };
    println(prettyNode(root));

    // Unparse the instantiated model (AST)
    println(adt2text(root));
    writeFile(|project://lionweb-rascal/input/ExampleExpressionsFile.model|, adt2text(root));
    // f1re::lionweb::examples::expression::\syntax::File exprFile = adt2parsetree(root);
    // println(prettyTree(exprFile));
    
    // Check separately: variable definition node
    // f1re::lionweb::examples::expression::\syntax::Stmnt expr3 = adt2statement(model["8320936306973980740"], model["1109945625693563396"]);
    // println(prettyTree(expr3));
    // println(expr3);

    // // Check separately: binary expression node
    // f1re::lionweb::examples::expression::\syntax::Expr expr4 = adt2expr(model["1109945625693563562"], model["1109945625693563396"]);
    // println(prettyTree(expr4));
    // println(expr4);

    return testArgument;
}