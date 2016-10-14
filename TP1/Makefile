main: Test.class

ExprLexer.java ExprParser.java: Expr.g
	java -jar "../antlr-3.5.2-complete.jar" Expr.g

Eval.java: Eval.g ExprLexer.java ExprParser.java
	java -jar "../antlr-3.5.2-complete.jar" Eval.g

Test.class: Test.java ExprLexer.java ExprParser.java Eval.java
	javac $^ -cp ".:../antlr-3.5.2-complete.jar:../antlr-3.5.2-runtime.jar"

run: Test.class
	java -cp ".:../antlr-3.5.2-complete.jar:../antlr-3.5.2-runtime.jar" Test
