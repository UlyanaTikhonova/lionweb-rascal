module f1re::lionweb::examples::expression::\syntax

layout Whitespace = [\t-\n\r\ ]*;

lexical IntegerLiteral = [0-9]+;

start syntax ExpressionsFile
    = {Expression ";"}* expressions;

syntax Expression
    = Expression: Literal literal
    | Expression: BinaryExpression binaryExpression;
    //| "(" Expression ")"

syntax Literal
    = Literal: IntegerLiteral value;

syntax BinaryExpression
    = left BinaryExpression: Expression leftOperand BinaryOperation operation Expression rightOperand;

syntax BinaryOperation
    = plus: "+"
    | mult: "*"
    | minus: "-";