module \test::testLWm2

import lionweb::converter::lionjson;
import lionweb::m3::lioncore;
import lionweb::converter::json2lioncore;
import lionweb::converter::lioncore2ADT;
import lionweb::converter::lionADT2rsc;

import IO;
import vis::Text;
import List;
import Type;
import Map;
import Set;
import ParseTree;
import lang::rascal::\syntax::Rascal;

test bool testLangJson2LionCore() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestLang-metamodel.json|;
    SerializationChunk langChunk = loadLionJSON(jsonfile);

    list[lionweb::m3::lioncore::Language] langs = jsonlang2lioncore(langChunk);
    lionweb::m3::lioncore::Language lang = langs[0];
    
    str entityName = "TestConceptExtends2";
    bool testResult = (lang.name == "io.lionweb.mps.converter.TestLang") && 
                        (size(lang.entities) == 13) &&
                        (lang.version == "0") &&
                        (size(lang.dependsOn) == 2) &&
                        (size([le | le <- lang.entities, le.name == entityName]) == 1); 
    
    return testResult;
}

test bool testLionCore2Rascal() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestLang-metamodel.json|;
    SerializationChunk langChunk = loadLionJSON(jsonfile);
    list[lionweb::m3::lioncore::Language] langs = jsonlang2lioncore(langChunk);
    lionweb::m3::lioncore::Language lang = langs[0];

    map[Symbol, Production] langADT = language2adt(lang);

    Symbol testConcept1 = adt("TestInterfaceBase", []);
    Production prod1 = langADT[testConcept1];
    Symbol testConcept2 = adt("TestConceptExtends2", []);
    Production prod2 = langADT[testConcept2];

    bool testResult = (size(domain(langADT)) == 13) &&
                        (size(prod1.alternatives) == 3) &&
                        (size(getSingleFrom(prod2.alternatives).kwTypes) == 18);

    return testResult;
}

test bool testLionCoreADT2Rascal() {
    loc jsonfile = |project://lionweb-rascal/src/test/resources/TestLang-metamodel.json|;
    SerializationChunk langChunk = loadLionJSON(jsonfile);
    list[lionweb::m3::lioncore::Language] langs = jsonlang2lioncore(langChunk);
    lionweb::m3::lioncore::Language lang = langs[0];

    map[Symbol, Production] langADT = language2adt(lang);

    writeLionADTModule(lang, langADT);

    bool testResult = (exists(moduleLocation(lang.name))) &&
                      (unparse(parse(#Module, moduleLocation(lang.name))) == readFile(moduleLocation(lang.name)));

    return testResult;
}