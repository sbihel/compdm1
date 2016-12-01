/**
 * Type checking operations (NOTE: this class must be implemented by the
 * student; the methods indicated here can be seen as suggestions; note that
 * some minor checks can still be performed directly in VSLTreeParser.g).
 * 
 */
public class TypeCheck {

	public static void checkReturnType(org.antlr.runtime.tree.CommonTree token, Type ty) {
		if (ty != Type.INT) {
        	Errors.incompatibleTypes(token, Type.INT, ty, null);
        	System.exit(1);
      	}
	}

	public static VarSymbol checkAndDeclArray(org.antlr.runtime.tree.CommonTree token, java.lang.String name, int size, SymbolTable symTab) {
		Operand3a id = symTab.lookup(name);
		if (id != null && id.getScope() == symTab.getScope()) {
            Errors.redefinedIdentifier(token, name, null);
            System.exit(1);
        }
        VarSymbol vid = new VarSymbol(new ArrayType(Type.INT, size), name, symTab.getScope());
        symTab.insert(name,vid);
        return vid;
	}

	public static VarSymbol checkAndDeclIdent(org.antlr.runtime.tree.CommonTree token, java.lang.String name, Type type, SymbolTable symTab) {
		Operand3a id = symTab.lookup(name);
        if (id != null && id.getScope() == symTab.getScope()) {
            Errors.redefinedIdentifier(token, name, null);
            System.exit(1);
        }
        VarSymbol vid = new VarSymbol(type, name, symTab.getScope());
        symTab.insert(name, vid);
        return vid;
	}

	public static VarSymbol checkAndDeclParm(org.antlr.runtime.tree.CommonTree token, java.lang.String name, Type type, SymbolTable symTab) {
		VarSymbol parameter = new VarSymbol(type, name, symTab.getScope());
    	parameter.setParam();
    	symTab.insert(name, parameter);
    	return parameter;
	}

	public static Operand3a checkArrayElem(org.antlr.runtime.tree.CommonTree token, java.lang.String name, Type indice, SymbolTable symTab) {
		if(!indice.isCompatible(Type.INT)) {
			Errors.incompatibleTypes(token, Type.INT, indice, null);
            System.exit(1);
		}
		Operand3a id = symTab.lookup(name);
		if (id == null) {
          Errors.unknownIdentifier(token, name, null);
          System.exit(1);
      	}
      	ArrayType arrType = new ArrayType(Type.INT, 0);
      	if(!id.type.isCompatible(arrType)) {
			Errors.incompatibleTypes(token, arrType, id.type, null);
            System.exit(1);
		}
      	return id;
	}

	public static Operand3a checkIdent(org.antlr.runtime.tree.CommonTree token, java.lang.String name, SymbolTable symTab) {
		Operand3a id = symTab.lookup(name);
		if (id == null) {
          Errors.unknownIdentifier(token, name, null);
          System.exit(1);
      	}
      	return id;
	}

	public static void checkAssign(org.antlr.runtime.tree.CommonTree token, Type lType, Type rType) {
      if (!lType.isCompatible(rType)) {
          Errors.incompatibleTypes(token, lType, rType, null);
          System.exit(1);
      }
	}


	// Type checking for a binary operation - in VSL+: integer operations only!
	public static Type checkBinOp(Type t1, Type t2) {
		if (t1 == Type.INT && t2 == Type.INT)
			return Type.INT;
		else {
			return Type.ERROR;
		}
	}

	// Checks if the call is correct (valid function name and compatible argument types).
	public static  FunctionSymbol checkFuncCall(org.antlr.runtime.tree.CommonTree token, java.lang.String name, FunctionType callType, SymbolTable symTab) {
		Operand3a id = symTab.lookup(name);
      	if (id == null) {
          Errors.unknownIdentifier(token, name, null);
          System.exit(1);
        }
		if (!(id.type instanceof FunctionType)) {
      	  Errors.incompatibleTypes(token, id.type, callType, null);
          System.exit(1);
        }
        FunctionType proto = (FunctionType) id.type;
		if (!callType.isCompatible(proto)) {
          Errors.incompatibleTypes(token, proto, callType, null);
          System.exit(1);
      	}
      	return (FunctionSymbol) id;
	}

	public static void checkFuncDecl(org.antlr.runtime.tree.CommonTree token, java.lang.String name, FunctionType ft, SymbolTable symTab) {
		Operand3a fid = symTab.lookup(name);
		if(fid != null) {
          // Check if the identifier is already used
          if(!(fid.type instanceof FunctionType)) {
            Errors.redefinedIdentifier(token, name, null);
            System.exit(1);
          } else {
            FunctionType proto = (FunctionType) fid.type;
            // Check if the previous definition is a prototype
            if(!proto.prototype) {
                Errors.redefinedIdentifier(token, name, null);
                System.exit(1);
            }
            // Check if the function matches the prototype
            if (!ft.isCompatible(proto)) {
                Errors.incompatibleTypes(token, proto, ft, null);
                System.exit(1);
            } 
          }
        }
	}

	public static void checkProtoDecl(org.antlr.runtime.tree.CommonTree token, java.lang.String name, FunctionType ft, SymbolTable symTab) {
		Operand3a fid = symTab.lookup(name);
		if(fid != null) {
		  // Prototype ft is already defined
		  Errors.redefinedIdentifier(token, name, null);
          System.exit(1);
        }
	}

	public static void reserveFunctionName(org.antlr.runtime.tree.CommonTree token, java.lang.String name, FunctionType ft, SymbolTable symTab) {
		symTab.insert(name, new FunctionSymbol(new LabelSymbol(name), ft));
	}
}
