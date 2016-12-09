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



/* TODO : fix the function call on arrays : 
 * incompatible types: expected 'FUNC[POINTER] : VOID',
 *                          got 'FUNC[ARRAY(INT)] : VOID'
 */

/* Beginning of the parsing */
s returns [Code3a code]
  : ^(PROG {code = new Code3a(); SymbolTable symTab = new SymbolTable(); } (e=unit[symTab] {code.append($e.code);})+)
  ;

/* Base unit of the program : function or prototype */
unit [SymbolTable symTab] returns [Code3a code]
  : ^(PROTO_KW type IDENT
    {
      FunctionType ft = new FunctionType($type.ty, true);
    }
    ^(PARAM (p=param[symTab]
    {
      // Add the parameters
      ft.extend($p.ty);
    })*)
    {
      // Check if the function is alredy declared
      TypeCheck.checkProtoDecl($PROTO_KW, $IDENT.text, ft, symTab);
      // Add the function to the symTab
      TypeCheck.reserveFunctionName($PROTO_KW, $IDENT.text, ft, symTab);
    })

  | ^(FUNC_KW type IDENT 
    {
      code = new Code3a();
      FunctionType ft = new FunctionType($type.ty, false);
      LabelSymbol funLabel = new LabelSymbol($IDENT.text);

      // Print the label and the begining of the function
      code.append(Code3aGenerator.genBeginfunc(funLabel));
      // Create a new scope for the funtion definition
      symTab.enterScope();
    }
    ^(PARAM (p=param[symTab]
    {
       // Add the parameters
       VarSymbol param = TypeCheck.checkAndDeclParm($PARAM, $p.name, $p.ty, symTab); 
       ft.extend($p.ty);
       code.append(Code3aGenerator.genVar(param));
    })*)
    ^(BODY statement[symTab]))
    {
      code.append($statement.code);
      //Leave the scope and the function
      symTab.leaveScope();
      code.append(Code3aGenerator.genEndfunc());
      // Check if the function is alredy declared or if it fits its proto
      TypeCheck.checkFuncDecl($FUNC_KW, $IDENT.text, ft, symTab);
      // Add the function to the symtable
      TypeCheck.reserveFunctionName($FUNC_KW, $IDENT.text, ft, symTab);
    }
  ;

/* Statement */
statement [SymbolTable symTab] returns [Code3a code]
  : ^(ASSIGN_KW e=expression[symTab] a=assignp[symTab, e])
    {
      code = a;
    }

  | ^(RETURN_KW e=expression[symTab])
    {
      // Checks the return type => must be INT
      TypeCheck.checkReturnType($RETURN_KW, e.type);
      code = e.code;
      code.append(Code3aGenerator.genRet(e.place));
    }

  | ^(PRINT_KW {code = new Code3a();} (p=print_item[symTab] {code.append(p);})+)

  | ^(READ_KW {code = new Code3a();} (r=read_item[symTab] {code.append(r);})+)

  | ^(IF_KW
    {
      code = new Code3a();
      LabelSymbol tempL1 = SymbDistrib.newLabel();
      LabelSymbol tempL2 = SymbDistrib.newLabel();
    }
    e1=expression[symTab]
    {
      code.append(e1.code);
      code.append(Code3aGenerator.genIfz(e1, tempL1));
    }
    e2=statement[symTab]
    {
      code.append(e2);
      code.append(Code3aGenerator.genGoto(tempL2));
      code.append(Code3aGenerator.genLabel(tempL1));
    }
    (e3=statement[symTab] {
      code.append(e3);
    })? // TODO, use only 1 goto if there's no else
    {
      code.append(Code3aGenerator.genLabel(tempL2));
    })

  | ^(WHILE_KW
    {
      code = new Code3a();
      LabelSymbol tempL1 = SymbDistrib.newLabel();
      LabelSymbol tempL2 = SymbDistrib.newLabel();
      code.append(Code3aGenerator.genLabel(tempL1));
    }
    e1=expression[symTab]
    {
      code.append(e1.code);
      code.append(Code3aGenerator.genIfz(e1, tempL2));
    }
    e2=statement[symTab]
    {
      code.append(e2);
      code.append(Code3aGenerator.genGoto(tempL1));
      code.append(Code3aGenerator.genLabel(tempL2));
    })

  | ^(FCALL_S IDENT
    {
      code = new Code3a();
      // Creates the function type to check the type
      FunctionType ft = new FunctionType(Type.VOID);
      ArrayList<ExpAttribute> args = new ArrayList<>(); 
    }
    (e=expression[symTab]
    {
      code.append(e.code);
      ft.extend(e.type);
      args.add(e);
    })*)
    {
      for (ExpAttribute elem : args) {
        code.append(Code3aGenerator.genArg(elem.place));
      }
      // Check the function call
      Operand3a fun = TypeCheck.checkFuncCall($FCALL_S, $IDENT.text, ft, symTab);
      // Makes the Call
      code.append(Code3aGenerator.genCall(new ExpAttribute(ft.getReturnType(), new Code3a(), fun)));
    }

  | block[symTab] {code = $block.code;}
  ;

assignp [SymbolTable symTab, ExpAttribute e1] returns [Code3a code]
  : IDENT
    {
      Operand3a id = TypeCheck.checkIdent($IDENT, $IDENT.text, symTab);
      TypeCheck.checkAssign($IDENT, id.type, e1.type);
      code = Code3aGenerator.genCopy(id, e1);
    }
  | ^(ARELEM IDENT e2=expression[symTab])
    {
      Operand3a id = TypeCheck.checkArrayElem($IDENT, $IDENT.text, e2.type, symTab);
      TypeCheck.checkAssign($IDENT, Type.INT, e1.type);
      code = Code3aGenerator.genVartab(id, e2, e1);
    }
  ;


