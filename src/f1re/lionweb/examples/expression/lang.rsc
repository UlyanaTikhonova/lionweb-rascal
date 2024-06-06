module f1re::lionweb::examples::expression::lang

// Code generated from lionweb language.
// Date: $2024-06-06T09:50:59.361+00:00$

import DateTime;

data BinaryExpression
  = BinaryExpression(BinaryOperation \operation
      , Expression \leftOperand
      , Expression \rightOperand)
  ;

data Expression
  = Expression(BinaryExpression \binaryExpression
      , BinaryOperation \operation = \binaryExpression.\operation
      , Expression \leftOperand = \binaryExpression.\leftOperand
      , Expression \rightOperand = \binaryExpression.\rightOperand)
  | Expression(Literal \literal
      , int \value = \literal.\value)
  ;

data ExpressionsFile
  = ExpressionsFile(list[Expression] \expressions = [])
  ;

data Literal
  = Literal(int \value = 0)
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;