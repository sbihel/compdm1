import java.util.List;
import java.io.*;
import java.util.HashMap;
import java.util.Map;

/**
 * This is the MIPS code generator. You only need to know the <b>genCode</b>
 * method. Read it if you are curious but it is pretty hairy!!
 */
public class MIPSCodeGenerator implements MIPSCGConstants {

	static boolean nachos = true;

	static boolean debugCG = false;

	private MIPSRegAlloc regalloc;

	private int topOfStack;

	private int nextArgMIPS;
	private int nextArgCallMIPS;

	// /-----------------------
	// / add for function
	// /-----------------------

	private boolean beginFunction = true;
	private String currentFunctionLabel = "";

	// /-----------------------

	/**
	 * This is the output stream where the generated assembly code is directed
	 * to.
	 */
	private PrintStream out;

	public MIPSCodeGenerator(PrintStream out) {
		regalloc = new MIPSRegAlloc(out);
		topOfStack = 0;
		nextArgMIPS = 0;
		nextArgCallMIPS = 0;
		this.out = out;
	}

	// size of the stack frame of each function without arguments
	Map<String, Integer> StackInformation = new HashMap<String, Integer>();
	// number of argument of each callee
	Map<String, Integer> CalleeInformation = new HashMap<String, Integer>();
	// max number of arguments gives to callees by each caller
	Map<String, Integer> CallerInformation = new HashMap<String, Integer>();

	private int functionStackSize = 0;
	private boolean beginCurrentFunction = true;
	private String functionName = "";
	private int nbMaxArgFunctionCaller = 0;
	private int nbArgFunctionCallee = 0;

	private void firstAnalysis(Inst3a inst) throws IOException {
		switch (inst.getOp()) {
		// stackAnalysis
		case VAR:
			if (!inst.getA().isParam()) {
				functionStackSize += inst.getA().getSize();
			}
			break;

		case LABEL:
			if (beginCurrentFunction) {
				functionName = inst.getA().getName3a();
			}
			break;

		case BEGINFUNC:
			functionStackSize = 0;
			beginCurrentFunction = false;

			nbMaxArgFunctionCaller = 0;
			nbArgFunctionCallee = 0;
			break;

		case ENDFUNC:
			beginCurrentFunction = true;
			StackInformation.put(functionName, functionStackSize);
			CallerInformation.put(functionName, nbMaxArgFunctionCaller);
			break;

		case ARG:
			nbArgFunctionCallee++;
			break;

		case CALL:
			if (CalleeInformation.get(inst.getB().getName3a()) != null
					&& CalleeInformation.get(inst.getB().getName3a()) != nbArgFunctionCallee) {
				System.out.println("function " + inst.getB().getName3a()
						+ ": different number of argument ");
				System.exit(0);
			}
			CalleeInformation.put(inst.getB().getName3a(), nbArgFunctionCallee);
			if (nbArgFunctionCallee > nbMaxArgFunctionCaller) {
				nbMaxArgFunctionCaller = nbArgFunctionCallee;
			}
			nbArgFunctionCallee = 0;

			break;
		default:
			// Nothing to do here
		}
	}

	// ////////////////////////////////////////////////////////////

	/**
	 * This method generates code for a whole three address code fragment. The
	 * resulting assembly code is emitted on the data output stream.
	 * 
	 * @param c
	 *            : Code 3a to be translated
	 */
	public void genCode(Code3a c) throws IOException {
		List<Inst3a> cc = c.getCode();

		for (Inst3a inst : cc) {
			firstAnalysis(inst);
		}
		if (debugCG) {
			System.out.println("Stack information:");
			System.out.println(StackInformation.toString());
			System.out.println("Caller information:");
			System.out.println(CallerInformation.toString());
			System.out.println("Callee information:");
			System.out.println(CalleeInformation.toString());
		}
		out.println(".rdata");
		out.println(".align 2");
		out.println("$LC0:");
		out.println(R_INDENT + ".ascii\t\"%d\\000\"");
		cg_constMIPS(c.the_data);

		out.println(".text");

		for (Inst3a inst : cc) {
			out.println("#" + inst.toString());
			this.genCodeMIPS(inst);
		}
	}

	/**
	 * Adds a stub for the main function, surrounding the given code. In other
	 * words, acts as if the given code had been written inside of the main
	 * function. To be used until functions are implemented in the VSL+
	 * compiler.
	 * 
	 * @param c
	 *            code to be inserted as the body of the main function.
	 * @return a new code with the surrounding instructions to encapsulate it in
	 *         the main function.
	 */
	public Code3a addStubMain(Code3a c) {
		Code3a code = new Code3a();
		FunctionSymbol mainStub = new FunctionSymbol(new LabelSymbol("main"),
				new FunctionType(Type.INT));
		code.append(new Inst3a(Inst3a.TAC.LABEL, mainStub.label, null, null));
		code.append(new Inst3a(Inst3a.TAC.BEGINFUNC, null, null, null));
		code.append(c);
		code.append(new Inst3a(Inst3a.TAC.ENDFUNC, null, null, null));
		return code;
	}

