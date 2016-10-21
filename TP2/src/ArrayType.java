/**
 * Type for arrays (currently, only integer arrays). Includes the underlying
 * array type and the length of the array (necessary to compute its size in
 * memory).
 * 
 * @author MLB
 * 
 */

class ArrayType extends Type {
	private int length;
	private Type type;

	public ArrayType(Type t, int l) {
		super("ARRAY", 4 * l);
		type = t;
		length = l;
	}

	/**
	 * Returns the dimension of this array (used only for code generation).
	 */
	public int getLength() {
		return length;
	}

	@Override
	public boolean isCompatible(Type t) {
		if (this == t)
			return true;
		if (!(t instanceof ArrayType)) {
			return false;
		}
		ArrayType at = (ArrayType) t;
		return this.name.equals(at.name) && this.type.equals(at.type);
	}

	@Override
	public String toString() {
		return name + "(" + type + ")";
	}

}
