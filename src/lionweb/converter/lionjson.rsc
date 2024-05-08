module lionweb::converter::lionjson

data SerializationChunk
    = SerializationChunk(str serializationFormatVersion, list[UsedLanguage] languages, list[Node] nodes);

data UsedLanguage
    = UsedLanguage(Id key, str version);

data Node
    = Node(Id id, Id parent, list[Id] annotations, MetaPointer classifier, list[Containment] containments, list[Property] properties, list[Reference] references);

data Containment
    = Containment(list[Id] children, MetaPointer containment);

data Property
    = Property(str \value, MetaPointer property);

data Reference
    = Reference(MetaPointer reference, list[ReferenceTarget] targets);

data MetaPointer
    = MetaPointer(Id language, str version, Id key);

data ReferenceTarget
    = ReferenceTarget(Id reference, str resolveInfo);

data Id
    = ref(str id) | null();