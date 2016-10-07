tree grammar Eval;

options {
    tokenVocab=Expr;
    ASTLabelType=CommonTree;
}

@header {
import java.util.HashMap;
import java.lang.Math;
}

@members {
/** Map variable name to Integer object holding value */
HashMap memory = new HashMap();
}

prog:   stat+ ;

stat:   expr
        {System.out.println($expr.value);}
    |   ^('=' ID expr)
        {memory.put($ID.text, new Integer($expr.value));}
    ;

expr [string s] returns [string value]
    : ^('document' a=list_sujet)           {$value = a;}
    | ^('list_sujet' a=sujet b=list_sujet) {$value = a + "\n" + b;}
    | ^('list_sujet')                      {$value = "";}
    | ^('sujet' )                           {$value = ;}

    | ^('liste_obj')
    | ^('liste_objp' a=objet b=liste_objp)  {$value = a + ", " + b;}
    | ^('liste_objp')  {$value = "";}
    | ^('objet' a=entite) {$value = a;}
    | ^('objet' a=texte)  {$value = a;}
    ;
