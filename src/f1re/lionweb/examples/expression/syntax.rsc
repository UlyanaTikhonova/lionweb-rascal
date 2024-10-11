module f1re::lionweb::examples::expression::\syntax

extend lang::std::Layout;

import List;
import IO;

lexical IntegerLiteral = [0-9]+;
lexical Identifier = [a-z][a-z0-9]* !>> [a-z0-9];
lexical StringLiteral = [a-z0-9]*;

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

start syntax File = {Stmnt ";"}* statements;

syntax Stmnt
  = Comp comp 
  | Def varDefinition;

syntax Def 
  = DocAnno? Identifier name "=" Expr val;

syntax Comp
  = DocAnno? Expr expr;

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

syntax DocAnno
  = "@doc" StringLiteral "\n";  

// The cross-referencing mechanism of this language uses Identifiers:
Def findVarDefinition(File file, Identifier varName) {
  list[Def] defs = [d | (Stmnt)`<Def d>` <- file.statements, varName := d.name];
  if (size(defs) == 0) throw "No definition found for the variable <varName> in the file <file>";
  return defs[0];
}