	private int nbMaxarg = 0;// max number of argument of callee
	private int sizeLocal = 0; // number of local + temporaries
	private int stackSize = 0;

	/**
	 * This method generates code for a simple instruction. The resulting
	 * assembly code is emitted on the data output stream.
	 * 
	 * @param inst
	 */
	private void genCodeMIPS(Inst3a inst) throws IOException {

		switch (inst.getOp()) {
		case ADD:
			genCodeMIPSBinaryOp("add", inst.getA(), inst.getB(), inst.getC());
			break;
		case SUB:
			genCodeMIPSBinaryOp("sub", inst.getA(), inst.getB(), inst.getC());
			break;

		case MUL:
			genCodeMIPSBinaryOp("mult", inst.getA(), inst.getB(), inst.getC());
			break;
		case DIV:
			genCodeMIPSBinaryOp("div", inst.getA(), inst.getB(), inst.getC());
			break;

		case NEG:
			cg_negMIPS(inst.getA(), inst.getB());
			break;

		case COPY:
			cg_copyMIPS(inst.getA(), inst.getB());
			break;

		case GOTO:
			cg_condMIPS("j", null, inst.getA());
			break;

		case IFZ:
			cg_condMIPS("beq", inst.getA(), inst.getB());
			break;

		case IFNZ:
			cg_condMIPS("bne", inst.getA(), inst.getB());
			break;

		case ARG:
			/**
			 * Generate for an ARG instruction. If the arg. is a pointer or an
			 * integer We load the argument into a register, and then write it
			 * onto the parameter area of the stack frame. If it is a local
			 * array, we compute its address and write it into the frame. We
			 * keep track of which arg this is in the global variable
			 * "nextArgCallMIPS". We assume that ARG instructions are always
			 * followed by other ARG instructions or CALL instructions.
			 */

			int r,
			offset;
			if (inst.getA().isArray()) { /* local array */
				r = regalloc.getSome(0);
				offset = inst.getA().getOffset();
				out.println("\t add   $" + r + ",$" + R_STACK + "," + offset); // compute
																				// array
			} else {
				r = regalloc.getErasable(inst.getA());
			}

			// put the value on the callee parameter area of the stack
			out.println("\t sw   $" + r + "," + nextArgCallMIPS + "($"
					+ R_STACK + ")");

			// keep it in register also (for the first 4 arguments)
			switch (nextArgCallMIPS) {
			case 0:
				regalloc.spillOne(R_ARG1);
				regalloc.clearDescriptor(R_ARG1);
				out.println("\tmove   $" + R_ARG1 + ",$" + r);
				break;
			case 4:
				regalloc.spillOne(R_ARG2);
				regalloc.clearDescriptor(R_ARG2);
				out.println("\tmove   $" + R_ARG2 + ",$" + r);
				break;
			case 8:
				regalloc.spillOne(R_ARG3);
				regalloc.clearDescriptor(R_ARG3);
				out.println("\tmove   $" + R_ARG3 + ",$" + r);
				break;
			case 12:
				regalloc.spillOne(R_ARG4);
				regalloc.clearDescriptor(R_ARG4);
				out.println("\tmove   $" + R_ARG4 + ",$" + r);
				break;
			}

			nextArgCallMIPS += 4;
			break;

		case CALL:

			nextArgCallMIPS = 0;
			regalloc.flushAll();
			String slabel = inst.getB().getName3a();
			Operand3a res = inst.getA();
			if (slabel.equals("L4")) {// print string

				if (nachos) {
					slabel = "n_printf";
				} else {
					slabel = "printf";
				}

			} else if (slabel.equals("L2")) {// print int
				out.println(R_INDENT + "move $" + R_ARG2 + ",$" + R_ARG1);
				out.println(R_INDENT + "lui   $" + R_ARG1 + ",%hi($LC0)");
				out.println(R_INDENT + "addiu   $" + R_ARG1 + ",$" + R_ARG1
						+ ",%lo($LC0)");
				if (nachos) {
					slabel = "n_printf";
				} else {
					slabel = "printf";
				}
			} else if (slabel.equals("L8")) {// scanf int

				if (res.isVarInteger()) {
					out.println(R_INDENT + "addiu   $" + R_ARG2 + ",$"
							+ R_STACK + "," + res.getOffset());
				} else {
					System.out.println("error: with scanf");
				}

				out.println(R_INDENT + "lui   $" + R_ARG1 + ",%hi($LC0)");
				out.println(R_INDENT + "addiu   $" + R_ARG1 + ",$" + R_ARG1
						+ ",%lo($LC0)");

				slabel = "n_read_int";
				if (nachos) {
					slabel = "n_read_int";
				} else {
					slabel = "scanf";
				}

			}

			if (nachos) {
				out.println("\t jal   " + slabel);
				out.println("\t nop");
			} else {
				out.println("\t lw  $25,%call16(" + slabel + ")($28)");
				out.println("\t nop");
				out.println("\t jalr $25");
				out.println("\t nop");
			}

			if (res != null) { /* Do a result if there is one */
				regalloc.setDescriptor(R_RES, res, R_MODIFIED);

				if (slabel.equals("scanf")) {
					out.println(R_INDENT + "lw   $" + R_RES + ","
							+ res.getOffset() + "($" + R_STACK + ")");
				}

				// nachos
				else if (slabel.equals("n_read_int")) {
					out.println(R_INDENT + "sw   $" + R_RES + ","
							+ res.getOffset() + "($" + R_STACK + ")");
				}
			}

			break;

		case RETURN:
			// put return value in register R_RES
			if (inst.getA() != null) {
				regalloc.spillOne(R_RES);
				regalloc.loadRegisterMIPS(R_RES, inst.getA());
			}

			// /------------------------
			// this part is needed for multiple return statement in a function

			if (currentFunctionLabel.equals("main")) {// restore s0-s1 saved by
														// called function
														// (number 16-23)
				for (int i = 0; i < 8; i++) {
					out.println("\t lw	$" + (16 + i) + ","
							+ (nbMaxarg * 4 + (4 + i * 4)) + "($" + R_STACK
							+ ")");
				}
			}

			// get @ret and stack modification
			out.println("\t lw	$" + R_RET + "," + nbMaxarg * 4 + "($" + R_STACK
					+ ")");
			out.println("\t addiu	$sp,$sp," + stackSize);

			this.out.println("\t jr  $" + R_RET);
			this.out.println("\t nop");
			// /------------------------

			break;

		case LABEL:

			/*
			 * We generate an appropriate label. Note that we must flush the
			 * register descriptor, since control may arrive at this label from
			 * other points in the code.
			 */

			if (beginFunction) {
				regalloc.clearAll();
				currentFunctionLabel = inst.getA().getName3a();
				beginFunction = false;
			} else {
				regalloc.flushAll();
				this.out.println(inst.getA().getName3a() + ":");
			}
			break;

		case VAR:

			if (currentFunctionLabel.equals("main")) {
				// TODO special case of main if param
			}

			/*
			 * Allocate 4*n bytes for this variable to hold an integer (n=1) or
			 * an integer array (n = size) on the current top of stack
			 */
			if (inst.getA().isParam()) {
				inst.getA().setOffset(nextArgMIPS + stackSize);
				if (debugCG) {
					System.out.println("\\ (param)" + inst.getA().getName3a()
							+ "  @ = " + (nextArgMIPS + stackSize));
				}
				nextArgMIPS += 4;
			} else {// local or temporary

				topOfStack = cg_varMIPS(inst.getA(), topOfStack);

			}
			break;

		case BEGINFUNC:

			nextArgMIPS = 0;
			nextArgCallMIPS = 0;
			regalloc.flushAll();

			out.println("\t.align	2");
			out.println("\t.globl " + currentFunctionLabel);
			out.println("\t.ent " + currentFunctionLabel);
			out.println(currentFunctionLabel + ":");

			if (!nachos) {
				out.println(".cpload $25");
				out.println(".cprestore  " + (nbMaxarg * 4 + 4));// nbMaxarg*4 +
																	// 4 == area
																	// to save
																	// $gp into
																	// the stack
			}

			// stack information
			nbMaxarg = CallerInformation.get(currentFunctionLabel);// max number
																	// of
																	// argument
																	// of callee

			// Reservation of the arg build area (for compatibility with nachos
			// and printf,scanf)
			if (nbMaxarg < 4) {
				nbMaxarg = 4;
			}

			sizeLocal = StackInformation.get(currentFunctionLabel); // number of
																	// local +
																	// temporaries
			stackSize = nbMaxarg * 4 + sizeLocal + 4 + 4; // +4 for the $R_RET
															// save and +4 for
															// gp register

			if (currentFunctionLabel.equals("main")) {
				stackSize += 4 * 8;// s0-s1 saved by called function (number
									// 16-23)
			}

			out.println("\t addiu	$sp,$sp,-" + stackSize);
			out.println("\t sw	$" + R_RET + "," + nbMaxarg * 4 + "($" + R_STACK
					+ ")");

			topOfStack = nbMaxarg * 4 + 4 + 4; // +4 for stack_register and +4
												// for gp register

			if (currentFunctionLabel.equals("main")) {
				topOfStack += 4 * 8;

				for (int i = 0; i < 8; i++) {
					out.println("\t sw	$" + (16 + i) + ","
							+ (nbMaxarg * 4 + (4 + 4 + i * 4)) + "($" + R_STACK
							+ ")");
				}
			}

			break;

		case ENDFUNC:

			if (currentFunctionLabel.equals("main")) {// restore s0-s1 saved by
														// called function
														// (number 16-23)
				for (int i = 0; i < 8; i++) {
					out.println("\t lw	$" + (16 + i) + ","
							+ (nbMaxarg * 4 + (4 + i * 4)) + "($" + R_STACK
							+ ")");
				}
			}

			// get @ret and stack modification
			out.println("\t lw	$" + R_RET + "," + nbMaxarg * 4 + "($" + R_STACK
					+ ")");
			out.println("\t addiu	$sp,$sp," + stackSize);

			this.out.println("\t jr  $" + R_RET);
			this.out.println("\t nop");

			out.println("\t.end " + currentFunctionLabel);
			beginFunction = true;
			break;

		case VARTAB:
			cg_vartabMIPS(inst.getA(), inst.getB(), inst.getC());
			break;
		case TABVAR:
			cg_tabvarMIPS(inst.getA(), inst.getB(), inst.getC());
			break;

		default: /* Don't know what this one is */
			System.err.println("unknown TAC opcode to translate");
			return;
		}
	}

