tree grammar Eval;

options {
    tokenVocab=Expr;
    ASTLabelType=CommonTree;
    output=String;
}

prog returns [String s]:
    document {$s = $document.s;};

document returns [String s]:
    ^(DOCUMENT {$s = "";} (sujet {$s += $sujet.s;})* EMPTY);

sujet returns [String s]:
    ^(SUJET {$s = "";} Entite (predicat[$Entite.text] {$s += $predicat.s;})* EMPTY);

predicat [String h] returns [String s]:
    ^(PREDICAT {$s = "";} Entite (objet[$h + " " + $Entite.text] {$s += $objet.s;})* EMPTY);

objet [String h] returns [String s]:
    ^(OBJET a=(Entite|Texte)) {$s = $h + " " + $a.text + " .\n";};
