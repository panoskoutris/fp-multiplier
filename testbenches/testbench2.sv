`timescale 1ns/1ps
import round_pkg::*;
import mult_pkg::*;

module testbench2;

    logic clk, rst;
    logic [31:0] a, b;
    logic [2:0] rnd;
    logic [31:0] z;
    logic [7:0] status;

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

    // Select Rounding Mode Here 
    round_mode rmode = away_zero;

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

    // Enum of all 12 corner cases
    typedef enum int {
        pos_snan, neg_snan,
        pos_qnan, neg_qnan,
        pos_inf,  neg_inf,
        pos_norm, neg_norm,
        pos_sub,  neg_sub,
        pos_zero, neg_zero
    } corner_case_t;

    // Generate predefined bit patterns for corner cases
    function logic [31:0] get_pattern(corner_case_t t);
        case (t)
            pos_snan:  return 32'h7fa00001;
            neg_snan:  return 32'hffa00001;
            pos_qnan:  return 32'h7fc00000;
            neg_qnan:  return 32'hffc00000;
            pos_inf:   return 32'h7f800000;
            neg_inf:   return 32'hff800000;
            pos_norm:  return 32'h4b400001; 
            neg_norm:  return 32'hcb400001;
            pos_sub:   return 32'h00000001;
            neg_sub:   return 32'h80000001;
            pos_zero:  return 32'h00000000;
            neg_zero:  return 32'h80000000;
            default:   return 32'hDEADBEEF;
        endcase
    endfunction

    typedef struct {
        logic [31:0] a, b, expected_z;
        string round_str, desc;
        int valid_cycle;
        int test_id;
    } test_entry_t;

    test_entry_t test_queue[144];
    int cycle = 0;
    int apply_idx = 0;

    logic [31:0] ra, rb, ref_z;
    string rstr;

    corner_case_t all_cases[12] = '{
        pos_snan, neg_snan,
        pos_qnan, neg_qnan,
        pos_inf,  neg_inf,
        pos_norm, neg_norm,
        pos_sub,  neg_sub,
        pos_zero, neg_zero
    };

    initial begin
        rst = 0; a = 0; b = 0; rnd = rmode;
        #12;
        rst = 1;
   
        $display("=== Starting Corner Case Test ===");
        $display("Rounding mode set to: %s", round_to_string(rmode));

        forever begin
            @(posedge clk);
            cycle++;

            if (apply_idx < 144) begin
                ra = get_pattern(all_cases[apply_idx / 12]);
                rb = get_pattern(all_cases[apply_idx % 12]);
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
                    desc: $sformatf("Corner Case Test %0d: %s x %s", apply_idx, all_cases[apply_idx / 12].name(), all_cases[apply_idx % 12].name()),
                    valid_cycle: cycle + 4,
                    test_id: apply_idx
                };

                $display("Cycle %0t: Applied %s", $time, test_queue[apply_idx].desc);
                apply_idx++;
            end

            for (int i = 0; i < 144; i++) begin
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

            if (cycle > 144 + 10)
                break;
        end

        $display("=== Corner Case Test Complete ===");
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