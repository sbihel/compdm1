parser grammar VSLParser;

options {
  language=Java;
  k=3;
  tokenVocab = VSLLexer;
  output = AST; 
}

// imaginaryTokenDefinitions
//    : BLOCK PROG ARRAY ARELEM ARDECL PARAM BODY DECL INST FCALL FCALL_S

tokens  {BLOCK; PROG; ARRAY; ARELEM; ARDECL; PARAM; BODY; DECL; INST; FCALL; FCALL_S;NEGAT;}

s
    : program
    ;

program
    : unit+ -> ^(PROG unit+)
    ;

unit
    : function
    | proto
    ;

function
    : FUNC_KW type IDENT LP param_list RP statement -> ^(FUNC_KW type IDENT param_list  ^(BODY statement))
    ;

proto
    : PROTO_KW^ type IDENT LP! param_list RP!
    ;

type
    : INT_KW^ 
    | VOID_KW^
    ;

param_list
    : param (COM param)* -> ^(PARAM param*)
    | -> ^(PARAM)
    ;

param
    : IDENT
    | IDENT LB RB -> ^(ARRAY IDENT)
    ;

statement
    : IDENT ASSIGN_KW expression -> ^(ASSIGN_KW expression IDENT)
    | array_elem ASSIGN_KW expression -> ^(ASSIGN_KW expression array_elem)
    | RETURN_KW^ expression
    | PRINT_KW^ print_list
    | READ_KW^ read_list
    | IF_KW^ expression THEN_KW! statement (ELSE_KW! statement)? FI_KW!
    | WHILE_KW^ expression DO_KW! statement OD_KW!
    | IDENT LP argument_list? RP -> ^(FCALL_S IDENT argument_list?)
    | block 
    ;

block
    : LC declaration inst_list RC -> ^(BLOCK declaration inst_list)
    | LC inst_list RC -> ^(BLOCK inst_list)
    ;
    
array_elem
    : IDENT LB expression RB ->  ^(ARELEM  IDENT expression)
    ;

inst_list
    : statement+ -> ^(INST statement+)
    ;

expression
    : factor ((PLUS^|MINUS^) factor)*
    ;

factor
    : primary ((MUL^|DIV^) primary)*
    ;

primary
    : INTEGER
    | IDENT
    | array_elem
    | IDENT LP argument_list? RP -> ^(FCALL IDENT argument_list?)
    | LP! expression RP!
    | MINUS primary -> ^(NEGAT primary)
    ;

argument_list
    : expression (COM! expression)*
    ;

print_list
    : print_item (COM! print_item)*
    ;

print_item
    : TEXT
    | expression
    ;

read_list
    : read_item (COM! read_item)*
    ;

read_item
    : IDENT
    | array_elem
    ;

declaration
    : (INT_KW decl_list)+  ->  ^(DECL decl_list+)
    ;
 
decl_list
    : decl_item (COM! decl_item)*
    ;

decl_item
    : IDENT
    | IDENT LB INTEGER RB -> ^(ARDECL IDENT INTEGER)
    ;


