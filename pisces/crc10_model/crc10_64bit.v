// ============================================================================
// CRC10 Calculator / Checker
// Polynomial: x^10 + x^9 + x^5 + x^4 + x + 1  (CCITT CRC-10, 0x319)
// Reference: 数字协议（GZ）V1.1
// ============================================================================

// ----------------------------------------------------------------------------
// crc10_64bit: 64-bit 并行 CRC10 计算器
// 每周期处理 64 bits, 匹配协议中 64-bit 数据帧宽度
// ----------------------------------------------------------------------------
module crc10_64bit (
    input         clk,
    input         rst_n,
    input         enable,
    input  [63:0] data_in,
    input         load_seed,
    input  [9:0]  seed,
    output [9:0]  crc_out,
    output        crc_valid
);

reg [9:0]  crc_reg;
reg        valid_reg;

// --- 级联展开: 64 次串行迭代, 每次处理 1 bit ---
wire [9:0] crc_chain [63:0];

// --- 第 0 级: 处理 data_in[0] ---
wire feedback_0 = crc_reg[9] ^ data_in[0];
assign crc_chain[0][9] = crc_reg[8] ^ feedback_0;
assign crc_chain[0][8] = crc_reg[7];
assign crc_chain[0][7] = crc_reg[6];
assign crc_chain[0][6] = crc_reg[5];
assign crc_chain[0][5] = crc_reg[4] ^ feedback_0;
assign crc_chain[0][4] = crc_reg[3] ^ feedback_0;
assign crc_chain[0][3] = crc_reg[2];
assign crc_chain[0][2] = crc_reg[1];
assign crc_chain[0][1] = crc_reg[0] ^ feedback_0;
assign crc_chain[0][0] = feedback_0;

// --- 第 1~63 级: 依次处理 data_in[1] ~ data_in[63] ---
genvar i;
generate
    for (i = 1; i < 64; i = i + 1) begin : crc_chain_gen
        wire feedback_i = crc_chain[i-1][9] ^ data_in[i];
        assign crc_chain[i][9] = crc_chain[i-1][8] ^ feedback_i;
        assign crc_chain[i][8] = crc_chain[i-1][7];
        assign crc_chain[i][7] = crc_chain[i-1][6];
        assign crc_chain[i][6] = crc_chain[i-1][5];
        assign crc_chain[i][5] = crc_chain[i-1][4] ^ feedback_i;
        assign crc_chain[i][4] = crc_chain[i-1][3] ^ feedback_i;
        assign crc_chain[i][3] = crc_chain[i-1][2];
        assign crc_chain[i][2] = crc_chain[i-1][1];
        assign crc_chain[i][1] = crc_chain[i-1][0] ^ feedback_i;
        assign crc_chain[i][0] = feedback_i;
    end
endgenerate

assign crc_out   = crc_reg;
assign crc_valid = valid_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_reg   <= 10'h000;
        valid_reg <= 1'b0;
    end else if (load_seed) begin
        crc_reg   <= seed;
        valid_reg <= 1'b1;
    end else if (enable) begin
        crc_reg   <= crc_chain[63];
        valid_reg <= 1'b1;
    end
end

endmodule
