module f1re.lionweb.examples.expression.lang

// Code generated from lionweb language.
// Date: $2024-06-05T07:39:42.147+00:00$

import lionweb::pointer;
import DateTime;

data BinaryExpression
  = BinaryExpression(Expression leftOperand
      , Expression rightOperand
      , list[BinaryOperation] operation = [])
  ;

data Expression
  = Expression(Literal \literal
      , list[int] value = \literal.value)
  | Expression(BinaryExpression \binaryExpression
      , list[BinaryOperation] operation = \binaryExpression.operation
      , Expression leftOperand = \binaryExpression.leftOperand
      , Expression rightOperand = \binaryExpression.rightOperand)
  ;

data ExpressionsFile
  = ExpressionsFile(list[Expression] expressions = [])
  ;

data Literal
  = Literal(list[int] value = [])
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;