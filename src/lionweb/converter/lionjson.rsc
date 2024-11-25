module lionweb::converter::lionjson

import IO;
import lang::json::IO;
import lionweb::pointer;

SerializationChunk loadLionJSON(loc jsonfile) = readJSON(#SerializationChunk, jsonfile);

str lionwebVersion = "2023.1";

data SerializationChunk
    = SerializationChunk(str serializationFormatVersion = lionwebVersion, 
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
                  list[Id] children = []);

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


@javaClass{lionweb.IdCodec}
public java str toBase64url(str src, str charset = "UTF-8", bool includePadding = false);
@javaClass{lionweb.IdCodec}
public java str fromBase64url(str src, str charset = "UTF-8");

test bool base64InOutForLoc(loc x)
    = fromBase64url(toBase64url("<x>")) == "<x>"
    when bprintln(x);