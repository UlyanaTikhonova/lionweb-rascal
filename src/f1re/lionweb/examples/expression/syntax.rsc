module f1re::lionweb::examples::expression::\syntax

extend lang::std::Layout;

import List;

// layout Whitespace = [\t-\n\r\ ]*;
lexical IntegerLiteral = [0-9]+;
lexical Identifier = [a-z][a-z0-9]* !>> [a-z0-9];
lexical AnnotationString = ![\n]*;

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
  = "@doc " AnnotationString text;  

// The cross-referencing mechanism of this language uses Identifiers:
Def findVarDefinition(File file, Identifier varName) {
  list[Def] defs = [d | (Stmnt)`<Def d>` <- file.statements, varName := d.name];
  if (size(defs) == 0) throw "No definition found for the variable <varName> in the file <file>";
  return defs[0];
}