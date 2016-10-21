import org.antlr.runtime.tree.CommonTree;
import java.util.logging.*;

/**
 * Utility methods for generating error and warning messages, as well as
 * debugging settings. This class contains a status field which is set in the
 * presence of errors and warnings. It also contains a field indicating the
 * current debugging level.
 * 
 * All messages here are emitted using the standard error (stderr) or a logger
 * (if the -debug option is used).
 */
public class Util {

	static public String vslFilename = "<undefined>";
	static public int status = 0; // 0 - no errors nor warnings; 1 - errors
									// detected; 2 - warnings emitted; 3 -
									// errors and warnings

	static private void printMsg(int newStatus, int line, int col, String type,
			String msg) {
		status |= newStatus;
		System.err.println(vslFilename + ":" + line + ": " + type + ": " + msg);
	}

	static private void printMsg(int newStatus, String type, String msg) {
		status |= newStatus;
		System.err.println(vslFilename + ": " + type + ": " + msg);
	}

	/**
	 * Auxiliary method to retrieve the line number of a token, without throwing
	 * exceptions. If the token is null, returns -1.
	 */
	static private int getTokenLine(CommonTree t) {
		if (t == null)
			return -1;
		else
			return t.getLine();
	}

	/**
	 * Auxiliary method to retrieve the column of a token, without throwing
	 * exceptions. If the token is null, returns -1.
	 */
	static private int getTokenCharPositionInLine(CommonTree t) {
		if (t == null)
			return -1;
		else
			return t.getCharPositionInLine();
	}

	static public void printError(String msg) {
		printMsg(1, "error", msg);
	}

	static public void printError(int line, int col, String msg) {
		printMsg(1, line, col, "error", msg);
	}

	static public void printError(CommonTree token, String msg) {
		printMsg(1, getTokenLine(token), getTokenCharPositionInLine(token),
				"error", msg);
	}

	static public void printWarning(String msg) {
		printMsg(2, "warning", msg);
	}

	static public void printWarning(int line, int col, String msg) {
		printMsg(2, line, col, "warning", msg);
	}

	static public void printWarning(CommonTree token, String msg) {
		printMsg(2, getTokenLine(token), getTokenCharPositionInLine(token),
				"warning", msg);
	}

	static public Logger log = Logger.getLogger("comp");

}
