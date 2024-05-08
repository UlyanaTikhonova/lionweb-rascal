module LionWeb::M3

data Language 
    = language(str version, list[LanguageEntity] entities);

data LanguageEntity
    = LanguageEntity(Classifier)
    | LanguageEntity(DataType);

data Classifier
    = Classifier(Concept)
    | Classifier(Interface)
    | Classifier(Annotation);

data Concept
    = Concept(bool abstract, bool partition, Concept extends);

data Interface
    = Interface(list[Interface] extends);

data Annotation
    = Annotation(Classifier annotates, Annotation extends, list[Interface] implements);

data DataType
    = DataType(PrimitiveType); // | DataType(Enumeration);