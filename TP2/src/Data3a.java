/**
 * Class for implementing initialized constants. The only constants in VSL are
 * character strings. A label must be associated to its textual content and is
 * used as the name of the text in three-address code. So the class is simple:
 * it contains the label and its text.
 * 
 * @author MLB
 * 
 */

public class Data3a {
	private LabelSymbol label;
	private String text;

	public Data3a(String t) {
		label = SymbDistrib.newLabel();
		text = t;
	}

	public LabelSymbol getLabel() {
		return label;
	}

	public String getText() {
		return text;
	}

	public String toString() {
		return label.toString() + ":" + text;
	}

	public void print() {
		System.out.println(this.toString());
	}

}
