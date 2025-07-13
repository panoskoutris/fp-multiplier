module normalize_mult (
    input  logic [47:0] P,              
    input  logic signed [9:0]  exp_in,         

    output logic [22:0] mantissa_norm, 
    output logic signed [9:0]  exp_norm,      
    output logic        guard_bit,     
    output logic        sticky_bit     
);

    always_comb begin
        if (P[47] == 1'b1) begin
            // MSB is 1 -> shift 
            mantissa_norm = P[46:24];         
            guard_bit     = P[23];             
            sticky_bit    = |P[22:0];          
            exp_norm      = exp_in + 1;        
        end else begin
            // MSB is 0 -> no shift
            mantissa_norm = P[45:23];          
            guard_bit     = P[22];
            sticky_bit    = |P[21:0];
            exp_norm      = exp_in;            
        end
    end

endmodule
