import java.util.List;
import java.util.LinkedList;

/**
 * The type of a function is composed of a return type plus a list of types for
 * its arguments (empty if none). It also has a field "prototype" indicating
 * whether this represents a prototype declaration (without body) or a function
 * definition (with body).
 * 
 * @author MLB
 * 
 */
public class FunctionType extends Type {
	/**
	 * True if this is a prototype declaration, false if this is a function
	 * definition.
	 */
	public boolean prototype;
	private Type returnType;
	private List<Type> arguments = new LinkedList<Type>();

	/**
	 * Creates a new function type with the given return type and whether it is
	 * a prototype declaration or a function definition.
	 * 
	 * @param returnType
	 *            Return type of the function
	 * @param prototype
	 *            True iff this is a prototype declaration (instead of a
	 *            function definition)
	 */
	public FunctionType(Type returnType, boolean prototype) {
		super("FUNC", -1);
		this.returnType = returnType;
		this.prototype = prototype;
	}

	/**
	 * Creates a new function type indifferent of prototype/function status
	 * (used to check function calls).
	 * 
	 * @param returnType
	 *            Return type of the function
	 */
	public FunctionType(Type returnType) {
		super("FUNC", -1);
		this.returnType = returnType;
		this.prototype = true; // meaningless, arbitrary choice
	}

	/**
	 * Returns the return type of this function (it can be VOID).
	 * 
	 * @return the return type of this function (it can be VOID).
	 */
	public Type getReturnType() {
		return returnType;
	}

	/**
	 * Returns the list of argument types of this function (without the return
	 * type).
	 * 
	 * @return the list of argument types of this function.
	 */
	public List<Type> getArguments() {
		// Defensive copy to avoid user from mutating the list
		return new LinkedList<Type>(arguments);
	}

	/**
	 * Extend the arity of this function type, from f(t1, ..., tn) to f(t1, ...,
	 * tn, t).
	 * 
	 * Use this when iteratively constructing the entire type of a function
	 * call.
	 * 
	 * @param t
	 *            the new argument type to be added.
	 */
	public void extend(Type t) {
		arguments.add(t);
	}

	@Override
	public boolean isCompatible(Type t) {
		if (!(t instanceof FunctionType)) {
			return false;
		}
		FunctionType ft = (FunctionType) t;
		return this.returnType.equals(ft.returnType)
				&& this.arguments.equals(ft.arguments);
	}

	@Override
	public String toString() {
		return name + arguments + " : " + returnType;
	}

}
