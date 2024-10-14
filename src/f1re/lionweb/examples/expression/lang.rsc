module f1re::lionweb::examples::expression::lang

// Code generated from lionweb language.
// Date: $2024-10-14T09:17:15.127+00:00$

import DateTime;
import lionweb::pointer;
import lang::json::ast::JSON;

data Literal
  = Literal(int \value = 0
      , lionweb::pointer::Id \uid = "")
  ;

data Documentation
  = Documentation(list[str] \body = []
      , lionweb::pointer::Id \uid = "")
  ;

data VariableDefinition
  = VariableDefinition(str \varName = ""
      , list[Expression] \varValue = []
      , list[Documentation] \annoDocumentation = []
      , lionweb::pointer::Id \uid = "")
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;

data Statement
  = Statement(Computation \computation
      , Expression \expr = computation.\expr
      , list[Documentation] \annoDocumentation = computation.\annoDocumentation
      , lionweb::pointer::Id \uid = computation.\uid)
  | Statement(VariableDefinition \variableDefinition
      , str \varName = variableDefinition.\varName
      , list[Expression] \varValue = variableDefinition.\varValue
      , list[Documentation] \annoDocumentation = variableDefinition.\annoDocumentation
      , lionweb::pointer::Id \uid = variableDefinition.\uid)
  ;

data Computation
  = Computation(Expression \expr
      , list[Documentation] \annoDocumentation = []
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

data VarReference
  = VarReference(lionweb::pointer::Pointer[VariableDefinition] \ref = null()
      , lionweb::pointer::Id \uid = "")
  ;

data ExpressionsFile
  = ExpressionsFile(list[Statement] \body = []
      , str \name = ""
      , lionweb::pointer::Id \uid = "")
  ;