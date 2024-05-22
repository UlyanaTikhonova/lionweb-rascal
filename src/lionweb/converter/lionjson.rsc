module lionweb::converter::lionjson

data SerializationChunk
    = SerializationChunk(str serializationFormatVersion = "", 
            list[UsedLanguage] languages = [], list[Node] nodes = []);

data UsedLanguage
    = UsedLanguage(str key = "", str version = "");

data Node
    = Node(MetaPointer classifier, str id = "", str parent = "", list[str] annotations = [], 
        list[Containment] containments = [], list[Property] properties = [], 
        list[Reference] references = []);

data Containment
    = Containment(MetaPointer containment, list[str] children = []);

data Property
    = Property(MetaPointer property, str \value = "");

data Reference
    = Reference(MetaPointer reference, list[ReferenceTarget] targets = []);

data MetaPointer
    = MetaPointer(str language = "", str version = "", str key = "");

data ReferenceTarget
    = ReferenceTarget(str reference, str resolveInfo);

// data Id
//     = ref(str id = "") | "";