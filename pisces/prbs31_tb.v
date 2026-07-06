`timescale 1ns / 1ps

module prbs31_tb;

reg         clk;
reg         rst_n;
reg         enable;
reg         load_seed;
reg  [30:0] seed;
wire        prbs_out;
wire [30:0] prbs_state;
wire [63:0] prbs_64bit_out;
wire [30:0] prbs_64bit_state;
wire        lock;
wire        error;

prbs31_generator u_prbs_gen (
    .clk        (clk),
    .rst_n      (rst_n),
    .enable     (enable),
    .load_seed  (load_seed),
    .seed       (seed),
    .prbs_out   (prbs_out),
    .prbs_state (prbs_state)
);

prbs31_checker u_prbs_check (
    .clk        (clk),
    .rst_n      (rst_n),
    .enable     (enable),
    .load_seed  (load_seed),
    .seed       (seed),
    .prbs_in    (prbs_out),
    .lock       (lock),
    .error      (error)
);

prbs31_64bit u_prbs_64bit (
    .clk        (clk),
    .rst_n      (rst_n),
    .enable     (enable),
    .load_seed  (load_seed),
    .seed       (seed),
    .prbs_out   (prbs_64bit_out),
    .prbs_state (prbs_64bit_state)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end

initial begin
    $dumpfile("prbs31_tb.vcd");
    $dumpvars(0, prbs31_tb);
    
    rst_n      = 1'b0;
    enable     = 1'b0;
    load_seed  = 1'b0;
    seed       = 31'h0;
    
    #10;
    rst_n = 1'b1;
    
    #10;
    enable = 1'b1;
    
    #1000;
    
    $display("Test completed successfully!");
    $finish;
end

initial begin
    $monitor("Time=%0t, prbs_out=%b, lock=%b, error=%b, prbs_state=%h", 
             $time, prbs_out, lock, error, prbs_state);
end

endmodule