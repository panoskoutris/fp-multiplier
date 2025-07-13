import round_pkg::*;

module round_mult (
    input  logic [23:0] mantissa_in,
    input  logic        guard_bit,
    input  logic        sticky_bit,
    input  logic        calculated_sign,
    input  round_mode   round,

    output logic [24:0] result,     
    output logic        inexact
);
  
    logic round_up;  // The bit that will be added or not to mantissa
    
    always_comb begin
     
        result   = 25'b0;
        inexact = guard_bit | sticky_bit;
        round_up = 1'b0;
        

        case (round)
            IEEE_near:    round_up = guard_bit & (sticky_bit | mantissa_in[0]);
            IEEE_zero:    round_up = 1'b0;
            IEEE_pinf:    round_up = (calculated_sign == 1'b0) & inexact;
            IEEE_ninf:    round_up = (calculated_sign == 1'b1) & inexact;
            near_up:      round_up = guard_bit;
            away_zero:    round_up = inexact;
            default:      round_up = guard_bit & (sticky_bit | mantissa_in[0]);
        endcase

        result = {1'b0, mantissa_in} + round_up; // One extra bit in case of overflow
    end

endmodule
