grammar Expr;
options {
    output=AST;
    ASTLabelType=CommonTree; // type of $stat.tree ref etc...
}

tokens {
    DOCUMENT;
    SUJET;
    PREDICAT;
    OBJET;
    EMPTY;  // Used to put something where there should be nothing. Antlr3 can't concatenate list of nodes with nothing
}

prog:       stat {System.out.println($stat.tree.toStringTree());};

stat:       document EOF -> document;

document:   list_sujet -> ^(DOCUMENT list_sujet);

list_sujet:
      /* espilon */ -> EMPTY
    | sujet list_sujet -> sujet list_sujet;

sujet:
      Entite list_predicat '.' -> ^(SUJET Entite list_predicat)
    | '[' list_predicat ']' '.' -> ^(SUJET EMPTY list_predicat);

list_predicat:
      predicat list_predicatp -> predicat list_predicatp;

list_predicatp:
      /* epsilon */ -> EMPTY
    | ';' predicat list_predicatp -> predicat list_predicatp;

predicat:
      Entite liste_obj -> ^(PREDICAT Entite liste_obj);

liste_obj:
      objet liste_objp -> objet liste_objp;

liste_objp:
      /* epsilon */ -> EMPTY
    | ',' objet liste_objp -> objet liste_objp;

objet
    : Entite -> ^(OBJET Entite)
    | Texte -> ^(OBJET Texte)
    | '[' list_predicat ']' -> ^(SUJET EMPTY list_predicat)  // Blank node
    ;

Entite: '<'~('>')*'>';

Texte: '\"'~('\"')*'\"';

NEWLINE: ('\r'? '\n') { $channel=HIDDEN; };
WS  :   (' '|'\t')+ {skip();} ;
