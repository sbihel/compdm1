import org.antlr.runtime.*;
import org.antlr.runtime.tree.*;
 
public class Test {
    public static void main(String[] args) throws Exception {
        ANTLRFileStream input = new ANTLRFileStream("tests/test1.ttl");
        ExprLexer lexer = new ExprLexer(input);
        CommonTokenStream tokens = new CommonTokenStream(lexer);
        ExprParser parser = new ExprParser(tokens);
        ExprParser.prog_return r = parser.prog();
 
        // walk resulting tree
        CommonTree t = (CommonTree)r.getTree();
        CommonTreeNodeStream nodes = new CommonTreeNodeStream(t);
        Eval walker = new Eval(nodes);
        System.out.printf(walker.prog());
    }
}
