module f1re::lionweb::examples::expression::translators

import IO;
import String;
import List;
import ParseTree;

import lionweb::pointer;

import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::\lang;

// Translate concrete syntax to ADT
ExpressionsFile file2lion(File file)
  = ExpressionsFile(expressions = [expr2adt(e, file) | (Stmnt)`<Expr e>` <- file.statements], 
                    definitions = [expr2adt(d, file) | (Stmnt)`<Def d>` <- file.statements],
                    name = "",
                    \uid = "<file.src>");

Expression expr2adt((Expr)`(<Expr e>)`, File file)
  = expr2adt(e, file);

VariableDefinition expr2adt(Def definition, File file)
  = VariableDefinition(varName = "<definition.name>", 
                       varValue = [expr2adt(definition.val, file)],
                       \uid = "<definition.src>");

Expression expr2adt((Expr)`<Literal l>`, File file)
  = Expression(f1re::lionweb::examples::expression::\lang::Literal(\value=toInt("<l>"), \uid = "<l.src>"));

Expression expr2adt(expr: (Expr)`<Identifier varName>`, File file)
  = Expression(VarReference(\ref = lionweb::pointer::Pointer("<findVarDefinition(file, varName).src>"),
                            \uid = "<expr.src>"));

Expression expr2adt(expr: (Expr)`<Expr lhs> * <Expr rhs>`, File file)
  = Expression(BinaryExpression(mult(), expr2adt(lhs, file), expr2adt(rhs, file), \uid = "<expr.src>"));

Expression expr2adt(expr: (Expr)`<Expr lhs> + <Expr rhs>`, File file)
  = Expression(BinaryExpression(plus(), expr2adt(lhs, file), expr2adt(rhs, file), \uid = "<expr.src>"));

Expression expr2adt(expr: (Expr)`<Expr lhs> - <Expr rhs>`, File file)
  = Expression(BinaryExpression(minus(), expr2adt(lhs, file), expr2adt(rhs, file), \uid = "<expr.src>"));


// Translate ADT to concrete syntax

// In Rascal it is hard to generate lists for parse trees, 
// so we print the lists in a string and then parse the result to get a parse tree with the lists
// Question: current parsing doesn't recognize ";" in the end of the file, why?
str adt2text(ExpressionsFile exprFile)
  = "<intercalate("\n", ["<adt2statement(d, exprFile)>;" | d <- exprFile.\definitions])>
    '
    '<intercalate(";\n", ["<adt2statement(e, exprFile)>" | e <- exprFile.\expressions])>";

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