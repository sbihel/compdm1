/**
 * Symbol for a var Ident or an Array ident. We need name + type + scope in
 * general - type is already an attribute of Operand3a. Notice the param
 * attribute, used to mark an ident as a function argument. The interface
 * methods isParam is necessary for MIPS code generation.
 * 
 * @author MLB
 * 
 */
public class VarSymbol extends Operand3a {
	public String name;
	public int scope;
	public boolean param;

	/**
	 * Generic constructor
	 * 
	 * @param t
	 *            type (INT or ARRAY)
	 * @param n
	 *            string: name of the symbol
	 * @param sc
	 *            int: declaration scope level
	 */
	public VarSymbol(Type t, String n, int sc) {
		super(t);
		name = n;
		scope = sc;
	}

	/**
	 * Constructor for temporary integer variables (scope is meaningless).
	 * 
	 * @param n
	 *            string: name of the id
	 */
	public VarSymbol(String n) {
		super(Type.INT);
		name = n;
		scope = -1;
	}

	/**
	 * for code 3a printing
	 */
	public String getName3a() {
		return name;
	}

	/**
	 * Self explained
	 */
	public int getScope() {
		return scope;
	}

	/**
	 * Put param attribute to true
	 */
	public void setParam() {
		param = true;
	}

	/**
	 * MIPS code generator interface only
	 */
	public boolean isParam() {
		return param;
	}
}
