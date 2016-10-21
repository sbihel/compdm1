import org.antlr.runtime.tree.CommonTree;

/**
 * Predefined messages for most semantic/typing errors. Helps providing
 * automatic error evaluation. Each method here emits an error corresponding to
 * the method name. Its parameters are useful for human readability.
 * 
 * Error codes are used by the test scripts and are chosen arbitrarily.
 * 
 * @author aoliveir
 * 
 */
public class Errors {

	/**
	 * Auxiliary method to add extra information to the error message.
	 * 
	 * @param extra
	 *            extra information, or null if nothing should be added.
	 * @return an empty String if null, "(" + extra + )" otherwise.
	 */
	static private String addExtra(String extra) {
		if (extra == null)
			return "";
		else
			return "(" + extra + ")";
	}

	/**
	 * Error message for an unknown identifier (i.e., use before declaration).
	 * 
	 * @param token
	 *            ANTLR token (for line/column numbering). If null, no
	 *            meaningful line/column information will be given.
	 * @param name
	 *            name of the undeclared identifier.
	 * @param extra
	 *            additional information to the error message, or null if none.
	 */
	static public void unknownIdentifier(CommonTree token, String name,
			String extra) {
		Util.printError(token, "E#UNK_ID: unknown identifier: " + name
				+ addExtra(extra));
	}

	/**
	 * Error message for a redefined identifier (e.g., two local variable
	 * declarations with same name).
	 * 
	 * @param token
	 *            ANTLR token (for line/column numbering). If null, no
	 *            meaningful line/column information will be given.
	 * @param name
	 *            name of the redefined identifier.
	 * @param extra
	 *            additional information to the error message, or null if none.
	 */
	static public void redefinedIdentifier(CommonTree token, String name,
			String extra) {
		Util.printError(token, "E#DEF_ID: redefined identifier: " + name
				+ addExtra(extra));
	}

	/**
	 * Error message for incompatible types (i.e., assignment of INT value to
	 * POINTER variable). Note that this uses a very broad definition of type
	 * incompatibility, i.e., several kinds of invalid operations can be mapped
	 * to a type incompatibility issue.
	 * 
	 * @param token
	 *            ANTLR token (for line/column numbering). If null, no
	 *            meaningful line/column information will be given.
	 * @param expectedType
	 *            expected type (e.g., INT for a return value). Uses the
	 *            toString() method of the object.
	 * @param actualType
	 *            actual obtained type (which is incompatible with the previous
	 *            one). Uses the toString() method of the object.
	 * @param extra
	 *            additional information to the error message, or null if none.
	 */
	static public void incompatibleTypes(CommonTree token, Object expectedType,
			Object actualType, String extra) {
		Util.printError(token, "E#INC_TYP: incompatible types: expected '"
				+ expectedType + "', got '" + actualType + "'"
				+ addExtra(extra));
	}

	/**
	 * Miscellaneous error message (for errors which do not fit any other
	 * method). Note: all "standard" errors should fit in one of the previous
	 * categories.
	 * 
	 * @param token
	 *            ANTLR token (for line/column numbering). If null, no
	 *            meaningful line/column information will be given.
	 * @param msg
	 *            the entire error message describing the error.
	 */
	static public void miscError(CommonTree token, Object msg) {
		Util.printError(token, "E#MISC: " + msg);
	}
}
