module f1re::lionweb::examples::expression::lang

// Code generated from lionweb language.
// Date: $2024-10-08T11:18:02.916+00:00$

import DateTime;
import lionweb::pointer;

data Literal
  = Literal(int \value = 0
      , lionweb::pointer::Id \uid = "")
  ;

data VarReference
  = VarReference(lionweb::pointer::Pointer[VariableDefinition] \ref = null()
      , lionweb::pointer::Id \uid = "")
  ;

data ExpressionsFile
  = ExpressionsFile(list[Expression] \expressions = []
      , list[VariableDefinition] \definitions = []
      , str \name = ""
      , lionweb::pointer::Id \uid = "")
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;

data VariableDefinition
  = VariableDefinition(str \varName = ""
      , list[Expression] \varValue = []
      , lionweb::pointer::Id \uid = "")
  ;

data Expression
  = Expression(Literal \literal
      , int \value = literal.\value
      , lionweb::pointer::Id \uid = literal.\uid)
  | Expression(VarReference \varReference
      , lionweb::pointer::Pointer[VariableDefinition] \ref = varReference.\ref
      , lionweb::pointer::Id \uid = varReference.\uid)
  | Expression(BinaryExpression \binaryExpression
      , BinaryOperation \operation = binaryExpression.\operation
      , Expression \leftOperand = binaryExpression.\leftOperand
      , Expression \rightOperand = binaryExpression.\rightOperand
      , lionweb::pointer::Id \uid = binaryExpression.\uid)
  ;

data BinaryExpression
  = BinaryExpression(BinaryOperation \operation
      , Expression \leftOperand
      , Expression \rightOperand
      , lionweb::pointer::Id \uid = "")
  ;