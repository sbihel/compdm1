# -----------------------------------------------------------------------------
# CONFIGURATION
# Vérifiez bien les valeurs suivantes avant de procéder.
# -----------------------------------------------------------------------------

ANTLR_JAR=../antlr-3.5.2-complete.jar
ANTLR_RUNT=../antlr-3.5.2-runtime.jar
SRC_DIR=./src


# -----------------------------------------------------------------------------
# SCRIPT
# Cette partie n'a normalement pas besoin d'être modifiée.
# -----------------------------------------------------------------------------

CLASSPATHRUN=$(SRC_DIR):$(ANTLR_JAR):$(ANTLR_RUNT)
CLASSPATH=$(SRC_DIR):$(ANTLR_JAR)
SRCS=$(wildcard $(SRC_DIR)/*.java)
OBJS=$(SRCS:.java=.class)

.PHONY: all clean clean_test run

all: $(SRC_DIR)/VSLTreeParser.java $(SRC_DIR)/VSLParser.java $(SRC_DIR)/VSLLexer.java $(OBJS)

$(SRC_DIR)/%.class: $(SRC_DIR)/%.java
	javac -cp $(CLASSPATH) $(SRCS)

$(SRC_DIR)/VSLTreeParser.java: $(SRC_DIR)/VSLTreeParser.g $(SRC_DIR)/VSLParser.java VSLParser.tokens
	java -cp $(CLASSPATH) org.antlr.Tool $(SRC_DIR)/VSLTreeParser.g

$(SRC_DIR)/VSLParser.java: $(SRC_DIR)/VSLParser.g $(SRC_DIR)/VSLLexer.java VSLLexer.tokens
	java -cp $(CLASSPATH) org.antlr.Tool $(SRC_DIR)/VSLParser.g

%.tokens: $(SRC_DIR)/%.g
	java -cp $(CLASSPATH) org.antlr.Tool $^

$(SRC_DIR)/VSLLexer.java: $(SRC_DIR)/VSLLexer.g
	java -cp $(CLASSPATH) org.antlr.Tool $^

clean:
	rm -f $(SRC_DIR)/*.class $(SRC_DIR)/VSLTreeParser.java $(SRC_DIR)/VSLParser.java $(SRC_DIR)/VSLLexer.java *.tokens tmp.vsl_code

clean_test:
	rm -f tests/testlevel*/*.mips tests/testlevel*/*.mips.o tests/testlevel*/*.mips.s tests/testlevel*/*.vsm.o tests/testlevel*/*.vsm.s tests/testlevel*/*.mips_res tests/testlevel*/*.vsm_res tests/testlevel*/*.comp_res

run: 
	java -cp $(CLASSPATHRUN) VslComp $(SRC_DIR)/test.vsl -debug