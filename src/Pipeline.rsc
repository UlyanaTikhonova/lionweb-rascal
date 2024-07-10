module Pipeline

import IO;
import vis::Text;
import List;

import lionweb::converter::lionjson;
import lionweb::converter::json2lioncore;
// import lionweb::converter::json2model;
import lionweb::m3::lioncore;
import lionweb::m3::lionspace;

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
        lionspace.add(lang);
    }
    return lionspace;
}