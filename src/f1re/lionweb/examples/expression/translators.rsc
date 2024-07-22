module f1re::lionweb::examples::expression::translators

import IO;
import String;
import List;
import ParseTree;

import lionweb::pointer;

import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::\lang;

// Translate concrete syntax to ADT
ExpressionsFile file2lion((File)`<{Stmnt ";"}* statememnts>`)
  = ExpressionsFile(expressions = [expr2adt(e) | (Stmnt)`<Expr e>` <- statememnts], 
                    definitions = [expr2adt(d) | (Stmnt)`<Def d>` <- statememnts]);

VariableDefinition expr2adt((Def)`<Identifier name> = <Expr val>`)
  = VariableDefinition(varName = "<name>", varValue = [expr2adt(val)]);

Expression expr2adt((Expr)`<Literal l>`)
  = Expression(f1re::lionweb::examples::expression::\lang::Literal(\value=toInt("<l>")));

// TODO: here we should do an actual resolving and use the generated uid of the nodes
Expression expr2adt((Expr)`<Identifier varName>`)
  = Expression(VarReference(lionweb::pointer::Pointer("<varName>")));    // here we should be using loockup in the tree and uid of the found node!

Expression expr2adt((Expr)`(<Expr e>)`)
  = expr2adt(e);

Expression expr2adt((Expr)`<Expr lhs> * <Expr rhs>`)
  = Expression(BinaryExpression(mult(), expr2adt(lhs), expr2adt(rhs)));

Expression expr2adt((Expr)`<Expr lhs> + <Expr rhs>`)
  = Expression(BinaryExpression(plus(), expr2adt(lhs), expr2adt(rhs)));

Expression expr2adt((Expr)`<Expr lhs> - <Expr rhs>`)
  = Expression(BinaryExpression(minus(), expr2adt(lhs), expr2adt(rhs)));


// Translate ADT to concrete syntax

// In Rascal it is hard to generate lists for parse trees, 
// so we print the lists in a string and then parse the result to get a parse tree with the lists
// Question: current parsing doesn't recognize ";" in the end of the file, why?
str adt2text(ExpressionsFile exprFile)
  = "<intercalate("\n", ["<adt2statement(d, exprFile)>;" | d <- exprFile.\definitions])>
    '
    '<intercalate("\n;", ["<adt2statement(e, exprFile)>" | e <- exprFile.\expressions])>";

File adt2parsetree(ExpressionsFile exprFile)
  = parse(#File, adt2text(exprFile));

Stmnt adt2statement(VariableDefinition def, ExpressionsFile exprFile)
  = (Stmnt)`<Identifier varId> = <Expr varVal>`
  when varId := [Identifier]"<def.varName>",
       varVal := adt2expr(def.varValue[0], exprFile);

Stmnt adt2statement(Expression abstractExpr, ExpressionsFile exprFile)
  = (Stmnt)`<Expr e>`
  when e := adt2expr(abstractExpr, exprFile);

Expr adt2expr(Expression(Literal l), ExpressionsFile exprFile)
  = (Expr)`<IntegerLiteral val>` 
  when IntegerLiteral val := [IntegerLiteral]"<l.\value>";

Expr adt2expr(Expression(VarReference vr), ExpressionsFile exprFile)
  = (Expr)`<Identifier vName>`
  when VariableDefinition vd := typeCast(#VariableDefinition, resolve(vr.\ref, exprFile.\definitions)), 
        Identifier vName := [Identifier]"<vd.\varName>";

Expr adt2expr(Expression(BinaryExpression(plus(), Expression leftOp, Expression rightOp)), ExpressionsFile exprFile)
  = (Expr)`(<Expr lhs> + <Expr rhs>)`
  when lhs := adt2expr(leftOp, exprFile),
       rhs := adt2expr(rightOp, exprFile);

Expr adt2expr(Expression(BinaryExpression(minus(), Expression leftOp, Expression rightOp)), ExpressionsFile exprFile)
  = (Expr)`(<Expr lhs> - <Expr rhs>)`
  when lhs := adt2expr(leftOp, exprFile),
       rhs := adt2expr(rightOp, exprFile);

Expr adt2expr(Expression(BinaryExpression(mult(), Expression leftOp, Expression rightOp)), ExpressionsFile exprFile)
  = (Expr)`<Expr lhs> * <Expr rhs>`
  when lhs := adt2expr(leftOp, exprFile),
       rhs := adt2expr(rightOp, exprFile);  