module lionweb::m3::lionspace

import List;
import IO;

import lionweb::m3::lioncore;
import lionweb::pointer;

alias LionSpace = tuple[void(Language) add, list[&T](Pointer[&T]) lookup];

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
                        LanguageEntity(DataType(PrimitiveType(name = "Integer", key = "LionCore-builtins-Integer")))]);

    list[Language] lionLanguages = [lionBuiltinLanguage, lionMetaLanguage];                        

    void add_(Language lang) {
        println("In the add of lion space function");
        // TODO: check that we are not adding a language that already exists in the space (using its key)
        lionLanguages = lionLanguages + [lang];
    }

    // Question: I cannot use generic type &T as a return here: I get CallFailed exception. How to overcome this? With IKeyed?
    list[&T] lookup_(Pointer[&T] pointer) {
        println("In the lookup of lion space function");
        list[&T] elements = [];

        if (pointer != null()) {
            Id elemId = pointer.uid;
            for(Language lang <- lionLanguages)
                visit(lang) {
                    // only concrete classes are possible here
                    // Question: is there a smarter way to do this using &T?
                    case e:Concept(key = elemId): elements = elements + [Classifier(e)];
                    case e:Interface(key = elemId): elements = elements + [Classifier(e)];
                    case e:Annotation(key = elemId): elements = elements + [Classifier(e)];
                    case e:PrimitiveType(key = elemId):  elements = elements + [DataType(e)];
                    case e:Enumeration(key = elemId): elements = elements + [DataType(e)];
                    case e:Language(key = elemId): elements = elements + [e];
                };
        }
        // TODO: validate that the found element is actually of type &T

        if (size(elements) == 0) throw "No element found for the pointer: <pointer>";
        if (size(elements) > 1) throw "More than one element found for the pointer: <pointer>";
        
        println("Found the element <elements[0]> referenced by the pointer <pointer>");
        return elements;
    }

    return <add_, lookup_>;
}

LionSpace defaultSpace(Language lang) {
    LionSpace space = newLionSpace();
    space.add(lang);
    return space;
}