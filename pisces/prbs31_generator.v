module prbs31_generator (
    input         clk,
    input         rst_n,
    input         enable,
    input         load_seed,
    input  [30:0] seed,
    output        prbs_out,
    output [30:0] prbs_state
);

reg [30:0] prbs_reg;

assign prbs_out = prbs_reg[0];
assign prbs_state = prbs_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prbs_reg <= 31'h7FFFFFFF;
    end else if (load_seed) begin
        prbs_reg <= seed;
    end else if (enable) begin
        prbs_reg <= {prbs_reg[29:0], prbs_reg[30] ^ prbs_reg[27]};
    end
end

endmodule

module prbs31_checker (
    input        clk,
    input        rst_n,
    input        enable,
    input        load_seed,
    input [30:0] seed,
    input        prbs_in,
    output       lock,
    output       error
);

reg [30:0] prbs_reg;
reg        lock_reg;
reg        error_reg;

wire expected_bit = prbs_reg[0];

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prbs_reg   <= 31'h7FFFFFFF;
        lock_reg   <= 1'b0;
        error_reg  <= 1'b0;
    end else if (load_seed) begin
        prbs_reg   <= seed;
        lock_reg   <= 1'b0;
        error_reg  <= 1'b0;
    end else if (enable) begin
        prbs_reg   <= {prbs_reg[29:0], prbs_reg[30] ^ prbs_reg[27]};
        
        if (prbs_in != expected_bit) begin
            error_reg <= 1'b1;
            lock_reg  <= 1'b0;
        end else begin
            error_reg <= 1'b0;
            lock_reg  <= 1'b1;
        end
    end
end

assign lock  = lock_reg;
assign error = error_reg;

endmodule

module prbs31_64bit (
    input         clk,
    input         rst_n,
    input         enable,
    input         load_seed,
    input  [30:0] seed,
    output [63:0] prbs_out,
    output [30:0] prbs_state
);

reg [30:0] prbs_reg;

wire [30:0] prbs_next[63:0];

assign prbs_next[0] = {prbs_reg[29:0], prbs_reg[30] ^ prbs_reg[27]};

genvar i;
generate
    for (i = 1; i < 64; i = i + 1) begin
        assign prbs_next[i] = {prbs_next[i-1][29:0], prbs_next[i-1][30] ^ prbs_next[i-1][27]};
    end
endgenerate

assign prbs_out[0] = prbs_reg[0];
generate
    for (i = 1; i < 64; i = i + 1) begin
        assign prbs_out[i] = prbs_next[i-1][0];
    end
endgenerate

assign prbs_state = prbs_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        prbs_reg <= 31'h7FFFFFFF;
    end else if (load_seed) begin
        prbs_reg <= seed;
    end else if (enable) begin
        prbs_reg <= prbs_next[63];
    end
end

endmodule