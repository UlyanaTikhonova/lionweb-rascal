module f1re::lionweb::examples::expression::translators

import String;

import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::\lang;

// Translate concrete syntax to ADT
ExpressionsFile file2lion((File)`<{Stmnt ";"}* statememnts>`)
  = ExpressionsFile(expressions = [expr2adt(e) | (Stmnt)`<Expr e>` <- statememnts], 
                    definitions = [expr2adt(d) | (Stmnt)`<Def d>` <- statememnts]);

VariableDefinition expr2adt((Def)`<Id name> = <Expr val>`)
  = VariableDefinition(varName = "<name>", varValue = [expr2adt(val)]);

Expression expr2adt((Expr)`<Literal l>`)
  = Expression(f1re::lionweb::examples::expression::\lang::Literal(\value=toInt("<l>")));

// TODO: here we should do an actual resolving and use the generated uid of the nodes
Expression expr2adt((Expr)`<Id varName>`)
  = Expression(VarReference(ref=lionweb::pointer::Pointer("<name>")));    // here we should be using loockup in the tree and uid of the found node!

Expression expr2adt((Expr)`(<Expr e>)`)
  = expr2adt(e);

Expression expr2adt((Expr)`<Expr lhs> * <Expr rhs>`)
  = Expression(BinaryExpression(mult(), expr2adt(lhs), expr2adt(rhs)));

Expression expr2adt((Expr)`<Expr lhs> + <Expr rhs>`)
  = Expression(BinaryExpression(plus(), expr2adt(lhs), expr2adt(rhs)));

Expression expr2adt((Expr)`<Expr lhs> - <Expr rhs>`)
  = Expression(BinaryExpression(minus(), expr2adt(lhs), expr2adt(rhs)));


// Translate ADT to concrete syntax

File adt2text(ExpressionsFile exprFile)
  = contents([adt2statement(d) | d <- exprFile.\definitions] + 
              [adt2statement(e) | e <- exprFile.\expressions]);

Stmnt adt2statement(VariableDefinition def)
  = varDefinition(definition(def.varName, adt2expr(def.varValue[0])));

Stmnt adt2statement(Expression abstractExpr)
  = expression(adt2expr(abstractExpr));

Expr adt2expr(Expression(Literal l))
  = literal(l.\value);

// Expr adt2expr(Expression(VarReference vr))
//   = varRef(resolve(vr.ref).varName);  //TODO: resolve for the pointer return what it points at

Expr adt2expr(Expression(BinaryExpression(plus(), Expression leftOp, Expression rightOp)))
  = add(adt2expr(leftOp), adt2expr(rightOp));

Expr adt2expr(Expression(BinaryExpression(minus(), Expression leftOp, Expression rightOp)))
  = sub(adt2expr(leftOp), adt2expr(rightOp));

Expr adt2expr(Expression(BinaryExpression(mult(), Expression leftOp, Expression rightOp)))
  = mult(adt2expr(leftOp), adt2expr(rightOp));  