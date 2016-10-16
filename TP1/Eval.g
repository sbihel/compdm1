tree grammar Eval;

options {
    tokenVocab=Expr;
    ASTLabelType=CommonTree;
    output=String;
}

@members {
    private static long idCounter = 0;
    public static String createID() {
        return "_:" + String.valueOf(idCounter++);
    }

    public static String headXml =
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
"<rdf:RDF\n" +
"\txml:base=\"http://mydomain.org/myrdf/\"\n" +
"\txmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\">\n";
}

//prog returns [String s]:
//    document {$s = $document.s;};

//document returns [String s]:
//    ^(DOCUMENT {$s = "";} (sujet {$s += $sujet.s;})* EMPTY);

//sujet returns [String s]:
//    ^(SUJET {$s = "";} Entite (predicat[$Entite.text] {$s += $predicat.s;})* EMPTY)
//  | ^(SUJET {String idBlank = createID(); $s = "";}
//            EMPTY (predicat[idBlank] {$s += $predicat.s;})* EMPTY);  // Blank node

//predicat [String h] returns [String s]:
//    ^(PREDICAT {$s = "";} Entite (objet[$h + " " + $Entite.text] {$s += $objet.s;})* EMPTY);

//objet [String h] returns [String s]:
//    ^(OBJET a=(Entite|Texte)) {$s = $h + " " + $a.text + " .\n";}
//  | ^(SUJET {String idBlank = createID(); $s = $h + " " + idBlank + " .\n";}
//            EMPTY (predicat[idBlank] {$s += $predicat.s;})* EMPTY);  // Blank node


prog returns [String s]:
    document {$s = $document.s;};

document returns [String s]:
    ^(DOCUMENT {$s = headXml;} (sujet {$s += $sujet.s;})* {$s += "</rdf:RDF>\n";} EMPTY);

sujet returns [String s]:
    ^(SUJET Entite {$s = "<rdf:Description rdf:about="+$Entite.text.substring(1, $Entite.text.length()-1)+">\n";}
            (predicat["\t"] {$s += $predicat.s;})* {$s += "</rdf:Description>\n";} EMPTY)
  | ^(SUJET {String idBlank = createID(); $s = "<rdf:Description rdf:about=\""+idBlank+"\">\n";}
            EMPTY (predicat["\t"] {$s += $predicat.s;})* {$s += "</rdf:Description>\n";} EMPTY);  // Blank node

predicat [String tabs] returns [String s]:
    ^(PREDICAT {$s = "";} Entite (objet[$Entite.text.substring(1, $Entite.text.length()-1),
                                        $tabs] {$s += $objet.s;})* EMPTY);

objet [String h, String tabs] returns [String s]:
    ^(OBJET a=Entite) {$s = $tabs + "<" + $h + " rdf:resource=\"" +
                            $a.text.substring(1, $a.text.length()-1) + "\"/>\n";}
  | ^(OBJET a=Texte) {$s = $tabs + "<"+$h+">" + $a.text.substring(1, $a.text.length()-1) + "</"+$h+">\n";}
  | ^(SUJET {String idBlank = createID(); $s = $tabs + "<"+$h+" rdf:parseType=\"Resource"+idBlank+"\">\n";}
            EMPTY (predicat[$tabs+"\t"] {$s += $predicat.s;})* EMPTY);  // Blank node
