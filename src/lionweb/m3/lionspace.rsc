module lionweb::m3::lionspace

import List;
import IO;

import lionweb::m3::lioncore;
import lionweb::pointer;

// Currently lookup searches for pointers in all registered languages (not models, and not scoped langs/models)
alias LionSpace = tuple[void(Language) add, 
                        IKeyed(Pointer[&T]) lookup,
                        IKeyed(Pointer[&T], Language) lookupInScope,
                        IKeyed(Id, Id) findInScope];

LionSpace newLionSpace() {
    // Lioncore M3 language instance
    Language lionMetaLanguage = Language(
            name = "Lionweb Meta-Metamodel", 
            key = "LionCore-M3", 
            version = "2023.1");

    // (Default) language with built-in lionweb data types
    // TODO: generate this definition using M1 json-to-lion transformation
    Language lionBuiltinLanguage = Language(
            name = "Built-in DataTypes", 
            key = "LionCore-builtins", 
            version = "2023.1",
            entities = [LanguageEntity(DataType(PrimitiveType(name = "String", key = "LionCore-builtins-String"))),
                        LanguageEntity(DataType(PrimitiveType(name = "Boolean", key = "LionCore-builtins-Boolean"))),
                        LanguageEntity(DataType(PrimitiveType(name = "Integer", key = "LionCore-builtins-Integer"))),
                        LanguageEntity(Classifier(Concept(name = "Node", key = "LionCore-builtins-Node", abstract = true))),
                        LanguageEntity(Classifier(Interface(name = "INamed", key = "LionCore-builtins-INamed", 
                            features = [Feature(Property(name = "name", key = "LionCore-builtins-INamed-name", optional = false, \type = Pointer("LionCore-builtins-String")))])))]);

    map[Id, Language] lionLanguages = ("LionCore-builtins": lionBuiltinLanguage, 
                                        "LionCore-M3": lionMetaLanguage);                        

    void add_(Language lang) {
        println("Add the language to the lion space: <lang.name>");
        // TODO: check that we are not adding a language that already exists in the space (using its key)
        lionLanguages[lang.key] = lang;
    }

    IKeyed lookup_(Pointer[&T] pointer) {
        list[IKeyed] elements = [];

        if (pointer != null()) {
            Id elemId = pointer.uid;
            for(Language lang <- lionLanguages<1>)
                visit(lang) {
                    // only concrete classes are possible here
                    // Question: is there a smarter way to do this using &T?
                    case e:Concept(key = elemId): elements += [IKeyed(LanguageEntity(Classifier(e)))];
                    case e:Interface(key = elemId): elements +=  [IKeyed(LanguageEntity(Classifier(e)))];
                    case e:Annotation(key = elemId): elements += [IKeyed(LanguageEntity(Classifier(e)))];
                    case e:PrimitiveType(key = elemId):  elements += [IKeyed(LanguageEntity(DataType(e)))];
                    case e:Enumeration(key = elemId): elements +=  [IKeyed(LanguageEntity(DataType(e)))];
                    case e:Language(key = elemId): elements += [IKeyed(e)];
                };
        }
        // TODO: validate that the found element is actually of type &T

        if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
        if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";
        
        return elements[0];
    }

    IKeyed lookupInScope_(Pointer[&T] pointer, Language scope) {
        if (pointer == null) throw "Look up for the null pointer";
        list[IKeyed] elements = [];

        Id elemId = pointer.uid;
        for(Language lang <- [scope] + [lookup_(l).language | l <- scope.dependsOn])
            visit(lang) {
                // only concrete classes are possible here
                // Question: is there a smarter way to do this using &T?
                case e:Concept(key = elemId): elements += [IKeyed(LanguageEntity(Classifier(e)))];
                case e:Interface(key = elemId): elements +=  [IKeyed(LanguageEntity(Classifier(e)))];
                case e:Annotation(key = elemId): elements += [IKeyed(LanguageEntity(Classifier(e)))];
                case e:PrimitiveType(key = elemId):  elements += [IKeyed(LanguageEntity(DataType(e)))];
                case e:Enumeration(key = elemId): elements +=  [IKeyed(LanguageEntity(DataType(e)))];
                case e:Language(key = elemId): elements += [IKeyed(e)];
            };

        // TODO: validate that the found element is actually of type &T

        if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
        if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";
        
        return elements[0];
    }

    IKeyed findInScope_(Id scopeKey, Id elementKey) {
        if (!(scopeKey in lionLanguages)) throw "This scope is not in the lionspace: <scopeKey>";
        list[IKeyed] elements = [];
        Language rootLang = lionLanguages[scopeKey];
        list[Language] scope = [rootLang] + [lookup_(l).language | l <- rootLang.dependsOn];
        
        for(Language lang <- scope) {
            visit(lang) {
                case e:LanguageEntity(_, key = elementKey): elements += IKeyed(e);
                case e:Feature(_, key = elementKey): elements += IKeyed(e);
                case e:EnumerationLiteral(key = elementKey): elements += IKeyed(e);
                case e:IKeyed(_, key = elementKey): elements += e;
            };
        }

        if (size(elements) == 0) throw "No element found for the key: <elementKey>";
        if (size(elements) > 1) throw "More than one element found for the key: <elementKey>";

        return elements[0];
    }

    return <add_, lookup_, lookupInScope_, findInScope_>;
}

LionSpace defaultSpace(Language lang) {
    LionSpace space = newLionSpace();
    space.add(lang);
    return space;
}