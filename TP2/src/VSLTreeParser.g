tree grammar VSLTreeParser;

options {
  language     = Java;
  tokenVocab   = VSLParser;
  ASTLabelType = CommonTree;
}

s [SymbolTable symTab] returns [Code3a code]
  : e=block[symTab]      { code = e; }
  ;

statement [SymbolTable symTab] returns [ExpAttribute expAtt]
  : ^(ASSIGN_KW e=expression[symTab] IDENT)
    {
      Operand3a temp = symTab.lookup($IDENT.text);
      Type ty = TypeCheck.checkBinOp(temp.type, e.type);
      Code3a cod = Code3aGenerator.genCopy(temp, e);
      expAtt = new ExpAttribute(ty, cod, temp);
    }
  // TODO, array
  ;

block [SymbolTable symTab] returns [Code3a code]
  : ^(BLOCK declaration[symTab] e=inst_list[symTab])
    {
      code = e;
    }
  | ^(BLOCK e=inst_list[symTab])
    {
      code = e;
    }
  ;

inst_list [SymbolTable symTab] returns [Code3a code]
  : ^(INST {code = new Code3a();} (e=statement[symTab] {code.append(e.code);})+)
  ;

expression [SymbolTable symTab] returns [ExpAttribute expAtt]
  : ^(PLUS e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.ADD, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }
  | ^(MINUS e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.SUB, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }
  | ^(MUL e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.MUL, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }
  | ^(DIV e1=expression[symTab] e2=expression[symTab])
    {
      Type ty = TypeCheck.checkBinOp(e1.type, e2.type);
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genBinOp(Inst3a.TAC.DIV, temp, e1, e2);
      expAtt = new ExpAttribute(ty, cod, temp);
    }
  | pe=primary_exp[symTab]
    { expAtt = pe; }
  ;

primary_exp [SymbolTable symTab] returns [ExpAttribute expAtt]
  : INTEGER
    {
      ConstSymbol cs = new ConstSymbol(Integer.parseInt($INTEGER.text));
      expAtt = new ExpAttribute(Type.INT, new Code3a(), cs);
    }
  | IDENT
    {
      Operand3a id = symTab.lookup($IDENT.text);
      expAtt = new ExpAttribute(id.type, new Code3a(), id);
    }
  ;

declaration [SymbolTable symTab] returns [Code3a code]
  : ^(DECL {code = new Code3a();} (decl_item[symTab] {code.append($decl_item.code);})+)
  ;

decl_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
      symTab.insert($IDENT.text, new VarSymbol(Type.INT, $IDENT.text, 0));
      code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  /*| ^(ARDECL IDENT INTEGER) {}  // TODO, array declaration*/
  ;
