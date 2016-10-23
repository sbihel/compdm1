/**
 * This class implements all the methods for 3a code generation (NOTE: this
 * class must be coded by the student; the methods indicated here can be seen as
 * a suggestion, but are not actually necessary).
 *
 * @author MLB
 *
 */
public class Code3aGenerator {

	// Constructor not needed
	private Code3aGenerator() {
	}

	/**
	 * Generates the 3a statement: VAR a
	 */
	public static Code3a genVar(Operand3a a) {
		Inst3a i = new Inst3a(Inst3a.TAC.VAR, a, null, null);
		return new Code3a(i);
	}

	/**
	 * Generates the 3a statement: ARG a
	 */
	public static Code3a genArg(Operand3a a) {
		Inst3a i = new Inst3a(Inst3a.TAC.ARG, a, null, null);
		return new Code3a(i);
	}

	/**
	 * Generates the 3a statement: COPY a = b
	 */
	public static Code3a genCopy(Operand3a a, ExpAttribute b) {
		Code3a cod = b.code;
		cod.append(new Inst3a(Inst3a.TAC.COPY, a, b.place, null));
		return cod;
	}

	/**
	 * Generates the 3a statement: IFZ ifz a goto b
	 */
	public static Code3a genIfz(ExpAttribute a, LabelSymbol b) {
		return new Code3a(new Inst3a(Inst3a.TAC.IFZ, a.place, b, null));
	}

	/**
	 * Generates the 3a statement: IFNZ ifnz a goto b
	 */
	public static Code3a genIfnz(ExpAttribute a, LabelSymbol b) {
		return new Code3a(new Inst3a(Inst3a.TAC.IFNZ, a.place, b, null));
	}

	/**
	 * Generates the 3a statement: GOTO goto a
	 */
	public static Code3a genGoto(LabelSymbol a) {
		return new Code3a(new Inst3a(Inst3a.TAC.GOTO, a, null, null));
	}

	/**
	 * Generates the 3a statement: LABEL label a
	 */
	public static Code3a genLabel(LabelSymbol a) {
		return new Code3a(new Inst3a(Inst3a.TAC.LABEL, a, null, null));
	}

	/**
	 * Generate code for a binary operation
	 *
	 * @param op must be a code op: Inst3a.TAC.XXX
	 */
	public static Code3a genBinOp(Inst3a.TAC op, Operand3a temp, ExpAttribute exp1,
			ExpAttribute exp2) {
		Code3a cod = exp1.code;
		cod.append(exp2.code);
		cod.append(genVar(temp));
		cod.append(new Inst3a(op, temp, exp1.place, exp2.place));
		return cod;
	}

} // Code3aGenerator ***
