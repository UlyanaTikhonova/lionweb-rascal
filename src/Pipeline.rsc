module Pipeline

import IO;
import vis::Text;
import List;
import Map;
import Type;

import lionweb::converter::lionjson;
import lionweb::converter::json2lioncore;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;
import lionweb::converter::lioncore2ADT;
import lionweb::converter::lionADT2rsc;
import lionweb::converter::json2model;
import lionweb::converter::model2json;
import lionweb::pointer;
import lang::json::IO;

list[lionweb::m3::lioncore::Language] importLionLanguages(loc jsonfile) {
    println("Serializing lion language(s) from: <jsonfile>");
    SerializationChunk langChunk = loadLionJSON(jsonfile);
    list[lionweb::m3::lioncore::Language] langs = jsonlang2lioncore(langChunk);
    println("Imported <size(langs)> language(s)");
    return langs;
}

lionweb::m3::lionspace::LionSpace addLangsToLionspace(list[lionweb::m3::lioncore::Language] langs,
                                                    lionweb::m3::lionspace::LionSpace lionspace = newLionSpace()) {
    for(lionweb::m3::lioncore::Language lang <- langs) {
        // Prepare language for the transformations: flattern inheritance
        lang = flattenInheritance(lang);
        lionspace.add(lang);
    }
    return lionspace;
}

map[Symbol, Production] generateRascalADTFile(Id langId, 
                                            lionweb::m3::lionspace::LionSpace lionspace) {
    lionweb::m3::lioncore::Language lang = lionspace.lookup(Pointer(langId)).language;                    
    println("Generating Rascal ADT for the LionCore language: <lang.name>");
    map[Symbol, Production] langADT = language2adt(lang, lionspace = lionspace);
    print("Language data set: ");
    println(domain(langADT));
    println("Writing ADT data types to the Rascal file at: <moduleLocation(lang.name)>");
    writeLionADTModule(lang, langADT);
    return langADT;
}

map[str, value] instantiateM1Model(loc jsonfile, 
                                    lionweb::m3::lionspace::LionSpace lionspace, 
                                    map[Symbol, Production] langADT) {
    println("Instantiating an M1 model from: <jsonfile>");
    SerializationChunk instanceChunk = loadLionJSON(jsonfile);
    return jsonlang2model(instanceChunk, lionspace, langADT);
}

void exportM1Model(node astRoot,
                    lionweb::m3::lionspace::LionSpace lionspace, 
                    Id langId, loc jsonfile) {
    lionweb::m3::lioncore::Language lang = lionspace.lookup(Pointer(langId)).language;   
    SerializationChunk modelChunk = ast2jsonmodel(astRoot, lionspace, lang);
    // println(prettyNode(modelChunk));
    writeJSON(jsonfile, modelChunk);
    println("Exported M1 model of the language <lang.name> into the json file: <jsonfile>");
}