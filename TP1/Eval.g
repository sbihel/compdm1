tree grammar Eval;

options {
    tokenVocab=Expr;
    ASTLabelType=CommonTree;
    output=template;
}

@header {
}

@members {
}

prog returns [String s]: document {$s = $document.s;};

document returns [String s]: ^(DOCUMENT (a+=sujet)*)  // we'll need to define a scope to access .s
    {$s = ""; for(int i = 0; i < $a.size(); i++) {$s = $a.get(i).s + $s;}};

sujet returns [String s]: ^(SUJET a=Entite (b+=predicat[$a.text])*)
    {$s = ""; for(int i = 0; i < $b.size(); i++) {$s = $b.get(i).s + $s;}};

empty returns [String s]: EMPTY {$s = "";};

predicat [String h] returns [String s]: ^(PREDICAT a=objet[$h] (b+=objet[$a.s])*)
    {$s = ""; for(int i = 0; i < $b.size(); i++) {$s = $b.get(i).s + $s;}};

objet [String h] returns [String s]: ^(OBJET a=(Entite|Texte)) {$s = $h + " " + $a.text + " .\n";};

//expr returns [String s]
//    : ^(DOCUMENT a+=expr)
//        {$s = ""; for(int i = 0; i < a.size(); i++) {$s = $a.get(i).s + $s;}}
//    | ^(SUJET a=expr b+=expr2[$a.text])
//        {$s = ""; for(int i = 0; i < b.size(); i++) {$s = $b.get(i).s + $s;}}
//    | EMPTY {$s = "";}
//    ;
//expr2 [String h] returns [String s]
//    : ^(PREDICAT a=expr2[$h] b+=expr2[$a.s])
//        {$s = ""; for(int i = 0; i < b.size(); i++) {$s = $b.get(i).s + $s;}}
//    | ^(OBJET a=expr)    {$s = $h + " " + $a.text + " .\n";}
//    ;
