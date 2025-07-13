module test_status_z_combinations (
    input logic clk,
    input logic rst_n,
    input logic [31:0] a, b, z,
    input logic [7:0] status
);

    // Bit aliases
    logic zero_f, inf_f, nan_f, tiny_f, huge_f;
    assign zero_f = status[0];
    assign inf_f  = status[1];
    assign nan_f  = status[2];
    assign tiny_f = status[3];
    assign huge_f = status[4];

    // Exponents and mantissas
    logic [7:0] exp_a, exp_b, exp_z;
    logic [22:0] mant_z;
    assign exp_a  = a[30:23];
    assign exp_b  = b[30:23];
    assign exp_z  = z[30:23];
    assign mant_z = z[22:0];

    // Delay pipelines
    logic [7:0] exp_a_d1, exp_a_d2, exp_a_d3;
    logic [7:0] exp_b_d1, exp_b_d2, exp_b_d3;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            exp_a_d1 <= 0; exp_a_d2 <= 0; exp_a_d3 <= 0;
            exp_b_d1 <= 0; exp_b_d2 <= 0; exp_b_d3 <= 0;
        end else begin
            exp_a_d1 <= exp_a;
            exp_a_d2 <= exp_a_d1;
            exp_a_d3 <= exp_a_d2;

            exp_b_d1 <= exp_b;
            exp_b_d2 <= exp_b_d1;
            exp_b_d3 <= exp_b_d2;
        end
    end

    // Concurrent Assertions 

    // zero_f => exp_z == 0
    property zero_status_ok;
        @(posedge clk) disable iff (!rst_n)
            zero_f |-> (exp_z == 8'b00000000);
    endproperty
    assert property (zero_status_ok)
        else $error("zero_f asserted but exponent of z is not 0");

    // inf_f => exp_z == 255
    property inf_status_ok;
        @(posedge clk) disable iff (!rst_n)
            inf_f |-> (exp_z == 8'b11111111);
    endproperty
    assert property (inf_status_ok)
        else $error("inf_f asserted but exponent of z is not 255");

    // nan_f => 3 cycles before: (exp_a == 0 && exp_b == 255) or vice versa
    property nan_status_ok;
        @(posedge clk) disable iff (!rst_n)
            nan_f |-> (
                (exp_a_d3 == 8'b00000000 && exp_b_d3 == 8'b11111111) ||
                (exp_b_d3 == 8'b00000000 && exp_a_d3 == 8'b11111111)
            );
    endproperty
    assert property (nan_status_ok)
        else $error("nan_f asserted but exponents of a,b 3 cycles earlier are not (0,255)/(255,0)");

    // huge_f => z is inf or maxNormal
    property huge_status_ok;
        @(posedge clk) disable iff (!rst_n)
            huge_f |-> (
                exp_z == 8'b11111111 || // inf
                (exp_z == 8'b11111110 && mant_z == 23'h7FFFFF) // maxNormal
            );
    endproperty
    assert property (huge_status_ok)
        else $error("huge_f asserted but z is not inf or maxNormal");

    // tiny_f => z is zero or minNormal
    property tiny_status_ok;
        @(posedge clk) disable iff (!rst_n)
            tiny_f |-> (
                exp_z == 8'b00000000 || // zero
                (exp_z == 8'b00000001 && mant_z == 23'h000000) // minNormal
            );
    endproperty
    assert property (tiny_status_ok)
        else $error("tiny_f asserted but z is not zero or minNormal");

endmodule

