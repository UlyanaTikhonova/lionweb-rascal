module lionweb::m3::lioncore

import lionweb::pointer;

data INamed
    = INamed(IKeyed ikeyed,
             str name = ikeyed.name);

data IKeyed
    = IKeyed(Language language,
            str name = language.name,
            Id key = language.key,
            str version = language.version, 
            list[LanguageEntity] entities = language.entities,
            list[Pointer[Language]] dependsOn = language.dependsOn)
    | IKeyed(LanguageEntity languageentity,
            str name = languageentity.name,
            Id key = languageentity.key)
    | IKeyed(Feature feature,
            str name = feature.name,
            Id key = feature.key,
            bool optional = feature.optional)
    | IKeyed(EnumerationLiteral enumerationliteral,
            str name = enumerationliteral.name,
            Id key = enumerationliteral.key);

data Language 
    = Language( str name = "",
                Id key = "",
                str version = "", 
                list[LanguageEntity] entities = [],
                list[Pointer[Language]] dependsOn = []);

data LanguageEntity
    = LanguageEntity(Classifier classifier,
                     str name = classifier.name,
                     Id key = classifier.key,
                     list[Feature] features = classifier.features)
    | LanguageEntity(DataType datatype,
                    str name = datatype.name,
                    Id key = datatype.key);

data Classifier
    = Classifier(Concept concept,
                str name = concept.name,
                Id key = concept.key,
                list[Feature] features = concept.features,
                bool abstract = concept.abstract, 
                bool partition = concept.partition, 
                list[Pointer[Concept]] extends = concept.extends,
                list[Pointer[Interface]] implements = concept.implements)
    | Classifier(Interface interface,
                str name = interface.name,
                Id key = interface.key,
                list[Feature] features = interface.features,
                list[Pointer[Interface]] extends = interface.extends)
    | Classifier(Annotation annotation,
                str name = annotation.name,
                Id key = annotation.key,
                list[Feature] features = annotation.features,
                list[Pointer[Classifier]] annotates = annotation.annotates,
                list[Pointer[Annotation]] extends = annotation.extends, 
                list[Pointer[Interface]] implements = annotation.implements);

data Concept
    = Concept( str name = "",
               Id key = "",
               list[Feature] features = [],
               bool abstract = false, 
               bool partition = false, 
               list[Pointer[Concept]] extends = [],
               list[Pointer[Interface]] implements = []);

data Interface
    = Interface(str name = "",
               Id key = "",
               list[Feature] features = [],
               list[Pointer[Interface]] extends = []);

data Annotation
    = Annotation(str name = "",
                 Id key = "",
                 list[Feature] features = [],
                 list[Pointer[Classifier]] annotates = [],
                 list[Pointer[Annotation]] extends = [],
                 list[Pointer[Interface]] implements = []);

data DataType
    = DataType(PrimitiveType primitivetype,
                str name = primitivetype.name,
                Id key = primitivetype.key) 
    | DataType(Enumeration enumeration,
                str name = enumeration.name,
                Id key = enumeration.key,
                list[EnumerationLiteral] literals = enumeration.literals);

data PrimitiveType 
    = PrimitiveType(str name = "",
                    Id key = "");

data Enumeration
    = Enumeration(str name = "",
                  Id key = "",
                  list[EnumerationLiteral] literals = []);

data EnumerationLiteral
    = EnumerationLiteral(str name = "",
                         Id key = "");

data Feature
    = Feature(Property property,
              str name = property.name,
              Id key = property.key,
              bool optional = property.optional,
              Pointer[DataType] \type = property.\type)
    | Feature(Link link,
              str name = link.name,
              Id key = link.key,
              bool optional = link.optional,
              bool multiple = link.multiple,
              Pointer[Classifier] \type = link.\type);

data Property
    = Property(str name = "",
               Id key = "",
               bool optional = true,
               Pointer[DataType] \type = null());

data Link 
    = Link(Reference reference,
            str name = reference.name,
            Id key = reference.key,
            bool optional = reference.optional,
            bool multiple = reference.multiple,
            Pointer[Classifier] \type = reference.\type)
    | Link(Containment containment,
            str name = containment.name,
            Id key = containment.key,
            bool optional = containment.optional,
            bool multiple = containment.multiple,
            Pointer[Classifier] \type = containment.\type);

data Reference
    = Reference(str name = "",
                Id key = "",
                bool optional = true,
                bool multiple = false,
                Pointer[Classifier] \type = null());

data Containment
    = Containment(str name = "",
                  Id key = "",
                  bool optional = true,
                  bool multiple = false,
                  Pointer[Classifier] \type = null());    