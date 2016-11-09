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

/* Beginning of the parsing */
s returns [Code3a code] // The symbol table is synthetized here and not inherited
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
      symTab.insert($IDENT.text, new FunctionSymbol(new LabelSymbol($IDENT.text), ft));
    })

  | ^(FUNC_KW type IDENT 
    {
      // TODO, as for everything else we'll have to check the type of arguments <= But the type of the arguments is not specified, is it always INT or can it be TAB ?
      // TODO, a function might not have been prototyped <= this is only a problem if it is used before its definition
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
       ft.extend($p.ty);
       VarSymbol parameter = new VarSymbol($p.ty, $p.name, 1);
       parameter.setParam();
       symTab.insert($p.name, parameter);
       code.append(Code3aGenerator.genVar(symTab.lookup($p.name)));
    })*)
    ^(BODY statement[symTab]))
    {
      code.append($statement.code);
      //Leave the scope and the function
      symTab.leaveScope();
      code.append(Code3aGenerator.genEndfunc());
      // Add the function to the symtable
      symTab.insert($IDENT.text, new FunctionSymbol(funLabel, ft));
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
    })?  // TODO, use only 1 goto if there's no else
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
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        // Error : Undeclared function
      }
      FunctionType ft = new FunctionType(id.type);
    }
    (e=expression[symTab]
    {
      ft.extend(e.type);
      code.append(Code3aGenerator.genArg(e.place));
    })*)
    {
      // Check the args
      if (!ft.isCompatible(id.type)) {
        // Error : wrong arg
      }

      if(ft.getReturnType() != Type.VOID) {
        // Error : unused return value
      } else {
        code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));
        // ExpAtt is null here !
      }
    }

  | block[symTab] {code = $block.code;}
  ;

assignp [SymbolTable symTab, ExpAttribute e1] returns [Code3a code]
  : IDENT
    {
      code = Code3aGenerator.genCopy(symTab.lookup($IDENT.text), e1);
    }
  | ^(ARELEM  IDENT e2=expression[symTab])
    {
      code = Code3aGenerator.genVartab(symTab.lookup($IDENT.text), e2, e1);
    }
  ;


block [SymbolTable symTab] returns [Code3a code]
  : ^(BLOCK { symTab.enterScope(); } // Push a new symTable
    d=declaration[symTab] {code = d;}
    e=inst_list[symTab])
    {
      code.append(e);
      symTab.leaveScope(); // Pop the symTable
    }

  | ^(BLOCK  { symTab.enterScope(); } // Push a new symTable => We don't really need to do it here since there is no decl ?
    e=inst_list[symTab])
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
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        // Error : Undeclared identifier
      }
      expAtt = new ExpAttribute(id.type, new Code3a(), id);
    }

  | ^(ARELEM IDENT e=expression[symTab])
    {
      VarSymbol temp = SymbDistrib.newTemp();
      Operand3a id = symTab.lookup($IDENT.text);
      Code3a cod = Code3aGenerator.genTabvar(temp, id, e);
      expAtt = new ExpAttribute(id.type, cod, temp);
    }

  // TODO check if the function has been declared and if the type of the arguments matches with the declaration
  | ^(FCALL IDENT
    {
      Code3a code = new Code3a();
      VarSymbol temp = SymbDistrib.newTemp();
      code.append(Code3aGenerator.genVar(temp));
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        // Error : Undeclared identifier
      }
      if (!(id.type instanceof FunctionType)) {
      	System.out.println("Error : " + $IDENT.text + " is not a function");
      }
      FunctionType ft = (FunctionType) id.type;
      System.out.println("Call function : " + $IDENT.text + " : " + ft);
      FunctionType fun = new FunctionType(ft.getReturnType());
      System.out.println("Intermediate function : " + fun);
    }
    (e=expression[symTab]
    {
      code.append(e.code);
      System.out.println("Arg : " + e.place);
      fun.extend(e.type);
      code.append(Code3aGenerator.genArg(e.place)); // TODO : should be right before the function call
    })*)
    {
      // Check the args
      System.out.println("Final function : " + fun);
      if (!fun.isCompatible(ft)) {
      	System.out.println("Error : Wrong argument type in function: " + $IDENT.text + " : " + ft);
        // Error : wrong arg
      }

      if(fun.getReturnType() != Type.VOID) {
        code.append(Code3aGenerator.genCall(temp, new ExpAttribute(fun.getReturnType(), new Code3a(), id))); // Is error from here?
        expAtt = new ExpAttribute(fun.getReturnType(), code, temp);
      } else {
        // Error: void type
      }
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
      code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));
    }
  | e=expression[symTab]
    {
      code = new Code3a();
      code.append(e.code);
      code.append(Code3aGenerator.genArg(e.place));
      Operand3a id = SymbDistrib.builtinPrintN;
      code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));
    }
  ;

read_item [SymbolTable symTab] returns [Code3a code]
  : IDENT
    {
      code = Code3aGenerator.genArg(symTab.lookup($IDENT.text));
      Operand3a id = SymbDistrib.builtinRead;
      code.append(Code3aGenerator.genCall(new ExpAttribute(id.type, new Code3a(), id)));
    }
  /*| array_elem*/
  ;

/* Parameters */
/*param_list [SymbolTable symTab] returns [List<Type> lty, List<String> lnames]  // TODO, check that params aren't in symTab? => If they are, they belong to a different scope
  // TODO, that's stupid to use lists right? => I don't see other possibilities
  : ^(PARAM {$lty = new LinkedList<Type>(); $lnames = new LinkedList<String>();}
    (e=param[symTab] {$lty.add($e.ty); $lnames.add($e.name);})*)
  ;*/

param [SymbolTable symTab] returns [Type ty, String name]
  : IDENT {$ty = Type.INT; $name = $IDENT.text;}
  | ^(ARRAY IDENT) {$ty = Type.POINTER; $name = $IDENT.text;} // TODO, probably not good
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
      symTab.insert($IDENT.text, new VarSymbol(Type.INT, $IDENT.text, symTab.getScope()));
      code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  | ^(ARDECL IDENT INTEGER)
    {
      symTab.insert($IDENT.text, new VarSymbol(new ArrayType(Type.INT, Integer.parseInt($INTEGER.text)),
                                               $IDENT.text, symTab.getScope()));
      code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  ;
