import round_pkg::*; 

module fp_mult_top (
     clk, rst, rnd, a, b, z, status
);

    input logic [31:0] a, b;      	 
    input logic [2:0] rnd;        
    output logic [31:0] z;       
    output logic [7:0] status;    
    input logic clk, rst; 
    
    logic [31:0] a1, b1;
    round_mode rnd1;              
    logic [31:0] z1;
    logic [7:0] status1;
    
    fp_mult multiplier(a1, b1, rnd1, z1, status1, clk, rst);
    
    always @(posedge clk)
       if (!rst)
          begin 
             a1 <= '0;
             b1 <= '0;
             rnd1 <= IEEE_near;
             z <= '0;
             status <= '0;
          end
       else
          begin
             a1 <= a;
             b1 <= b;
             rnd1 <= round_mode'(rnd); 
             z <= z1;
             status <= status1;
          end

endmodule

