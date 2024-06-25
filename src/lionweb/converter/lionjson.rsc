module lionweb::converter::lionjson

import IO;
import lang::json::IO;
import lionweb::pointer;

SerializationChunk loadLionJSON(loc jsonfile) = readJSON(#SerializationChunk, jsonfile);

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
            list[Containment] containments = [], 
            list[Property] properties = [], 
            list[Reference] references = []);

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

test bool inOutTest(SerializationChunk x)
  = parseJSON(#SerializationChunk, asJSON(x)) == x
  when bprintln(x);