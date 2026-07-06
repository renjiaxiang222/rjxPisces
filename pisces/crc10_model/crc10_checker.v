// ============================================================================
// CRC10 Calculator / Checker
// Polynomial: x^10 + x^9 + x^5 + x^4 + x + 1  (CCITT CRC-10, 0x319)
// Reference: 数字协议（GZ）V1.1
// ============================================================================

// ----------------------------------------------------------------------------
// crc10_checker: CRC10 校验器
// 将收到的数据 (含 CRC) 输入计算器, 若余数为 0 则校验通过
// 用法: 先送入数据位 (1568 bits), 再送入 10-bit CRC 值, 最后检查余数
// ----------------------------------------------------------------------------
module crc10_checker (
    input         clk,
    input         rst_n,
    input         enable,
    input         data_in,
    input         load_seed,
    input  [9:0]  seed,
    input         check_en,       // 脉冲: 校验结果锁存
    output        crc_pass,       // 1 = CRC 校验通过 (余数为 0)
    output [9:0]  remainder       // CRC 余数 (通过时应为 0)
);

reg [9:0]  crc_reg;
reg        pass_reg;

// --- 与 crc10_serial 相同的反馈逻辑 ---
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

assign crc_pass  = pass_reg;
assign remainder = crc_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc_reg  <= 10'h000;
        pass_reg <= 1'b0;
    end else if (load_seed) begin
        crc_reg  <= seed;
        pass_reg <= 1'b0;
    end else if (check_en) begin
        pass_reg <= (crc_reg == 10'h000);
    end else if (enable) begin
        crc_reg  <= crc_next;
    end
end

endmodule
