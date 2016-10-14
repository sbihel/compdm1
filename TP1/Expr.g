grammar Expr;
options {
    output=AST;
    ASTLabelType=CommonTree; // type of $stat.tree ref etc...
}

tokens {
    DOCUMENT;
    SUJET;
    PREDICAT;
    EMPTY;
}

prog:       ( stat {System.out.println($stat.tree.toStringTree());} );

stat:       document EOF -> document;

document:   list_sujet -> ^(DOCUMENT list_sujet);

list_sujet:
      /* espilon */ -> EMPTY
    | sujet list_sujetDA -> sujet list_sujetDA;

list_sujetDA:
      list_sujet -> list_sujet;

sujet:
      Entite list_predicat '.' -> ^(SUJET Entite list_predicat);

list_predicat:
      predicat list_predicatp -> predicat list_predicatp;

list_predicatp:
      /* epsilon */ -> EMPTY
    | ';' predicat list_predicatpDA -> predicat list_predicatpDA;

list_predicatpDA:
      list_predicatp -> list_predicatp;

predicat:
      Entite liste_obj -> ^(PREDICAT Entite liste_obj);

liste_obj:
      objet liste_objp -> objet liste_objp;

liste_objp:
      /* epsilon */ -> EMPTY
    | ',' objet liste_objpDA -> objet liste_objpDA;

liste_objpDA:
      liste_objp -> liste_objp;

objet
    : Entite -> Entite
    | Texte -> Texte
    ;

Entite: '<'~('>')*'>';

Texte: '\"'~('\"')*'\"';

NEWLINE: ('\r'? '\n') { $channel=HIDDEN; };
WS  :   (' '|'\t')+ {skip();} ;
