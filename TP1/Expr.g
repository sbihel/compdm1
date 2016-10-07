grammar Expr;
//options {
//    output=AST;
//    ASTLabelType=CommonTree; // type of $stat.tree ref etc...
//}

//prog:   ( stat {System.out.println($stat.tree.toStringTree());} )+ ;

prog: stat ;

stat:   document EOF {System.out.println($document.s);};// -> document;

document returns [String s]:
      list_sujet {$s = $list_sujet.s;};

list_sujet returns [String s]:
      /* espilon */ {$s = "";}
    | sujet list_sujetDA {$s = $sujet.s + $list_sujetDA.s;};

list_sujetDA returns [String s]:
      list_sujet {$s = $list_sujet.s;};

sujet returns [String s]:
      Entite list_predicat[$Entite.text] '.' {$s = $list_predicat.s;};

list_predicat [String h] returns [String s]:
      predicat[$h] list_predicatp[$h] {$s = $predicat.s + $list_predicatp.s;};

list_predicatp [String h] returns [String s]:
      /* epsilon */ {$s = "";}
    | ';' predicat[$h] list_predicatpDA[$h] {$s = $predicat.s + $list_predicatpDA.s;};

list_predicatpDA [String h] returns [String s]:
      list_predicatp[$h] {$s = $list_predicatp.s;};

predicat [String h] returns [String s]:
      Entite liste_obj[$h + " " + $Entite.text] {$s = $liste_obj.s;};

liste_obj [String h] returns [String s]:
      objet[$h] liste_objp[$h] {$s = $objet.s + $liste_objp.s;};

liste_objp [String h] returns [String s]:
      /* epsilon */ {$s = "";}
    | ',' objet[$h] liste_objpDA[$h] {$s = $objet.s + $liste_objpDA.s;};

liste_objpDA [String h] returns [String s]:
      liste_objp[$h] {$s = $liste_objp.s;};

objet [String h] returns [String s]:
      Entite {$s = $h + " " + $Entite.text + " .\n";}
    | Texte {$s = $h + " " + $Texte.text + " .\n";}
    ;

Entite: '<'~('>')*'>';

Texte: '\"'~('\"')*'\"';

NEWLINE: ('\r'? '\n') { $channel=HIDDEN; };
WS  :   (' '|'\t')+ {skip();} ;
