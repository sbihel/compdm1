/**
 * Wrapper class for a triple (type, code, place) associated to an expression in
 * the parser.
 * 
 * @author MLB
 * 
 */
class ExpAttribute {

	public Code3a code;
	public Type type;
	public Operand3a place;

	/**
	 * Constructor of ExpAttribute
	 * 
	 * @param ty
	 *            Type: the type associated with the expression
	 * @param cod
	 *            Code3a: the code implementing the expression
	 * @param pl
	 *            Operand3a: a representation of memory place for expression
	 *            value
	 */
	public ExpAttribute(Type ty, Code3a cod, Operand3a pl) {
		code = cod;
		type = ty;
		place = pl;
	}

}
