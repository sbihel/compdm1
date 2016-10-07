grammar Expr;
options {
    output=AST;
    ASTLabelType=CommonTree; // type of $stat.tree ref etc...
}

prog:   ( stat {System.out.println($stat.tree.toStringTree());} )+ ;

stat:   document NEWLINE        -> document
    ;

document returns [string s]:
      list_sujet {$s = $list_sujet.s;};

list_sujet return [string s]:
      sujet list_sujet {$s = $sujet.s + $list_sujet.s;}
    | /* espilon */ {$s = "";};

sujet returns [string s]:
      Entite list_predicat[$Entite.text] '.' {$s = $list_predicat.s;};

list_predicat [string h] returns [string s]:
      predicat[$h] {$s = $predicat.s;}
    | list_predicatp[$h] {$s = $list_predicatp.s;};

list_predicatp [string h] returns [string s]:
      /* epsilon */ {$s = "";}
    | ';' predicat[$h] list_predicatp[$h] {$s = $predicat.s + $list_predicatp.s;};

predicat [string h] returns [string s]:
      Entite liste_obj[$h + " " + $Entite.text] {$s = $liste_obj.s};

liste_obj [string h] returns [string s]:
      objet[$h] liste_objp[$h] {$s = $objet + "\n" + $liste_objp.s};

liste_objp [string h] returns [string s]:
      /* epsilon */ {$s = "";}
    | ',' objet[$h] liste_objp[$h] {$s = $objet.s + "\n" + $liste_objp.s};

objet [string h] returns [string s]:
      Entite {System.out.println($h + $Entite.text + "."); $s = $h + $Entite.text + ".";}
    | Texte {System.out.println($h + $Texte.text + "."); $s = $h + $Texte.text + ".";}
    ;

Entite: '<'~('>')*'>';

Texte: '\"'~('\"')*'\"';

ID  :   ('a'..'z'|'A'..'Z')+ ;
INT :   '0'..'9'+ ;
NEWLINE:'\r'? '\n' ;
WS  :   (' '|'\t')+ {skip();} ;
