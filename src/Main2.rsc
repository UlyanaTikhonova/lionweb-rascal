module Main2

import IO;
import vis::Text;

import lionweb::m3::lioncore;
import lionweb::converter::lioncore2ADT;

int main2(int testArgument=0) {

    lionweb::m3::lioncore::Language lang = lionweb::m3::lioncore::Language();
    lang.name = "f1re.lionweb.examples.expression.lang";

    lionweb::m3::lioncore::Enumeration enum = lionweb::m3::lioncore::Enumeration();
    enum.name = "BinaryOperation";
    lionweb::m3::lioncore::EnumerationLiteral literal1 = lionweb::m3::lioncore::EnumerationLiteral();
    lionweb::m3::lioncore::EnumerationLiteral literal2 = lionweb::m3::lioncore::EnumerationLiteral();
    literal1.name = "plus";
    literal2.name = "minus";
    enum.literals = [literal1, literal2];

    lionweb::m3::lioncore::Concept concept = lionweb::m3::lioncore::Concept();
    concept.name = "BinaryExpression";
    concept.abstract = false;

    lionweb::m3::lioncore::Property feature1 = lionweb::m3::lioncore::Property();
    feature1.name = "operation";
    lionweb::m3::lioncore::Containment feature2 = lionweb::m3::lioncore::Containment();
    feature2.name = "leftOperand";
    feature2.optional = false;
    lionweb::m3::lioncore::Containment feature3 = lionweb::m3::lioncore::Containment();
    feature3.name = "rightOperand";
    feature3.optional = false;

    concept.features = [Feature(feature1), Feature(Link(feature2)), Feature(Link(feature3))];

    lang.entities = [LanguageEntity(DataType(enum)), LanguageEntity(Classifier(concept))];

    println(prettyNode(lang));
    writeLionADTModule(lang);

    return testArgument;
}