	private void genCodeMIPSBinaryOp(String inst, Operand3a dest,
			Operand3a op1, Operand3a op2) throws IOException {
		MIPSCGTriplet<MIPSRegDesc> registers = this.regalloc.allocateRegisters(
				dest, op1, op2);
		MIPSRegDesc dst = registers.get1();
		MIPSRegDesc r1 = registers.get2();
		MIPSRegDesc r2 = registers.get3();
		String MIPSinst;

		if (inst == "mult" || inst == "div") {
			// mult
			// The low-order 32-bit word
			// of the result is placed into special register LO, and the
			// high-order 32-bit word is placed
			// into special register HI.

			// div
			// quotient is placed into special register LO
			// remainder is placed into special register HI.

			// use MFLO $dest to move LO to dest

			if (inst == "div") {// patch for gcc compatibility with div
								// gcc add the instruction mflo $r1
				regalloc.spillOne(r1.getRegNumber());
				regalloc.clearDescriptor(r1.getRegNumber());
				regalloc.spillOne(r2.getRegNumber());
				regalloc.clearDescriptor(r2.getRegNumber());
				regalloc.setDescriptor(dst.getRegNumber(), dest, R_MODIFIED);
			}

			MIPSinst = "\t" + inst + " $" + r1.getRegNumber() + ", $"
					+ r2.getRegNumber();
			this.out.println(MIPSinst);
			MIPSinst = "\t" + "mflo" + " $" + dst.getRegNumber();
			this.out.println(MIPSinst);

		} else if (inst == "add" || inst == "sub") {
			MIPSinst = "\t" + inst + " $" + dst.getRegNumber() + ", $"
					+ r1.getRegNumber() + ", $" + r2.getRegNumber();
			this.out.println(MIPSinst);

		} else {
			System.out.println("Error during code generation");
			System.exit(0);
		}

	}

