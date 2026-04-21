////////////////////////////////////////////////////////////////////////////////////////////////////
//
// File: function_unit.v
//
// INSERT AN APPROPRIATE HEADER
////////////////////////////////////////////////////////////////////////////////////////////////////

module function_unit(FS, OpA, OpB, result, V, C, N, Z);
	input   [3:0] FS;				// Function Unit select code.
   input  [15:0] OpA;				// Function Unit operand A
   input  [15:0] OpB;				// Function Unit operand B
   output [15:0] result;		// Function Unit result
   output        V;				// Overflow status bit
   output        C;				// Carry-out status bit
   output        N;				// Negative status bit
   output        Z;				// Zero status bit
	
	wire carry, cout;
	wire w0, w1, w2;
	wire [15:0] sel0, sel1, sel2;
	
	// 0100 movA, 0011 add, 0010 subAB, 0001 incA, 0101 negB, 0110 dec3B
	assign w2 = (~FS[3] & ~FS[1]) | (~FS[3] & ~FS[2]) | (FS[2] & FS[1] & ~FS[0]);
	// 1010 shift, 1011 div4, 1100 mult16, 1111 notA
	assign w1 = (FS[3] & ~FS[2] & FS[1]) | (FS[3] & FS[2] & ~FS[1] & ~FS[0]) | (FS[3] & FS[1] & FS[0]);
	// 0111 AND, 1000 OR, 1001 XOR, 1101 XNOR
	assign w0 = (FS[3] & ~FS[2] & ~FS[1]) | (FS[3] & ~FS[1] & FS[0]) | (~FS[3] & FS[2] & FS[1] & FS[0]);

	block2 arith(sel2, carry, cout, FS, OpA, OpB);
	block1 misc(sel1, OpA, OpB, FS);
	block0 logic(sel0, OpA, OpB, FS);

	assign result = (w2 == 1'b1) ? sel2 :
					(w1 == 1'b1) ? sel1 :
					(w0 == 1'b1) ? sel0 : 16'bx;
  
	assign V = carry ^ cout;
	assign C = carry & w2;
	assign N = result[15] & ~(FS[3] & ~FS[2] & FS[1] & ~FS[0]);
	assign Z = ~result[7] & ~result[6] & ~result[5] & ~result[4] & ~result[3] & ~result[2] & ~result[1] & ~result[0];
endmodule

module block2(result, carry, cout, sel, A, B);
	input [15:0] A, B;
	input [3:0] sel;
	output [15:0] result;
	output carry, cout;

	wire [15:0] w1, w2;
	wire [1:0] sA, sB;
	wire cin;
	wire [15:0] eight_one, eight_zero, neg3;

	// Constants
	assign eight_one = 16'b1111111111111111;
	assign eight_zero = 16'b0000000000000000;
	assign neg3 = 16'b1111111111111101;

	assign sA[1] = ~sel[3] & sel[2] & sel[1] & ~sel[0];
	assign sA[0] = ~sel[3] & sel[2] & ~sel[1] & sel[0];
	assign sB[1] = (~sel[3] & sel[2] & ~sel[1] & ~sel[0]) | (~sel[3] & ~sel[2] & ~sel[1] & sel[0]);
	assign sB[0] = (~sel[3] & ~sel[2] & sel[1] & ~sel[0]) | (~sel[3] & sel[2] & ~sel[1] & sel[0]);
	assign cin = (~sel[3] & ~sel[2] & sel[1] & ~sel[0]) | (~sel[3] & ~sel[2] & ~sel[1] & sel[0]) | (~sel[3] & sel[2] & ~sel[1] & sel[0]);
		
	mux4x1 MUXA(w1, sA, A, eight_zero, neg3,  eight_one);
	mux4x1 MUXB(w2, sB, B, ~B, eight_zero, eight_one);

	eightbitadder main(result, w1, w2, carry, cout, cin);
endmodule

module full_adder(s, c, a, b, cin);
	input a, b, cin;
	output s, c;

	assign s = a ^ b ^ cin;
	assign c = a & b | (cin & (a ^ b)); 
endmodule
 
module eightbitadder(S, A, B, C15, C16, C0);
	input [15:0] A, B;
	input C0;
	output [15:0] S;
	output C15, C16;
	wire c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15;

	full_adder fA0(S[0], c1, A[0], B[0], C0);
	full_adder fA1(S[1], c2, A[1], B[1], c1);
	full_adder fA2(S[2], c3, A[2], B[2], c2);
	full_adder fA3(S[3], c4, A[3], B[3], c3);
	full_adder fA4(S[4], c5, A[4], B[4], c4);
	full_adder fA5(S[5], c6, A[5], B[5], c5);
	full_adder fA6(S[6], c7, A[6], B[6], c6);
	full_adder fA7(S[7], c8, A[7], B[7], c7);
	full_adder fA8(S[8], c9, A[0], B[8], c8);
	full_adder fA9(S[9], c10, A[1], B[9], c9);
	full_adder fA10(S[10], c11, A[2], B[10], c10);
	full_adder fA11(S[11], c12, A[3], B[11], c11);
	full_adder fA12(S[12], c13, A[4], B[12], c12);
	full_adder fA13(S[13], c14, A[5], B[13], c13);
	full_adder fA14(S[14], c15, A[6], B[14], c14);
	full_adder fA15(S[15], C16, A[7], B[15], c15);
	
	assign C15 = c15;
endmodule 

module mux4x1(F, S, X1, X2, X3, X4);
	input [1:0] S;
	input [15:0] X1, X2, X3, X4;
	output [15:0] F;
	
	assign F = (S == 2'b00) ? X1 :
				  (S == 2'b01) ? X2 :
				  (S == 2'b10) ? X3 :
				  (S == 2'b11) ? X4 : 16'bx;
endmodule


module block0 (result, OpA, OpB, sel);
	input [3:0] sel;
	input [15:0] OpA, OpB;
	output [15:0] result;
	wire [15:0] and1, or1, xor1, xnor1;
	wire [1:0] select;
	
	assign and1 = (OpA & OpB);
	assign or1 = (OpA | OpB);
	assign xor1 = (OpA ^ OpB);
	assign xnor1 = ~(OpA ^ OpB);

	assign select[1] = (sel[3] & ~sel[2] & ~sel[1] & sel[0]) | (sel[3] & sel[2] & ~sel[1] & sel[0]);
	assign select[0] = (sel[3] & ~sel[2] & ~sel[1] & ~sel[0]) | (sel[3] & sel[2] & ~sel[1] & sel[0]);
	// 0111 AND, 1000 OR, 1001 XOR, 1101 XNOR
	mux4x1 b2mux(result, select, and1, or1, xor1, xnor1);
endmodule


module block1 (result, OpA, OpB, sel);
	input [3:0] sel;
	input [15:0] OpB, OpA;
	output [15:0] result;
	wire [15:0] div, mult, shift, notA;
	wire [1:0] select;


	// Implements lslb
	assign shift[0] = 1'b0;
	assign shift[1] = OpB[0];
	assign shift[2] = OpB[1];
	assign shift[3] = OpB[2];
	assign shift[4] = OpB[3];
	assign shift[5] = OpB[4];
	assign shift[6] = OpB[5];
	assign shift[7] = OpB[6];
	assign shift[8] = OpB[7];
	assign shift[9] = OpB[8];
	assign shift[10] = OpB[9];
	assign shift[11] = OpB[10];
	assign shift[12] = OpB[11];
	assign shift[13] = OpB[12];
	assign shift[14] = OpB[13];
	assign shift[15] = OpB[14];
	
	// Implements div4 - changed to work with signed numbers
	assign div[0] = OpB[2];
	assign div[1] = OpB[3];
	assign div[2] = OpB[4];
	assign div[3] = OpB[5];
	assign div[4] = OpB[6];
	assign div[5] = OpB[7];
	assign div[6] = OpB[8];
	assign div[7] = OpB[9];
	assign div[8] = OpB[10]
	assign div[9] = OpB[11]
	assign div[10] = OpB[12]
	assign div[11] = OpB[13]
	assign div[12] = OpB[14]
	assign div[13] = OpB[15]
	assign div[14] = OpB[15]
	assign div[15] = OpB[15]
	// Implements mult16
	assign mult[0] = 1'b0;
	assign mult[1] = 1'b0;
	assign mult[2] = 1'b0;
	assign mult[3] = 1'b0;
	assign mult[4] = OpB[0];
	assign mult[5] = OpB[1];
	assign mult[6] = OpB[2];
	assign mult[7] = OpB[3];
	assign mult[8] = OpB[4];
	assign mult[9] = OpB[5];
	assign mult[10] = OpB[6];
	assign mult[11] = OpB[7];
	assign mult[12] = OpB[8];
	assign mult[13] = OpB[9];
	assign mult[14] = OpB[10];
	assign mult[15] = OpB[11];
	
	// Implements notA
	assign notA = ~OpA;
	
	// Selects the output

	// 1010 shift, 1011 div4, 1100 mult16, 1111 notA
	// assign result = (sel == 4'b1010) ? shift :
	// 				(sel == 4'b1011) ? div :
	// 				(sel == 4'b1111) ? notA :
	// 				(sel == 4'b1100) ? mult : 8'bx;
	assign select[1] = (sel[3] & sel[2] & ~sel[1] & ~sel[0]) | (sel[3] & sel[2] & sel[1] & sel[0]);
	assign select[0] = (sel[3] & ~sel[2] & sel[1] & sel[0]) | (sel[3] & sel[2] & sel[1] & sel[0]);

	mux4x1 b1mux(result, select, shift, div, mult, notA);
	
endmodule