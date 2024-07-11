module f1re::lionweb::examples::expression::\syntax

extend lang::std::Layout;

lexical IntegerLiteral = [0-9]+;
lexical Identifier = [a-z][a-z0-9]* !>> [a-z0-9];

// start syntax ExpressionsFile
//     = {Expression ";"}* expressions;

// syntax Expression
//     = Expression: Literal literal
//     | Expression: BinaryExpression binaryExpression;
//     //| "(" Expression ")"

// syntax Literal
//     = Literal: IntegerLiteral value;

// syntax BinaryExpression
//     = left BinaryExpression: Expression leftOperand BinaryOperation operation Expression rightOperand;

// syntax BinaryOperation
//     = plus: "+"
//     | mult: "*"
//     | minus: "-";

/// 

start syntax File = contents: {Stmnt ";"}* statements;

syntax Stmnt
  = expression: Expr 
  | varDefinition: Def;

syntax Def 
  = definition: Identifier name "=" Expr;

syntax Expr
  = literal: Literal
  | varRef: Identifier varName
  | left mult: Expr lhs "*" Expr rhs
  > left 
  ( add: Expr lhs "+" Expr rhs
  | sub: Expr lhs "-" Expr rhs)
  | bracket "(" Expr ")"
  ;

syntax Literal
  = IntegerLiteral;