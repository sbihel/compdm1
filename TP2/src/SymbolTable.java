import java.util.Map;
import java.util.HashMap;

/**
 * In order to manage scopes, the VSL symbol table is implemented as a stack of
 * tables, each of them being a 'map' data structure (from string identifiers to
 * symbols (Operand3a)).
 * 
 * Every insertion of a pair (key, value) is done in the table which is on top
 * of the stack.
 * 
 * The lookup method proceeds first with the top of stack, and if nothing is
 * found there, it recursively descends the stack. It ends the search at the
 * first occurrence of the key or when it reaches the bottom of the stack.
 * 
 * @author MLB
 * 
 */
public class SymbolTable {

	/**
	 * A SingleScopeTable is one of the possibly several tables representing the
	 * different scopes in a program: one for the function level, then one scope
	 * per nested block in a program.
	 * 
	 * It is a simple wrapper on a Map, with standard lookup/insert functions.
	 */
	static private class SingleScopeTable {

		private Map<String, Operand3a> table;

		private SingleScopeTable parent;

		private SingleScopeTable(SingleScopeTable p) {
			table = new HashMap<String, Operand3a>(16); // Arbitrary initial
														// size for each table
			parent = p;
		}

		private Operand3a lookup(String name) {
			Operand3a to = table.get(name);
			if ((to == null) && (parent != null))
				// try again
				return parent.lookup(name);
			else
				return to;
		}

		private void insert(String name, Operand3a t) {
			table.put(name, t);
		}

		private void print() {
			for (Map.Entry<String, Operand3a> e : table.entrySet()) {
				String name = e.getKey();
				Operand3a op = e.getValue();
				System.out.println(name + "-> " + op);
			}
			if (parent != null)
				parent.print();
		}
	}

	/**
	 * Reference to the current top of the stack.
	 */
	private SingleScopeTable currentTable;

	/**
	 * Current scope level.
	 */
	private int scopeLevel;

	/**
	 * Creates a new symbol table. The current scope is zero.
	 * 
	 */
	public SymbolTable() {
		currentTable = new SingleScopeTable(null);
		scopeLevel = 0;
	}

	/**
	 * Pushes a new table, which becomes the current one. Updates the current
	 * scope accordingly.
	 */
	public void enterScope() {
		SingleScopeTable t = new SingleScopeTable(currentTable);
		currentTable = t;
		scopeLevel++;
	}

	/**
	 * Pops the current table and decrements the current scope.
	 */
	public void leaveScope() {
		currentTable = currentTable.parent;
		scopeLevel--;
	}

	/**
	 * Lookup for a value associated with a key. Returns null if the key is not
	 * found.
	 * 
	 * @param name
	 *            string - the key
	 * @return Value with Operand3a type (which might be necessary to cast)
	 */
	public Operand3a lookup(String name) {
		return currentTable.lookup(name);
	}

	/**
	 * Puts a pair (key, value) in the current table.
	 * 
	 * @param name
	 *            : name (String)
	 * @param t
	 *            : value of Operand3a type
	 */
	public void insert(String name, Operand3a t) {
		currentTable.insert(name, t);
	}

	/**
	 * Returns the current scope.
	 */
	public int getScope() {
		return scopeLevel;
	}

	/**
	 * For debugging; displays the name of the key associated with whatever the
	 * user wants to display by mean of a <b>toString</b> method on the object
	 * associated with the key.
	 */
	public void print() {
		System.out.println("\n ======= Symbol table ==========\n");
		currentTable.print();
		System.out.println("\n ======= End symbol table ==========\n");
	}

}
