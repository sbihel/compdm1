import java.io.FileWriter;
import java.util.LinkedList;
import java.util.List;

/**
 * A list of TAC statements (Inst3a). Basically, 3 address code is a list of
 * Inst3a objects. However, in any compiler, it is necessary to allocate some
 * memory for constants of variable size. The most obvious example are string
 * constants. In VSL it is the only constants which need memory allocation. The
 * other constants are integers which are operands in arithmetic expression and
 * have immediate addresses. Consequently, Code3a has two attributes: a list of
 * 3a instructions and a list of Data3a for storing the string constants.
 * 
 * @author MLB
 **/

public class Code3a {
	// private static boolean no_error = true;
	protected List<Inst3a> the_code;
	protected List<Data3a> the_data;

	/**
	 * Creates an empty list of TAC
	 */
	public Code3a() {
		the_code = new LinkedList<Inst3a>();
		the_data = new LinkedList<Data3a>();
	}

	/**
	 * Creates a list of TAC with only one statement.
	 */
	public Code3a(Inst3a i) {
		the_code = new LinkedList<Inst3a>();
		the_data = new LinkedList<Data3a>();
		the_code.add(i);
	}

	/**
	 * Appends two codes. Lists of instructions are concatenated. The two lists
	 * of string constants used in each code are also concatenated.
	 */
	public void append(Code3a c) {
		if (c != null) {
			the_code.addAll(c.the_code);
			the_data.addAll(c.the_data);
		}
	}

	/**
	 * Add a Data3a for storing a string constant
	 */
	public void appendData(Data3a dat) {
		the_data.add(dat);
	}

	/**
	 * Add a statement at the end of the list of TAC.
	 */
	public void append(Inst3a inst) {
		the_code.add(inst);
	}

	/**
	 * To be used by the (machine) code generator
	 * 
	 * @return List<Inst3a> the 3a code
	 */
	public List<Inst3a> getCode() {
		return the_code;
	}

	public boolean isEmpty() {
		return the_code.isEmpty();
	}

	/**
	 * Print the 3A code.
	 * 
	 */
	public void print() {
		int i;
		for (i = 0; i < the_code.size(); i++)
			((Inst3a) the_code.get(i)).print();
		// print the data
		for (i = 0; i < the_data.size(); i++)
			((Data3a) the_data.get(i)).print();
	}

	/**
	 * Print the 3A code in a file
	 */
	public void print_in_file(FileWriter fo) {
		int i;
		for (i = 0; i < the_code.size(); i++)
			((Inst3a) the_code.get(i)).print_in_file(fo);

	}

	public String toString() {
		StringBuilder sb = new StringBuilder();
		int i;
		for (i = 0; i < the_code.size(); i++)
			sb.append(the_code.get(i) + "\n");
		// print the data
		for (i = 0; i < the_data.size(); i++)
			sb.append(the_data.get(i) + "\n");
		return sb.toString();
	}

}