	/**
	 * generate code for unary neg operator a := - b.
	 * 
	 * MIPS: neg $dest,$src
	 */
	private void cg_negMIPS(Operand3a a, Operand3a b) {
		int cr; /* Result register */
		int br; /* Second argument register */

		cr = regalloc.getErasable(a); /* Result register */
		br = regalloc.getAnother(b, cr);

		String MIPSinst;
		MIPSinst = "\t" + "neg  " + "$" + cr + ",$" + br;

		regalloc.setDescriptor(cr, a, R_MODIFIED);
		this.out.println(MIPSinst);
	}

	/**
	 * Generate code for a copy instruction a := b We load b into an register,
	 * then update the descriptors to indicate that a is also in that register.
	 * We need not do the store until the register is spilled or flushed.
	 * 
	 * @param a
	 * @param b
	 */
	private void cg_copyMIPS(Operand3a a, Operand3a b) {
		int br = regalloc.getErasable(b); /* Load b into a register */
		regalloc.setDescriptor(br, a, R_MODIFIED); /* Indicate a is there */
	}

	/**
	 * Generate for "goto", "ifz" or "ifnz". We must spill registers before the
	 * branch. In the case of unconditional goto we have no condition, and so
	 * "a" is NULL. We set the condition flags if necessary by explicitly
	 * loading "a" into a register to ensure the zero flag is set. A better
	 * approach would be to keep track of what is in the status register, so
	 * saving this load.
	 */

