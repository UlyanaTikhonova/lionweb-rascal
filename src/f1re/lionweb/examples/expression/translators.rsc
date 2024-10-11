module f1re::lionweb::examples::expression::translators

import IO;
import String;
import List;
import ParseTree;

import lionweb::pointer;

import f1re::lionweb::examples::expression::\syntax;
import f1re::lionweb::examples::expression::\lang;

// Translate concrete syntax to ADT
ExpressionsFile file2lion(File file, str filename = "")
  = ExpressionsFile(\body = [expr2adt(s, file) | (Stmnt)`<Stmnt s>` <- file.statements],
                    \name = filename,
                    \uid = "<file.src>");

// Statement stmnt2adt((Comp)`<DocAnno anno Expr expr>`)
//   = Statement();

Statement expr2adt((Stmnt)`<Def def>`, File file)
  = Statement(expr2adt(def, file));

Statement expr2adt((Stmnt)`<Comp comp>`, File file)
  = Statement(expr2adt(comp, file));

Computation expr2adt(Comp comp, File file)
  = Computation(expr2adt(comp.expr, file), 
                \annoDocumentation = [],
                \uid = "<comp.src>");

VariableDefinition expr2adt(Def definition, File file)
  = VariableDefinition(varName = "<definition.name>", 
                       varValue = [expr2adt(definition.val, file)],
                       \annoDocumentation = [],
                       \uid = "<definition.src>");

Expression expr2adt((Expr)`(<Expr e>)`, File file)
  = expr2adt(e, file);

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
  = "<intercalate(";\n", ["<adt2statement(s, exprFile)>" | s <- exprFile.\body])>";

File adt2parsetree(ExpressionsFile exprFile)
  = parse(#File, adt2text(exprFile));

// Stmnt adt2statement(Statement(VariableDefinition def), ExpressionsFile exprFile)
//   = (Stmnt)`<Identifier varId> = <Expr varVal>`
//   when varId := [Identifier]"<def.varName>",
//        varVal := adt2expr(def.varValue[0], exprFile);

Stmnt adt2statement(Statement(VariableDefinition def), ExpressionsFile exprFile)
  = (Stmnt)`<Identifier varId> = <Expr varVal>`
  when varId := [Identifier]"<def.varName>",
       varVal := adt2expr(def.varValue[0], exprFile);

Stmnt adt2statement(Statement(Computation comp), ExpressionsFile exprFile)
  = (Stmnt)`<Comp c>`
  when c := adt2expr(comp, exprFile);

Comp adt2expr(Computation(Expression expr), ExpressionsFile exprFile)
  = (Comp)`<Expr e>` 
  when Expr e := adt2expr(expr, exprFile);

Expr adt2expr(Expression(Literal l), ExpressionsFile exprFile)
  = (Expr)`<IntegerLiteral val>` 
  when IntegerLiteral val := [IntegerLiteral]"<l.\value>";

Expr adt2expr(Expression(VarReference vr), ExpressionsFile exprFile)
  = (Expr)`<Identifier vName>`
  when VariableDefinition vd := typeCast(#VariableDefinition, 
                              resolve(vr.\ref, [d | s <- exprFile.\body, Statement(VariableDefinition d) := s])), 
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