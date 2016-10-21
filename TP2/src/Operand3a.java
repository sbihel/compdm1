/**
 * Abstract class for implementing TAC operands (which are also the "symbols"
 * stored in the SymbolTable). This class has the minimal set of attributes for
 * (assembler) code generation. The abstract methods defined in the interface
 * are also necessary for assembler code generation. They might be useful for
 * type checking and TAC generation.
 * <p>
 * The offset attribute is set and used by the machine code generator. It
 * represents the address of the operand relative to the top of the function
 * frame in the execution stack. You don't need it in the frontend.
 * 
 * @author MLB
 * 
 */
abstract public class Operand3a implements CGInterface {

	public final Type type;

	private int offset;

	/**
	 * set the address of the operand
	 * 
	 * @param off
	 *            int
	 */
	public void setOffset(int off) {
		offset = off;
	}

	/**
	 * returns the address of the operand.
	 * 
	 * @return the address
	 */
	public int getOffset() {
		return offset;
	}

	public Operand3a(Type t) {
		type = t;
		offset = 0;
	}

	public String toString() {
		if (type != null)
			return type.toString();
		else
			return "";
	}

	// Must be overridden by subclasses
	abstract public String getName3a();

	public int getScope() {
		return -1;
	}

	public int getSize() {
		return type.getSize();
	}

	public boolean isArray() {
		return type instanceof ArrayType;
	}

	public boolean isConstInteger() {
		return (type == Type.I_CONST);
	}

	public boolean isLabel() {
		return (type == Type.LABEL);
	}

	public boolean isPointer() {
		return (type == Type.POINTER);
	}

	public boolean isVarInteger() {
		return (type == Type.INT);
	}

	public boolean isParam() {
		return false;
	}

}
