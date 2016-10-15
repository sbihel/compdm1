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
}

prog:     stat {System.out.println($stat.tree.toStringTree());};

stat:     document EOF -> document;

document: sujet* -> ^(DOCUMENT sujet*);

sujet:    Entite predicat (';' predicat)* '.' -> ^(SUJET Entite predicat+);

predicat: Entite objet (',' objet)* -> ^(PREDICAT Entite objet+);

objet:    Entite -> ^(OBJET Entite)
        | Texte -> ^(OBJET Texte);

Entite: '<'~('>')*'>';

Texte: '\"'~('\"')*'\"';

NEWLINE: ('\r'? '\n') { $channel=HIDDEN; };
WS  :   (' '|'\t')+ {skip();} ;
