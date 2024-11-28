module f1re::lionweb::examples::expression::lang

// Code generated from lionweb language.
// Date: $2024-11-27T13:48:27.564+00:00$

import DateTime;
import lionweb::pointer;
import lang::json::ast::JSON;

data Computation
  = Computation(Expression \expr
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data BinaryExpression
  = BinaryExpression(BinaryOperation \operation
      , Expression \leftOperand
      , Expression \rightOperand
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data Literal
  = Literal(int \value = 0
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data ExpressionsFile
  = ExpressionsFile(list[Statement] \body = []
      , str \name = ""
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data BinaryOperation
  = plus()
  | mult()
  | minus()
  ;

data VariableDefinition
  = VariableDefinition(str \varName = ""
      , list[Expression] \varValue = []
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data VarReference
  = VarReference(lionweb::pointer::Pointer[VariableDefinition] \ref = null()
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data Documentation
  = Documentation(list[str] \body = []
      , lionweb::pointer::Id \uid = ""
      , list[node] \lionwebAnnotations = [])
  ;

data Statement
  = Statement(Computation \computation
      , Expression \expr = computation.\expr
      , lionweb::pointer::Id \uid = computation.\uid
      , list[node] \lionwebAnnotations = computation.\lionwebAnnotations)
  | Statement(VariableDefinition \variableDefinition
      , str \varName = variableDefinition.\varName
      , list[Expression] \varValue = variableDefinition.\varValue
      , lionweb::pointer::Id \uid = variableDefinition.\uid
      , list[node] \lionwebAnnotations = variableDefinition.\lionwebAnnotations)
  ;

data Expression
  = Expression(Literal \literal
      , int \value = literal.\value
      , lionweb::pointer::Id \uid = literal.\uid
      , list[node] \lionwebAnnotations = literal.\lionwebAnnotations)
  | Expression(VarReference \varReference
      , lionweb::pointer::Pointer[VariableDefinition] \ref = varReference.\ref
      , lionweb::pointer::Id \uid = varReference.\uid
      , list[node] \lionwebAnnotations = varReference.\lionwebAnnotations)
  | Expression(BinaryExpression \binaryExpression
      , BinaryOperation \operation = binaryExpression.\operation
      , Expression \leftOperand = binaryExpression.\leftOperand
      , Expression \rightOperand = binaryExpression.\rightOperand
      , lionweb::pointer::Id \uid = binaryExpression.\uid
      , list[node] \lionwebAnnotations = binaryExpression.\lionwebAnnotations)
  ;