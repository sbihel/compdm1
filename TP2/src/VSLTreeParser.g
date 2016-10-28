tree grammar VSLTreeParser;

options {
  language     = Java;
  tokenVocab   = VSLParser;
  ASTLabelType = CommonTree;
}

@header {
  import java.util.List;
  import java.util.LinkedList;
}

s [SymbolTable symTab] returns [Code3a code]
  : ^(PROG {code = new Code3a();} (e=unit[symTab] {code.append($e.code);})+)
  ;

unit [SymbolTable symTab] returns [Code3a code]
  : ^(PROTO_KW type IDENT e=param_list[symTab])
    {
      FunctionType ft = new FunctionType($type.ty, true);
      for(int i = 0; i < $e.lty.size(); i++)
        ft.extend($e.lty.get(i));
      /*symTab.insert($IDENT.text, new FunctionSymbol(SymbDistrib.newLabel(), ft));*/
      symTab.insert($IDENT.text, new FunctionSymbol(new LabelSymbol($IDENT.text), ft));
    }
  | ^(FUNC_KW type IDENT e=param_list[symTab]
    {
      // TODO, as for everything else we'll have to check the type of arguments
      // TODO, a function might not have been prototyped
      code = new Code3a();
      for(int i = 0; i < $e.lnames.size(); i++) {
        symTab.insert($e.lnames.get(i), new VarSymbol($e.lty.get(i), $e.lnames.get(i), 1));
        code.append(Code3aGenerator.genVar(symTab.lookup($e.lnames.get(i))));
      }
    }
    ^(BODY statement[symTab]))
    {
      code.append($statement.code);
    }
  ;

statement [SymbolTable symTab] returns [Code3a code]
  : ^(ASSIGN_KW e=expression[symTab] IDENT)
    {
      code = Code3aGenerator.genCopy(symTab.lookup($IDENT.text), e);
    }
  // TODO, array
  | ^(RETURN_KW e=expression[symTab])
    {
      code = Code3aGenerator.genRet(e.place);
    }
  | ^(IF_KW {code = new Code3a();
            LabelSymbol tempL1 = SymbDistrib.newLabel();
            LabelSymbol tempL2 = SymbDistrib.newLabel();}
    e1=expression[symTab] {code.append(Code3aGenerator.genIfz(e1, tempL1));}
    e2=statement[symTab] {code.append(e2);
                          code.append(Code3aGenerator.genGoto(tempL2));
                          code.append(Code3aGenerator.genLabel(tempL1));}
    (e3=statement[symTab] {code.append(e3);})?  // TODO, use only 1 goto if there's no else
    {code.append(Code3aGenerator.genLabel(tempL2));})
  | ^(WHILE_KW {code = new Code3a();
                LabelSymbol tempL1 = SymbDistrib.newLabel();
                LabelSymbol tempL2 = SymbDistrib.newLabel();
                code.append(Code3aGenerator.genLabel(tempL1));}
    e1=expression[symTab] {code.append(Code3aGenerator.genIfz(e1, tempL2));}
    e2=statement[symTab] {code.append(e2);
                          code.append(Code3aGenerator.genGoto(tempL1));
                          code.append(Code3aGenerator.genLabel(tempL2));})
  | block[symTab] {code = $block.code;}
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
  : ^(INST {code = new Code3a();} (e=statement[symTab] {code.append(e);})+)
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
  | ^(FCALL IDENT {Code3a code = new Code3a(); Operand3a id = symTab.lookup($IDENT.text);} (e=expression[symTab]
    {
      code.append(Code3aGenerator.genArg(e.place));
    })*)
    {
      VarSymbol temp = SymbDistrib.newTemp();
      code.append(Code3aGenerator.genCall(temp, new ExpAttribute(id.type, new Code3a(), id)));
      expAtt = new ExpAttribute(id.type, code, temp);
    }
  ;

param_list [SymbolTable symTab] returns [List<Type> lty, List<String> lnames]  // TODO, check that params aren't in symTab?
  // TODO, that's stupid to use lists right?
  : ^(PARAM {$lty = new LinkedList<Type>(); $lnames = new LinkedList<String>();}
    (e=param[symTab] {$lty.add($e.ty); $lnames.add($e.name);})*)
  ;

param [SymbolTable symTab] returns [Type ty, String name]
  : IDENT {$ty = Type.INT; $name = $IDENT.text;}
  | ^(ARRAY IDENT) {$ty = Type.POINTER; $name = $IDENT.text;}
  ;

type returns [Type ty]
  : INT_KW {ty = Type.INT;}
  | VOID_KW {ty = Type.VOID;}
  ;

declaration [SymbolTable symTab] returns [Code3a code]
  : ^(DECL {code = new Code3a();} (decl_item[symTab] {code.append($decl_item.code);})+)
  ;

decl_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
      symTab.insert($IDENT.text, new VarSymbol(Type.INT, $IDENT.text, 0));  // TODO, understand scope
      code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  /*| ^(ARDECL IDENT INTEGER) {}  // TODO, array declaration*/
  ;