block [SymbolTable symTab] returns [Code3a code]
  : ^(BLOCK { symTab.enterScope(); } // Push a new symTable
    b=blockP[symTab]) { code = b; }
  ;

blockP [SymbolTable symTab] returns [Code3a code]
  : d=declaration[symTab] {code = d;}
    e=inst_list[symTab]
    {
      code.append(e);
      symTab.leaveScope(); // Pop the symTable
    }
  | e=inst_list[symTab]
    {
      code = e;
      symTab.leaveScope(); // Pop the symTable
    }
  ;

inst_list [SymbolTable symTab] returns [Code3a code]
  : ^(INST {code = new Code3a();} (e=statement[symTab] {code.append(e);})+)
  ;

/* Expressions */
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
      Operand3a id = TypeCheck.checkIdent($IDENT, $IDENT.text, symTab);
      expAtt = new ExpAttribute(id.type, new Code3a(), id);
    }

  | ^(ARELEM IDENT e=expression[symTab])
    {
      VarSymbol temp = SymbDistrib.newTemp();
      Operand3a id = TypeCheck.checkArrayElem($IDENT, $IDENT.text, e.type, symTab);
      Code3a cod = Code3aGenerator.genTabvar(temp, id, e);
      expAtt = new ExpAttribute(Type.INT, cod, temp);
    }

  | ^(FCALL IDENT
    {
      Code3a code = new Code3a();
      VarSymbol temp = SymbDistrib.newTemp();
      code.append(Code3aGenerator.genVar(temp));
      FunctionType ft = new FunctionType(Type.INT);
      ArrayList<ExpAttribute> args = new ArrayList<>();
    }
    (e=expression[symTab]
    {
      code.append(e.code);
      ft.extend(e.type);
      args.add(e);
    })*)
    {
      for (ExpAttribute elem : args) {
        code.append(Code3aGenerator.genArg(elem.place));
      }
      // Check the function call
      Operand3a fun = TypeCheck.checkFuncCall($FCALL, $IDENT.text, ft, symTab);
      // Makes the Call
      code.append(Code3aGenerator.genCall(temp, new ExpAttribute(ft.getReturnType(), new Code3a(), fun)));
      expAtt = new ExpAttribute(ft.getReturnType(), code, temp);
    }

  | ^(NEGAT e=primary_exp[symTab])
    {
      VarSymbol temp = SymbDistrib.newTemp();
      Code3a cod = Code3aGenerator.genNeg(temp, e);
      expAtt = new ExpAttribute(e.type, cod, temp);
    }
  ;

print_item [SymbolTable symTab] returns [Code3a code]
  : TEXT
    {
      code = new Code3a();
      Data3a dat = new Data3a($TEXT.text);
      code.append(Code3aGenerator.genArg(dat.getLabel()));
      code.appendData(dat);
      Operand3a id = SymbDistrib.builtinPrintS;
      code.append(Code3aGenerator.genCall(new ExpAttribute(Type.VOID, new Code3a(), id)));
    }
  | e=expression[symTab]
    {
      code = new Code3a();
      code.append(e.code);
      code.append(Code3aGenerator.genArg(e.place));
      Operand3a id = SymbDistrib.builtinPrintN;
      code.append(Code3aGenerator.genCall(new ExpAttribute(Type.VOID, new Code3a(), id)));
    }
  ;

read_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
      code = new Code3a();
      Operand3a id = TypeCheck.checkIdent($IDENT, $IDENT.text, symTab);
      TypeCheck.checkAssign($IDENT, id.type, Type.INT);
      Operand3a lab = SymbDistrib.builtinRead;
      code.append(Code3aGenerator.genCall(id, new ExpAttribute(id.type, new Code3a(), lab)));
    }

  | ^(ARELEM IDENT e=expression[symTab])
    {
      // Use a temp var for READ and then copy the value to the array element
      VarSymbol temp = SymbDistrib.newTemp();
      code = new Code3a();
      Operand3a id = TypeCheck.checkArrayElem($IDENT, $IDENT.text, e.type, symTab);
      Operand3a lab = SymbDistrib.builtinRead;
      code.append(Code3aGenerator.genCall(temp, new ExpAttribute(id.type, new Code3a(), lab)));
      code.append(Code3aGenerator.genVartab(id, e, new ExpAttribute(id.type, new Code3a(), temp)));
    }
  ;

param [SymbolTable symTab] returns [Type ty, String name]
  : IDENT {$ty = Type.INT; $name = $IDENT.text;}
  | ^(ARRAY IDENT) {$ty = Type.POINTER; $name = $IDENT.text;}
  ;

/* Type */
type returns [Type ty]
  : INT_KW {ty = Type.INT;}
  | VOID_KW {ty = Type.VOID;}
  ;

/* Declarations */
declaration [SymbolTable symTab] returns [Code3a code]
  : ^(DECL {code = new Code3a();} (e=decl_item[symTab] {code.append(e);})+)
  ;

decl_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
        // Put the identifier in the symTable
        Operand3a id = TypeCheck.checkAndDeclIdent($IDENT, $IDENT.text, Type.INT, symTab);
        code = Code3aGenerator.genVar(id);
    }
  | ^(ARDECL IDENT INTEGER)
    {
        // Put the identifier in the symTable
        Operand3a id = TypeCheck.checkAndDeclArray($ARDECL, $IDENT.text, Integer.parseInt($INTEGER.text), symTab);
        code = Code3aGenerator.genVar(id);
    }
  ;
