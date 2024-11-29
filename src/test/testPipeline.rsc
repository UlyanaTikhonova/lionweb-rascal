module \test::testPipeline

import IO;
import Type;
import Map;
import vis::Text;

import lionweb::converter::lionjson;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;
import lionweb::converter::lionADT2rsc;

import Pipeline;

// Test with the resources from lionweb-mps:
// lionweb-mps\solutions\io.lionweb.mps.json.test\resources
// Check manually that the resulting language structures correspond to our expectations

test bool testLangJson2LionCore() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestLang-metamodel.json|;

    // Import LionWeb language from json
    list[lionweb::m3::lioncore::Language] langs = importLionLanguages(jsonfile);
    println(prettyNode(langs[0]));
    println([e.name | e <- langs[0].entities]);

    LionSpace lionspace = addLangsToLionspace(langs);

    // Generate Rascal ADT for the imported lioncore language
    map[Symbol, Production] langADT = generateRascalADTFile(langs[0].key, lionspace);    
    
    return exists(moduleLocation(langs[0].name));
}

test bool testLangAnnotations() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestAnnotation-metamodel.json|;

    // Import LionWeb language from json
    list[lionweb::m3::lioncore::Language] langs = importLionLanguages(jsonfile);
    println(prettyNode(langs[0]));
    println([e.name | e <- langs[0].entities]);

    LionSpace lionspace = addLangsToLionspace(langs);

    // Generate Rascal ADT for the imported lioncore language
    map[Symbol, Production] langADT = generateRascalADTFile(langs[0].key, lionspace);

    return exists(moduleLocation(langs[0].name));
}

test bool testLangAbstractDependsOn() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestAbstract-metamodel-annotated.json|;

    // Create the language that this one depends on
    Language lionLang = Language(
            name = "io.lionweb.mps.specific", 
            key = "io-lionweb-mps-specific", 
            version = "0");
    LionSpace lionspace = defaultSpace(lionLang);

    // Import LionWeb language from json
    list[lionweb::m3::lioncore::Language] langs = importLionLanguages(jsonfile);
    println(prettyNode(langs[0]));
    println([e.name | e <- langs[0].entities]);

    lionspace = addLangsToLionspace(langs, lionspace = lionspace);

    // Generate Rascal ADT for the imported lioncore language
    map[Symbol, Production] langADT = generateRascalADTFile(langs[0].key, lionspace);

    return exists(moduleLocation(langs[0].name));
}