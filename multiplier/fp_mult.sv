import round_pkg::*;

module fp_mult (
    input  logic [31:0] a, b,
    input  logic [2:0]  rnd,
    output logic [31:0] z,
    output logic [7:0]  status,
    input  logic        clk, rst
);

    // Stage 1: Unpack and prepare 
    logic        sign;
    logic signed [7:0]  a_exp, b_exp;
    logic signed [9:0]  exp_sum;
    logic [23:0] a_mant, b_mant;
    logic [47:0] P;

    always_comb begin
        sign     = a[31] ^ b[31];
        a_exp    = a[30:23];
        b_exp    = b[30:23];
        exp_sum  = a_exp + b_exp - 10'd127;
        a_mant   = {1'b1, a[22:0]};
        b_mant   = {1'b1, b[22:0]};
        P        = a_mant * b_mant;
    end

    // Stage 2: Normalize 
    logic [22:0] mantissa_norm;
    logic signed [9:0] exponent_norm;
    logic        guard_bit, sticky_bit;

    normalize_mult normalize_unit (
        .P(P),
        .exp_in(exp_sum),
        .mantissa_norm(mantissa_norm),
        .exp_norm(exponent_norm),
        .guard_bit(guard_bit),
        .sticky_bit(sticky_bit)
    );

    // Stage 3: Pipeline Register 
    logic [22:0] mantissa_reg;
    logic signed [9:0] exponent_reg;
    logic guard_reg, sticky_reg;
    logic sign_reg;
    round_mode round_reg;
    logic [31:0] a_reg, b_reg;

    always @(posedge clk) begin
        if (!rst) begin
            mantissa_reg <= '0;
            exponent_reg <= '0;
            guard_reg    <= '0;
            sticky_reg   <= '0;
            sign_reg     <= '0;
            round_reg    <= IEEE_near;
            a_reg        <= '0;
            b_reg        <= '0;
        end else begin
            mantissa_reg <= mantissa_norm;
            exponent_reg <= exponent_norm;
            guard_reg    <= guard_bit;
            sticky_reg   <= sticky_bit;
            sign_reg     <= sign;
            round_reg    <= round_mode'(rnd);
            a_reg        <= a;
            b_reg        <= b;
        end
    end

    // Stage 4: Rounding 
    logic [24:0] mantissa_rounded;
    logic signed [9:0] exponent_rounded;
    logic inexact;

    round_mult round_unit (
        .mantissa_in({1'b1, mantissa_reg}),
        .guard_bit(guard_reg),
        .sticky_bit(sticky_reg),
        .calculated_sign(sign_reg),
        .round(round_reg),
        .result(mantissa_rounded),
        .inexact(inexact)
    );

    // Stage 5: Post-rounding normalization and safe z_calc 
    logic [24:0] mantissa_shifted;
    logic [7:0]  exp_final;
    logic        overflow, underflow;
    logic [31:0] z_calc;

    always_comb begin
        // Normalize mantissa if MSB overflowed
        if (mantissa_rounded[24]) begin
            mantissa_shifted = mantissa_rounded >> 1;
            exponent_rounded = exponent_reg + 1;
        end else begin
            mantissa_shifted = mantissa_rounded;
            exponent_rounded = exponent_reg;
        end

        // Clamp exponent 
        if (exponent_rounded > 254)
            exp_final = 8'd255;
        else if (exponent_rounded < 1) begin
            exp_final = 8'd0;            
        end
        else
            exp_final = exponent_rounded[7:0];
        
        // Calculation of z_calc overflow and underflow bits
        z_calc = {sign_reg, exp_final, mantissa_shifted[22:0]};
        overflow  = (exponent_rounded > 254);
        underflow = (exponent_rounded < 1);
    end

    // Stage 6: Exception handling 
    logic zero_f, inf_f, nan_f, tiny_f, huge_f, inexact_f;

    exception_mult exception_unit (
        .a(a_reg),
        .b(b_reg),
        .z_calc(z_calc),
        .overflow(overflow),
        .underflow(underflow),
        .inexact(inexact),
        .round(round_reg),
        .z(z),   // Final z
        .zero_f(zero_f),
        .inf_f(inf_f),
        .nan_f(nan_f),
        .tiny_f(tiny_f),
        .huge_f(huge_f),
        .inexact_f(inexact_f)
    );

    // Final status
    assign status = {1'b0, 1'b0, inexact_f, huge_f, tiny_f, nan_f, inf_f, zero_f};

endmodule

