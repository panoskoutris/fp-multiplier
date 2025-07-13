import round_pkg::*;

module exception_mult (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [31:0] z_calc,
    input  logic        overflow,
    input  logic        underflow,
    input  logic        inexact,
    input  round_mode   round,

    output logic [31:0] z,
    output logic zero_f,
    output logic inf_f,
    output logic nan_f,
    output logic tiny_f,
    output logic huge_f,
    output logic inexact_f
);

    typedef enum logic [2:0] {
        ZERO,
        INF,
        NORM,
        MIN_NORM,
        MAX_NORM
    } interp_t;

    function interp_t num_interp(logic [31:0] num);
        case (num[30:23])
            8'b1111_1111: return INF;
            8'b0000_0000: return ZERO;
            default:      return NORM;
        endcase
    endfunction

    function logic [30:0] z_num(interp_t interp);
        case (interp)
            ZERO:     return 31'b00000000_00000000000000000000000;
            INF:      return 31'b11111111_00000000000000000000000;
            MIN_NORM: return 31'b00000001_00000000000000000000000;
            MAX_NORM: return 31'b11111110_11111111111111111111111;
            default:  return 31'b0;
        endcase
    endfunction

    interp_t interp_a, interp_b;
    logic sign;

    always_comb begin
        z         = 32'b0;
        zero_f    = 0;
        inf_f     = 0;
        nan_f     = 0;
        tiny_f    = 0;
        huge_f    = 0;
        inexact_f = inexact;

        sign      = z_calc[31];
        interp_a  = num_interp(a);
        interp_b  = num_interp(b);

        // Corner cases (Table 4) 
        if (interp_a == ZERO && interp_b == ZERO) begin
            z = {sign, z_num(ZERO)};
            zero_f = 1;
        end else if (interp_a == ZERO && interp_b == NORM) begin
            z = {sign, z_num(ZERO)};
            zero_f = 1;
        end else if (interp_a == ZERO && interp_b == INF) begin
            z = {1'b0, z_num(INF)};
            nan_f = 1;
        end else if (interp_a == INF && interp_b == INF) begin
            z = {sign, z_num(INF)};
            inf_f = 1;
        end else if (interp_a == INF && interp_b == NORM) begin
            z = {sign, z_num(INF)};
            inf_f = 1;
        end else if (interp_a == INF && interp_b == ZERO) begin
            z = {1'b0, z_num(INF)};
            nan_f = 1;
        end else if (interp_a == NORM && interp_b == ZERO) begin
            z = {sign, z_num(ZERO)};
            zero_f = 1;
        end else if (interp_a == NORM && interp_b == INF) begin
            z = {sign, z_num(INF)};
            inf_f = 1;
        end

        // Overflow case 
        else if (overflow) begin
            unique case (round)
                IEEE_near, near_up, away_zero: begin
                    z = {sign, z_num(INF)};
                    inf_f = 1;
                end
                IEEE_zero: begin
                    z = {sign, z_num(MAX_NORM)};
                    huge_f = 1;
                end
                IEEE_pinf: begin
                    if (sign == 1'b0) begin
                        z = {sign, z_num(INF)};
                        inf_f = 1;
                    end else begin
                        z = {sign, z_num(MAX_NORM)};
                        huge_f = 1;
                    end
                end
                IEEE_ninf: begin
                    if (sign == 1'b1) begin
                        z = {sign, z_num(INF)};
                        inf_f = 1;
                    end else begin
                        z = {sign, z_num(MAX_NORM)};
                        huge_f = 1;
                    end
                end
                default: begin
                    z = {sign, z_num(INF)};
                    inf_f = 1;
                end
            endcase
        end

        // Underflow case 
        else if (underflow) begin
            unique case (round)
                IEEE_near, IEEE_zero, near_up: begin
                    z = {sign, z_num(ZERO)};
                    zero_f = 1;
                end
                IEEE_pinf: begin
                    if (sign == 1'b1) begin
                        z = {1'b1, z_num(ZERO)};
                        zero_f = 1;
                    end else begin
                        z = {1'b0, z_num(MIN_NORM)};
                        tiny_f = 1;
                    end
                end
                IEEE_ninf: begin
                    if (sign == 1'b0) begin
                        z = {1'b0, z_num(ZERO)};
                        zero_f = 1;
                    end else begin
                        z = {1'b1, z_num(MIN_NORM)};
                        tiny_f = 1;
                    end
                end
                away_zero: begin
                    z = {sign, z_num(MIN_NORM)};
                    tiny_f = 1;
                end
                default: begin
                    z = {sign, z_num(ZERO)};
                    zero_f = 1;
                end
            endcase
        end

        // Normal case
        else begin
            z = z_calc;
        end
    end

endmodule


