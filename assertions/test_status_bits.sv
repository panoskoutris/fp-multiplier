module test_status_bits(input logic [7:0] status, input logic rst);

    // Aliases for readability
    logic zero_f, inf_f, nan_f, tiny_f, huge_f;
    assign zero_f = status[0];
    assign inf_f  = status[1];
    assign nan_f  = status[2];
    assign tiny_f = status[3];
    assign huge_f = status[4];

    // Immediate Assertions

    always_comb begin
        if (rst) begin  
            assert (!(zero_f && inf_f))  else $error("Illegal: zero_f and inf_f both asserted!");
            assert (!(zero_f && nan_f))  else $error("Illegal: zero_f and nan_f both asserted!");
            assert (!(inf_f  && nan_f))  else $error("Illegal: inf_f and nan_f both asserted!");
            assert (!(zero_f && tiny_f)) else $error("Illegal: zero_f and tiny_f both asserted!");
            assert (!(inf_f  && tiny_f)) else $error("Illegal: inf_f and tiny_f both asserted!");
            assert (!(nan_f  && tiny_f)) else $error("Illegal: nan_f and tiny_f both asserted!");
            assert (!(zero_f && huge_f)) else $error("Illegal: zero_f and huge_f both asserted!");
            assert (!(inf_f  && huge_f)) else $error("Illegal: inf_f and huge_f both asserted!");
            assert (!(nan_f  && huge_f)) else $error("Illegal: nan_f and huge_f both asserted!");
            assert (!(tiny_f && huge_f)) else $error("Illegal: tiny_f and huge_f both asserted!");
        end
    end
endmodule

