module f1re.lionweb.examples.expression.lang

// Code generated from lionweb language.
// Date: $2024-05-29T07:02:03.979+00:00$

import lionweb::pointer;
import DateTime;

data BinaryExpression
  = BinaryExpression(reference to type operation
      , reference to type leftOperand
      , reference to type rightOperand)
  ;

data Expression
  = 
  ;

data ExpressionsFile
  = ExpressionsFile(reference to type expressions)
  ;

data Literal
  = Literal(reference to type value)
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;