//tree grammar Eval;

//options {
//    tokenVocab=Expr;
//    ASTLabelType=CommonTree;
//}

//@header {
//}

//@members {
//}

//prog:   stat+ EOF ;

//stat:   expr
//        {System.out.println($expr.s);}
//    ;

//expr returns [string s]
//    //: ^('document' a=list_sujet)           {$value = a;}
//    //| ^('list_sujet' a=sujet b=list_sujet) {$value = a + "\n" + b;}
//    //| ^('list_sujet')                      {$value = "";}
//    //| ^('sujet' )                           {$value = ;}

//    //| ^('liste_obj')
//    //| ^('liste_objp' a=objet b=liste_objp)  {$value = a + ", " + b;}
//    //| ^('liste_objp')  {$value = "";}
//    //| ^('objet' a=entite) {$value = a;}
//    //| ^('objet' a=texte)  {$value = a;}
//    :
//    //| Entite {$s = $Entite.text;}
//    //| Texte {$s = $Texte.text;}
//    ;
