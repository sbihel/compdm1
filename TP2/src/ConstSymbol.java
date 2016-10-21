/**
 * Symbol for an integer constant. It could be a string since we never use the
 * value in integer operations.
 * 
 * @author MLB
 * 
 */
public class ConstSymbol extends Operand3a {
	public int value;

	public ConstSymbol(int v) {
		super(Type.I_CONST);
		value = v;
	}

	/**
	 * For code 3a printing
	 */
	public String getName3a() {
		return String.valueOf(value);
	}
}
