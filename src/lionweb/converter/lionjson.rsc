module lionweb::converter::lionjson

import lionweb::pointer;

// alias Id = str;

data SerializationChunk
    = SerializationChunk(str serializationFormatVersion = "", 
                         list[UsedLanguage] languages = [], 
                         list[Node] nodes = []);

data UsedLanguage
    = UsedLanguage( Id key = "", 
                    str version = "");

data Node
    = Node( MetaPointer classifier,
            Id id = "",
            Id parent = "", 
            list[Id] annotations = [],             
            list[lionweb::converter::lionjson::Containment] containments = [], 
            list[lionweb::converter::lionjson::Property] properties = [], 
            list[lionweb::converter::lionjson::Reference] references = []);

data Containment
    = Containment(MetaPointer containment, 
                  list[Id] children = "");

data Property
    = Property(MetaPointer property, str \value = "");

data Reference
    = Reference(MetaPointer reference, list[ReferenceTarget] targets = []);

data MetaPointer
    = MetaPointer( Id language = "", 
                    str version = "", 
                    Id key = "");

data ReferenceTarget
    = ReferenceTarget(Id reference = "", str resolveInfo = "");

