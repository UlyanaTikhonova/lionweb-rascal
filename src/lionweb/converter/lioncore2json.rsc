module lionweb::converter::lioncore2json

import lionweb::converter::lionjson;
import lionweb::m3::lioncore;

UsedLanguage lang2json(Language lang)
    = UsedLanguage(key = lang.key, version = lang.version);

MetaPointer langEntity2metapointer(LanguageEntity entity, Language lang)
    = MetaPointer(language = lang.key, version = lang.version, key = entity.key);

MetaPointer feature2metapointer(Feature feature, Language lang)
    = MetaPointer(language = lang.key, version = lang.version, key = feature.key);