	private void cg_condMIPS(String op, Operand3a a, /* Condition */
			Operand3a label) /* Branch destination */
	{
		regalloc.spillAll();

		String MIPSinst = "";

		if (a != null) {// condition present
			int r;
			r = regalloc.search(a);
			if (r == -1)
				r = regalloc.getErasable(a); /* Load into new register */

			MIPSinst = "\t" + op + "  $" + r + ",0," + label.getName3a();
		} else {
			MIPSinst = "\t" + op + "  " + label.getName3a();
		}

		this.out.println(MIPSinst);

	}

	/**
	 * Allocate 4*sizeof(var) bytes on top of stack
	 */
	private int cg_varMIPS(Operand3a var, int offset) {
		int size;
		size = var.getSize();
		var.setOffset(offset);
		if (debugCG) {
			System.out.println("\\ " + var.getName3a() + "  @ = " + offset);
		}
		return offset + size;
	}

	/**
	 * We compute the address of the array element tab[indice]. If tab is a
	 * local array its address is R_STACK+offset+indice. If it is a pointer, its
	 * address is tab+indice. indice is the offset from the beginning of the
	 * array
	 */

	private int tab_addressMIPS(Operand3a tab, Operand3a indice) {
		int r1, r2, offset = tab.getOffset();

		r1 = regalloc.getErasable(indice); /* indice -> r1 */
		r2 = regalloc.getSome(r1);

		out.println(R_INDENT + "li   $" + r2 + ",4"); /* 4 -> r2 */
		out.println(R_INDENT + "mult   $" + r1 + ",$" + r2); /* indice*4 ->r1 */
		out.println(R_INDENT + "mflo   $" + r1);

		if (tab.isPointer()) {
			r2 = regalloc.getAnother(tab, r1); /* tab -> r2 */
			out.println(R_INDENT + "add   $" + r1 + ",$" + r1 + ",$" + r2);
		} else { /* local array */

			out.println(R_INDENT + "add   $" + r2 + ",$" + R_STACK + ","
					+ offset); // r2= offset + R_stack
			out.println(R_INDENT + "add   $" + r1 + ",$" + r1 + ",$" + r2); // r1=offset+
																			// R_stack
																			// +
																			// 4*indice
		}
		;
		return r1; /* register holding tab[indice] address */
	}

	/**
	 * assignments using indice adressing
	 */
	// tab[indice]=val
	private void cg_vartabMIPS(Operand3a tab, Operand3a indice, Operand3a val) {
		int r1, r2;
		r1 = tab_addressMIPS(tab, indice);

		regalloc.clearDescriptor(r1);

		r2 = regalloc.getAnother(val, r1); /* val -> r2 */

		out.println(R_INDENT + "sw  $" + r2 + ",0($" + r1 + ")");
		/* r2 ->tab[indice] */
	}

	// var=tab[indice]
	private void cg_tabvarMIPS(Operand3a var, Operand3a tab, Operand3a indice) {
		int r1;
		r1 = tab_addressMIPS(tab, indice);
		out.println(R_INDENT + "lw  $" + r1 + ",0($" + r1 + ")");
		/* tab[indice] -> r1 */
		regalloc.setDescriptor(r1, var, R_MODIFIED);
	}

	/**
	 * This routine is used to create the constant area in memory
	 */
	private void cg_constMIPS(List<Data3a> suite) {
		Data3a courant;
		String t;
		int i;

		for (int ic = 0; ic < suite.size(); ic++) {
			courant = suite.get(ic);
			out.println(R_INDENT + ".align 2");
			out.println(courant.getLabel() + ":"); // the label of the string
			t = courant.getText(); // the text

			out.print(R_INDENT + ".ascii\t\"");

			for (i = 0; i < t.length(); i++) {
				if (t.charAt(i) == '\\') {
					i++;
					switch (t.charAt(i)) {
					case 'n':
						out.print("\\012");
						break;
					case 't':
						out.print("\\011");
						break;
					case '\"':
						out.print("\"");
						break;
					}
				} else {
					out.print(t.charAt(i));
				}
			}
			out.println("\\000\"");

		}
	}
}
