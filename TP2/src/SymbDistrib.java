/**
 * A simple new symbol generator for temporaries and labels. It also manages
 * symbols for built-in functions (read/print).
 */
public class SymbDistrib {
	private static int noTemp = 0;
	private static int noLabel = 10;

	public static VarSymbol newTemp() {
		String name = "T_" + noTemp;
		noTemp++;
		return new VarSymbol(name);
	}

	public static LabelSymbol newLabel() {
		String name = "L" + noLabel;
		noLabel++;
		return new LabelSymbol(name);
	}

	/**
	 * The label of the built-in function printN (print integer).
	 */
	public static final LabelSymbol builtinPrintN = new LabelSymbol("L2");

	/**
	 * The label of the built-in function printS (print string).
	 */
	public static final LabelSymbol builtinPrintS = new LabelSymbol("L4");

	/**
	 * The label of the built-in function read (to read integers).
	 */
	public static final LabelSymbol builtinRead = new LabelSymbol("L8");
}
