/**
 * Constants used for MIPS code generation only.
 */
public interface MIPSCGConstants {

	public int WORD_SIZE = 4; /* 32 bits machine */

	/**
	 * Constants for assembly code generation. Essentially register IDs This is
	 * architecture specific.
	 */

	static String R_INDENT = "       ";

	static int R_ZERO = 0; /* Constant zero */
	static int R_RES = 2; /* Result reg and last reserved */

	static int R_ARG1 = 4;
	static int R_ARG2 = 5;
	static int R_ARG3 = 6;
	static int R_ARG4 = 7;
	static int R_GEN = 8; /* First general purpose register */
	static int R_MAX = 24; /* 24 regs */

	// $25 is reserved for dynamic link

	static int R_GP = 28;
	static int R_STACK = 29; /* Stack pointer */
	static int R_RET = 31; /* Return address */

	static boolean R_MODIFIED = true; /* Entries for descriptors */
	static boolean R_UNMODIFIED = false;
}
