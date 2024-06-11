module f1re::lionweb::examples::expression::\syntax

extend lang::std::Whitespace;

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

/// 

syntax File = {Expr ";"}*;

syntax Expr
  = Literal
  | left Expr "*" Expr
  > left 
  (Expr "+" Expr 
   Expr "-" Expr)
  ;


ExpressionsFile file2lion((File)`<{Expr ";"}* es>`)
  = ExpressionsFile([ expr2lion(e) | Expr e <- es ]);

Expression expr2lion((Expr)`<Literal l>`)
  = Expression(Literal(\value=toInt("<l>")));

Expression expr2lion((Expr)`<Expr lhs> * <Expr rhs>`)
  = Expression(BinaryExpression(mult(), expr2lion(lhs), expr2lion(rhs)));

Expression expr2lion((Expr)`<Expr lhs> + <Expr rhs>`)
  = Expression(BinaryExpression(plus(), expr2lion(lhs), expr2lion(rhs)));

Expression expr2lion((Expr)`<Expr lhs> - <Expr rhs>`)
  = Expression(BinaryExpression(minus(), expr2lion(lhs), expr2lion(rhs)));
