/**
 * Implementation of a generic type object. The type is represented by the type
 * expression: T(t1, ...,tn). An attribute size was added for compiler needs.
 */
public class Type {
	protected int size;
	protected String name;

	/**
	 * Constructor for a simple type name().
	 */
	public Type(String name, int size) {
		this.name = name;
		this.size = size;
	}

	/**
	 * Returns the size in bytes.
	 */
	public int getSize() {
		return size;
	}

	/**
	 * Tests if two types are compatible. For simple types, compatibility is
	 * equality of types. Sub-types (e.g. function types) must override this
	 * function accordingly.
	 */
	public boolean isCompatible(Type t) {
		return this.equals(t);
	}

	/**
	 * Returns a printable representation of the type expression. Must be
	 * overridden by subclasses.
	 */
	public String toString() {
		return name;
	}

	/**
	 * Returns true iff the given parameter is an object with the same type as
	 * this one.
	 * 
	 * @param o
	 *            object to be compared with.
	 */
	public boolean equals(Object o) {
		if (this == o)
			return true;
		if (!(o instanceof Type)) {
			return false;
		}
		Type t = (Type) o;
		return this.name.equals(t.name) && this.size == t.size;
	}

	public int hashCode() {
		return name.hashCode() * 7 + size * 13;
	}

	static final public Type INT = new Type("INT", 4);
	static final public Type I_CONST = new Type("I_CONST", 4);
	static final public Type LABEL = new Type("LABEL", -1);
	static final public Type POINTER = new Type("POINTER", 4);
	static final public Type ERROR = new Type("ERROR", -1);
	static final public Type VOID = new Type("VOID", 0);

}
