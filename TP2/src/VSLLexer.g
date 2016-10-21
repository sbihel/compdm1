lexer grammar VSLLexer;


options {
  language = Java;
  k=3;
}
  
WS      : (' '|'\n'|'\t') {$channel = HIDDEN;}
    ;

COMMENT : '//' (~'\n')* {$channel = HIDDEN;}
    ;

fragment LETTER : 'a'..'z' ;
fragment DIGIT  : '0'..'9' ;
fragment ASCII  : ~('\n'|'\"');

// keywords
LP    : '(' ; // Left parenthesis
RP    : ')' ;
LB    : '[' ; // Left bracket
RB    : ']' ;
LC    : '{' ; // Left curly bracket
RC    : '}' ;
COM   : ',' ;
FUNC_KW   : 'FUNC'   ;
PROTO_KW  : 'PROTO'  ;
INT_KW    : 'INT'    ;
VOID_KW   : 'VOID'   ;
ASSIGN_KW : ':='     ;
RETURN_KW : 'RETURN' ;
PRINT_KW  : 'PRINT'  ;
READ_KW   : 'READ'   ;
IF_KW     : 'IF'     ;
THEN_KW   : 'THEN'   ;
ELSE_KW   : 'ELSE'   ;
FI_KW     : 'FI'     ;
WHILE_KW  : 'WHILE'  ;
DO_KW     : 'DO'     ;
OD_KW     : 'DONE'   ;
PLUS      : '+'      ;
MINUS     : '-'      ;
MUL       : '*'      ;
DIV       : '/'      ;

// other tokens (no conflict with keywords in VSL)

IDENT   : LETTER (LETTER|DIGIT)*;
TEXT    : '"' (ASCII)* '"';
INTEGER : (DIGIT)+ ;
