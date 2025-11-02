//===========================================================
// Top-level module for DE2 Board
// 16-bit Adder/Subtractor using switches and keys
//===========================================================

module addersubtractor (
    input  [17:0] SW,    // SW[15:0] = data, SW[17:16] = mode control
    input  [3:0]  KEY,   // KEY[0] = Reset (active low), KEY[1] = Clock
    output [17:0] LEDR,  // Show result
    output [8:0]  LEDG   // LEDG[0] = Overflow indicator
);

    //==============================
    // Control signal definitions
    //==============================
    wire Clock   = ~KEY[1];  // KEY active low → invert
    wire Reset   = ~KEY[0];
    wire AddSub  = SW[16];   // 0 = Add, 1 = Subtract
    wire Sel     = SW[17];   // Control mux

    //==============================
    // Input assignment
    //==============================
    wire [7:0] A = SW[15:8]; // A input (upper byte)
    wire [7:0] B = SW[7:0];  // B input (lower byte)

    //==============================
    // Internal connection wires
    //==============================
    wire [7:0] Z;
    wire Overflow;

    //==============================
    // Instantiate main core module
    //==============================
    addersubtractor_core #(.n(8)) core (
        .A(A),
        .B(B),
        .Clock(Clock),
        .Reset(Reset),
        .Sel(Sel),
        .AddSub(AddSub),
        .Z(Z),
        .Overflow(Overflow)
    );

    //==============================
    // Output mapping to LEDs
    //==============================
    assign LEDR[7:0]   = Z;         // Show result
    assign LEDR[17:8]  = 0;         // Unused LEDs off
    assign LEDG[0]     = Overflow;  // Overflow flag
    assign LEDG[8:1]   = 0;         // Others off

endmodule


//===========================================================
// Core Add/Subtract Module
//===========================================================

module addersubtractor_core #(parameter n = 8)(
    input  [n-1:0] A, B,
    input          Clock, Reset, Sel, AddSub,
    output [n-1:0] Z,
    output reg     Overflow
);

    //==============================
    // Internal registers & wires
    //==============================
    reg  [n-1:0] Areg, Breg, Zreg;
    reg          SelR, AddSubR;
    wire [n-1:0] G, H, M;
    wire         carryout, over_flow;

    //==============================
    // Arithmetic logic
    //==============================
    // If AddSub = 1 => subtract (invert B + carryin = 1)
    assign H = AddSubR ? ~Breg : Breg;

    mux2to1 #(.k(n)) mux_inst (
        .V(Areg),
        .W(Zreg),
        .Sel(SelR),
        .F(G)
    );

    adderk #(.k(n)) adder_inst (
        .carryin(AddSubR),
        .X(G),
        .Y(H),
        .S(M),
        .carryout(carryout)
    );

    // Overflow detection for 2’s complement arithmetic
    assign over_flow = (G[n-1] & H[n-1] & ~M[n-1]) |
                       (~G[n-1] & ~H[n-1] & M[n-1]);

    assign Z = Zreg;

    //==============================
    // Sequential logic
    //==============================
    always @(posedge Clock or posedge Reset) begin
        if (Reset) begin
            Areg     <= 0;
            Breg     <= 0;
            Zreg     <= 0;
            SelR     <= 0;
            AddSubR  <= 0;
            Overflow <= 0;
        end else begin
            Areg     <= A;
            Breg     <= B;
            Zreg     <= M;
            SelR     <= Sel;
            AddSubR  <= AddSub;
            Overflow <= over_flow;
        end
    end
endmodule


//===========================================================
// k-bit 2-to-1 Multiplexer
//===========================================================

module mux2to1 #(parameter k = 8)(
    input  [k-1:0] V, W,
    input          Sel,
    output [k-1:0] F
);
    assign F = Sel ? W : V;
endmodule


//===========================================================
// k-bit Adder
//===========================================================

module adderk #(parameter k = 8)(
    input  [k-1:0] X, Y,
    input          carryin,
    output [k-1:0] S,
    output         carryout
);
    assign {carryout, S} = X + Y + carryin;
endmodule
