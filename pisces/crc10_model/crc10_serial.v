// ============================================================================
// CRC10 Calculator / Checker
// Polynomial: x^10 + x^9 + x^5 + x^4 + x + 1  (CCITT CRC-10, 0x319)
// Reference: 数字协议（GZ）V1.1
// ============================================================================

// ----------------------------------------------------------------------------
// crc10_serial: 串行 (bit-by-bit) CRC10 计算器
// ----------------------------------------------------------------------------
module crc10_serial (
    input         clk,
    input         rst_n,
    input         enable,
    input         data_in,
    input         load_seed,
    input  [9:0]  seed,
    output [9:0]  crc_out,
    output        crc_valid
);

// ======================================================================
// --- CRC10 多项式: x^10 + x^9 + x^5 + x^4 + x + 1
// --- 反馈位: feedback = crc[9] ^ data_in
// --- crc_next[9] = crc[8] ^ feedback    (x^9 抽头)
// --- crc_next[8] = crc[7]
// --- crc_next[7] = crc[6]
// --- crc_next[6] = crc[5]
// --- crc_next[5] = crc[4] ^ feedback    (x^5 抽头)
// --- crc_next[4] = crc[3] ^ feedback    (x^4 抽头)
// --- crc_next[3] = crc[2]
// --- crc_next[2] = crc[1]
// --- crc_next[1] = crc[0] ^ feedback    (x^1 抽头)
// --- crc_next[0] = feedback             (x^0 = 1 抽头)
// ======================================================================

reg [9:0] crc_reg;
reg       valid_reg;

wire feedback = crc_reg[9] ^ data_in;

wire [9:0] crc_next;
assign crc_next[9] = crc_reg[8] ^ feedback;
assign crc_next[8] = crc_reg[7];
assign crc_next[7] = crc_reg[6];
assign crc_next[6] = crc_reg[5];
assign crc_next[5] = crc_reg[4] ^ feedback;
assign crc_next[4] = crc_reg[3] ^ feedback;
assign crc_next[3] = crc_reg[2];
assign crc_next[2] = crc_reg[1];
assign crc_next[1] = crc_reg[0] ^ feedback;
assign crc_next[0] = feedback;

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
        crc_reg   <= crc_next;
        valid_reg <= 1'b1;
    end
end

endmodule
