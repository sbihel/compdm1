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
      // Check if the function is already defined
      if(symTab.lookup($IDENT.text) != null) {
          Errors.redefinedIdentifier($IDENT, $IDENT.text, null);
          System.exit(1);
      }
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
      // Check the definition
      Operand3a fid = symTab.lookup($IDENT.text);
      FunctionType proto = null;
      if(fid != null) {
          // Check if the identifier is already used
          if(!(fid.type instanceof FunctionType)) {
              Errors.redefinedIdentifier($IDENT, $IDENT.text, null);
              System.exit(1);
          } else {
              proto = (FunctionType) fid.type;
              // Check if the previous definition is a prototype
              if(!proto.prototype) {
                  Errors.redefinedIdentifier($IDENT, $IDENT.text, null);
                  System.exit(1);
              }
          }
      }
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
    {
        // Checks if the function matches the prototype
        if(proto != null) {
            if (!ft.isCompatible(proto)) {
                Errors.incompatibleTypes($IDENT, proto, ft, null);
                System.exit(1);
            } 
        }
    }
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
      // Checks the return type => must be INT
      if (e.type != Type.INT) {
        Errors.incompatibleTypes($RETURN_KW, Type.INT, e.type, null);
        System.exit(1);
      }
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
        Errors.unknownIdentifier($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      FunctionType fun = new FunctionType(Type.VOID);
      if (!(id.type instanceof FunctionType)) {
      	Errors.incompatibleTypes($IDENT, id.type, fun, null);
        System.exit(1);
      }
      FunctionType proto = (FunctionType) id.type;
    }
    (e=expression[symTab]
    {
      code.append(e.code);
      fun.extend(e.type);
      code.append(Code3aGenerator.genArg(e.place));
    })*)
    {
      // Check the function call
      if (!fun.isCompatible(proto)) {
        Errors.incompatibleTypes($IDENT, proto, fun, null);
        System.exit(1);
      }
      // Makes the Call
      code.append(Code3aGenerator.genCall(new ExpAttribute(fun.getReturnType(), new Code3a(), id)));
    }

  | block[symTab] {code = $block.code;}
  ;

assignp [SymbolTable symTab, ExpAttribute e1] returns [Code3a code]
  : IDENT
    {
      // Check the type of the elements
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, null);
        System.exit(1);
      }
      if (id.type != e1.type) {
          Errors.incompatibleTypes($IDENT, id.type, e1.type, null);
          System.exit(1);
      }
      code = Code3aGenerator.genCopy(id, e1);
    }
  | ^(ARELEM IDENT e2=expression[symTab])
    {
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, null);
        System.exit(1);
      }
      if (Type.INT != e2.type) {
          Errors.incompatibleTypes($IDENT, Type.INT, e2.type, null);
          System.exit(1);
      }
      code = Code3aGenerator.genVartab(id, e2, e1);
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
          Errors.unknownIdentifier($IDENT, $IDENT.text, null);
        System.exit(1);
      }
      expAtt = new ExpAttribute(id.type, new Code3a(), id);
    }

  | ^(ARELEM IDENT e=expression[symTab])
    {
      VarSymbol temp = SymbDistrib.newTemp();
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      Code3a cod = e.code;
      cod.append(Code3aGenerator.genTabvar(temp, id, e));
      expAtt = new ExpAttribute(Type.INT, cod, temp);
      System.out.println("Tab expatt : " + expAtt.type + " " + expAtt.code + " " + expAtt.place + " ");
    }

  | ^(FCALL IDENT
    {
      Code3a code = new Code3a();
      VarSymbol temp = SymbDistrib.newTemp();
      code.append(Code3aGenerator.genVar(temp));
      Operand3a id = symTab.lookup($IDENT.text);
      if (id == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      FunctionType fun = new FunctionType(Type.INT);
      if (!(id.type instanceof FunctionType)) {
      	Errors.incompatibleTypes($IDENT, id.type, fun, null);
        System.exit(1);
      }
      FunctionType proto = (FunctionType) id.type;
    }
    (e=expression[symTab]
    {
      code.append(e.code);
      fun.extend(e.type);
      code.append(Code3aGenerator.genArg(e.place));
    })*)
    {
      // Check the function call
      if (!fun.isCompatible(proto)) {
        Errors.incompatibleTypes($IDENT, proto, fun, null);
        System.exit(1);
      }
      // Makes the call
      code.append(Code3aGenerator.genCall(temp, new ExpAttribute(fun.getReturnType(), new Code3a(), id)));
      expAtt = new ExpAttribute(fun.getReturnType(), code, temp);
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
      Operand3a result = symTab.lookup($IDENT.text);
      if (result == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      if (result.type != Type.INT) {
      	Errors.incompatibleTypes($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      Operand3a id = SymbDistrib.builtinRead;
      System.out.println("Read type: " + id.type);
      code.append(Code3aGenerator.genCall(result, new ExpAttribute(result.type, new Code3a(), id)));
    }

  | ^(ARELEM IDENT e=expression[symTab])
    {
      // Use a temp var for READ and then copy the value to the array element
      VarSymbol temp = SymbDistrib.newTemp();
      code = new Code3a();
      Operand3a result = symTab.lookup($IDENT.text);
      if (result == null) {
        Errors.unknownIdentifier($IDENT, $IDENT.text, "");
        System.exit(1);
      }
      Operand3a id = SymbDistrib.builtinRead;
      System.out.println("Read type: " + id.type);
      code.append(Code3aGenerator.genCall(temp, new ExpAttribute(result.type, new Code3a(), id)));
      code.append(Code3aGenerator.genVartab(result, e, new ExpAttribute(result.type, new Code3a(), temp)));
    }
  ;

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
        // Check if the identifier has already been defined in this scope
        Operand3a id = symTab.lookup($IDENT.text);
        if (id != null && id.getScope() == symTab.getScope()) {
            Errors.redefinedIdentifier($IDENT, $IDENT.text, null);
            System.exit(1);
        }
        symTab.insert($IDENT.text, new VarSymbol(Type.INT, $IDENT.text, symTab.getScope()));
        code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  | ^(ARDECL IDENT INTEGER)
    {
        // Check if the identifier has already been defined in this scope
        Operand3a id = symTab.lookup($IDENT.text);
        if (id != null && id.getScope() == symTab.getScope()) {
            Errors.redefinedIdentifier($IDENT, $IDENT.text, null);
            System.exit(1);
        }
        symTab.insert($IDENT.text, new VarSymbol(new ArrayType(Type.INT, Integer.parseInt($INTEGER.text)),
                                               $IDENT.text, symTab.getScope()));
        code = Code3aGenerator.genVar(symTab.lookup($IDENT.text));
    }
  ;
