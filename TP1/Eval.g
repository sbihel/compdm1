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

// Simply returning a string seems hard if possible for Test.java
//prog returns [String s]: document {$s = $document.s;};
prog: document {System.out.println($document.s);};

// You lose the elements if you use the built-in List construction += symbol. So you end-up with just a List of the
// right size but you can't do more with it. It's a shame, it would have been pretty with it...
// One solution is to build manualy a List and fill it each time you encounter a node

//document returns [String s]: ^(DOCUMENT (a+=sujet)* EMPTY)
//    {$s = ""; for(int i = 0; i < $a.size(); i++) {$s += $a.get(i).s;}};
document returns [String s] @init{ List<String> sl = new ArrayList<String>(); }:
    ^(DOCUMENT (a=sujet {sl.add($a.s);})* EMPTY)
    {$s = ""; for(int i = 0; i < sl.size(); i++) {$s += sl.get(i);}};

//sujet returns [String s]: ^(SUJET a=Entite (b+=predicat[$a.text])* EMPTY)
//    {$s = ""; for(int i = 0; i < $b.size(); i++) {$s += $b.get(i).s;}};
sujet returns [String s] @init{ List<String> sl = new ArrayList<String>(); }:
    ^(SUJET a=Entite (b=predicat[$a.text] {sl.add($b.s);})* EMPTY)
    {$s = ""; for(int i = 0; i < sl.size(); i++) {$s += sl.get(i);}};

//predicat [String h] returns [String s]: ^(PREDICAT a=Entite (b+=objet[$h + " " + $Entite.text])* EMPTY)
//    {$s = ""; for(int i = 0; i < $b.size(); i++) {$s += $b.get(i).s;}};
predicat [String h] returns [String s] @init{ List<String> sl = new ArrayList<String>(); }:
    ^(PREDICAT a=Entite (b=objet[$h + " " + $Entite.text] {sl.add($b.s);})* EMPTY)
    {$s = ""; for(int i = 0; i < sl.size(); i++) {$s += sl.get(i);}};

empty: EMPTY;

objet [String h] returns [String s]: ^(OBJET a=(Entite|Texte)) {$s = $h + " " + $a.text + " .\n";};
