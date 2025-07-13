`timescale 1ns/1ps
import round_pkg::*;
import mult_pkg::*;

module testbench;

    logic clk, rst;
    logic [31:0] a, b;
    logic [2:0] rnd;
    logic [31:0] z;
    logic [7:0] status;
    logic output_valid;

    // Select Rounding Mode Here 
    round_mode rmode = IEEE_ninf;

    fp_mult_top dut (
        .clk(clk),
        .rst(rst),
        .rnd(rnd),
        .a(a),
        .b(b),
        .z(z),
        .status(status)
    );


    initial clk = 0;
    always #5 clk = ~clk;

    function string round_to_string(round_mode r);
        case (r)
            IEEE_near:  return "IEEE_near";
            IEEE_zero:  return "IEEE_zero";
            IEEE_pinf:  return "IEEE_pinf";
            IEEE_ninf:  return "IEEE_ninf";
            near_up:    return "near_up";
            away_zero:  return "away_zero";
            default:    return "IEEE_near";
        endcase
    endfunction

    typedef struct {
        logic [31:0] a, b, expected_z;
        string round_str, desc;
        int valid_cycle;
        int test_id;
    } test_entry_t;

    test_entry_t test_queue[20];
    int cycle = 0;
    int apply_idx = 0;
    int TEST_COUNT = 20;

    logic [31:0] ra, rb, ref_z;
    string rstr;

    function logic [31:0] gen_valid_float();
        logic [31:0] val;
        val[31]     = $urandom() % 2;
        val[30:23]  = $urandom();
        val[22:0]   = $urandom();
        return val;
    endfunction

    initial begin
        rst = 0; a = 0; b = 0; rnd = rmode;
        #12;
        rst = 1;

        $display("=== Starting Random Test ===");
        $display("Rounding mode set to: %s", round_to_string(rmode));

        forever begin
            @(posedge clk);
            cycle++;

            if (apply_idx < TEST_COUNT) begin
                ra = gen_valid_float();
                rb = gen_valid_float();
                rstr = round_to_string(rmode);
                ref_z = multiplication(rstr, ra, rb);

                a = ra;
                b = rb;
                rnd = rmode;

                test_queue[apply_idx] = '{
                    a: ra,
                    b: rb,
                    expected_z: ref_z,
                    round_str: rstr,
                    desc: $sformatf("Random Test %0d, Round: %s", apply_idx, rstr),
                    valid_cycle: cycle + 4,
                    test_id: apply_idx
                };

                $display("Cycle %0t: Applied %s", $time, test_queue[apply_idx].desc);
                apply_idx++;
            end

            for (int i = 0; i < TEST_COUNT; i++) begin
                if (test_queue[i].valid_cycle == cycle) begin
                    $display("--- Result for %s ---", test_queue[i].desc);
                    $display("A = %h (%f)", test_queue[i].a, $bitstoshortreal(test_queue[i].a));
                    $display("B = %h (%f)", test_queue[i].b, $bitstoshortreal(test_queue[i].b));
                    $display("Expected z = %h (%f)", test_queue[i].expected_z, $bitstoshortreal(test_queue[i].expected_z));
                    $display("Actual   z = %h (%f)", z, $bitstoshortreal(z));
                    $display("Status      = %b", status);
                    if (z !== test_queue[i].expected_z)
                        $error("MISMATCH in result for test %0d", test_queue[i].test_id);
                    else
                        $display("Match");
                end
            end

            if (cycle > TEST_COUNT + 10)
                break;
        end

        $display("=== Test Complete ===");
        $finish;
    end

endmodule

// Bind Assertion 1
bind fp_mult_top test_status_bits check1 (
     .status(status),
     .rst(rst)
);
// Bind Assetions 2
bind fp_mult_top test_status_z_combinations zcheck (
    .clk(clk),
    .rst_n(rst),
    .a(a),
    .b(b),
    .z(z),
    .status(status)
);
