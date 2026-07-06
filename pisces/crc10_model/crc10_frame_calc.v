// ============================================================================
// CRC10 Calculator / Checker
// Polynomial: x^10 + x^9 + x^5 + x^4 + x + 1  (CCITT CRC-10, 0x319)
// Reference: 数字协议（GZ）V1.1
// ============================================================================

// ----------------------------------------------------------------------------
// crc10_frame_calc: 帧级 CRC10 计算器
// 对应 PDF 中 26 帧的数据结构, 为 1568 bits 有效数据计算 4 组 CRC10
// 每组覆盖的数据范围参见 PDF 第 3 页的 1st~8st 196 数据映射表
// ----------------------------------------------------------------------------
module crc10_frame_calc (
    input         clk,
    input         rst_n,
    input         enable,
    input  [63:0] data_in,        // 64-bit 帧数据 (头部 + 62-bit payload)
    input  [5:0]  frame_idx,      // 帧序号 0~25
    input         frame_valid,    // 帧数据有效
    input         calc_crc,       // 脉冲: 启动 CRC 计算
    output [9:0]  crc0_out,       // 第 1 组 CRC10
    output [9:0]  crc1_out,       // 第 2 组 CRC10
    output [9:0]  crc2_out,       // 第 3 组 CRC10
    output [9:0]  crc3_out,       // 第 4 组 CRC10
    output        crc_done        // CRC 计算完成
);

// --- 4 组 CRC 各自独立的寄存器 ---
reg [9:0] crc0_reg, crc1_reg, crc2_reg, crc3_reg;
reg       done_reg;

// --- 从 64-bit 帧中提取 62-bit 有效 payload (去掉 2-bit header) ---
wire [61:0] payload = data_in[61:0];

// --- 级联链: 一次处理 62 bits (去掉 2-bit header 后的 payload) ---
wire [9:0] crc0_chain [61:0];
wire [9:0] crc1_chain [61:0];
wire [9:0] crc2_chain [61:0];
wire [9:0] crc3_chain [61:0];

// --- CRC 单步组合逻辑函数 (在 generate 中复用) ---
function [9:0] crc_step;
    input [9:0] crc_in;
    input       bit_in;
    reg         fb;
begin
    fb = crc_in[9] ^ bit_in;
    crc_step[9] = crc_in[8] ^ fb;
    crc_step[8] = crc_in[7];
    crc_step[7] = crc_in[6];
    crc_step[6] = crc_in[5];
    crc_step[5] = crc_in[4] ^ fb;
    crc_step[4] = crc_in[3] ^ fb;
    crc_step[3] = crc_in[2];
    crc_step[2] = crc_in[1];
    crc_step[1] = crc_in[0] ^ fb;
    crc_step[0] = fb;
end
endfunction

// --- 第 0 级 ---
wire [9:0] crc0_s0 = crc_step(crc0_reg, payload[0]);
wire [9:0] crc1_s0 = crc_step(crc1_reg, payload[0]);
wire [9:0] crc2_s0 = crc_step(crc2_reg, payload[0]);
wire [9:0] crc3_s0 = crc_step(crc3_reg, payload[0]);

assign crc0_chain[0] = crc0_s0;
assign crc1_chain[0] = crc1_s0;
assign crc2_chain[0] = crc2_s0;
assign crc3_chain[0] = crc3_s0;

// --- 第 1~61 级 ---
genvar j;
generate
    for (j = 1; j < 62; j = j + 1) begin : crc_payload_chain
        assign crc0_chain[j] = crc_step(crc0_chain[j-1], payload[j]);
        assign crc1_chain[j] = crc_step(crc1_chain[j-1], payload[j]);
        assign crc2_chain[j] = crc_step(crc2_chain[j-1], payload[j]);
        assign crc3_chain[j] = crc_step(crc3_chain[j-1], payload[j]);
    end
endgenerate

assign crc0_out = crc0_reg;
assign crc1_out = crc1_reg;
assign crc2_out = crc2_reg;
assign crc3_out = crc3_reg;
assign crc_done = done_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        crc0_reg <= 10'h000;
        crc1_reg <= 10'h000;
        crc2_reg <= 10'h000;
        crc3_reg <= 10'h000;
        done_reg <= 1'b0;
    end else if (calc_crc) begin
        crc0_reg <= 10'h000;
        crc1_reg <= 10'h000;
        crc2_reg <= 10'h000;
        crc3_reg <= 10'h000;
        done_reg <= 1'b0;
    end else if (enable && frame_valid) begin
        // 根据帧序号将 payload 的 CRC 结果累加到对应的 CRC 组
        // PDF 第 3 页映射:
        //   1st 196: DATA[0], DATA[1], DATA[2], DATA[24][61:52]
        //   2nd 196: DATA[3], DATA[4], DATA[5], DATA[24][51:42]
        //   3rd 196: DATA[6], DATA[7], DATA[8], DATA[24][41:32]
        //   4th 196: DATA[9], DATA[10], DATA[11], DATA[24][31:22]
        //   5th 196: DATA[12], DATA[13], DATA[14], DATA[24][21:12]
        //   6th 196: DATA[15], DATA[16], DATA[17], DATA[24][11:2]
        //   7th 196: DATA[18], DATA[19], DATA[20], DATA[24][1:0], DATA[25][61:54]
        //   8th 196: DATA[21], DATA[22], DATA[23], DATA[25][53:44]
        //
        // 每组 CRC10 覆盖 2 个 196-bit 块 = 392 bits
        //   第1组 CRC10: 1st 196 + 2nd 196
        //   第2组 CRC10: 3rd 196 + 4th 196
        //   第3组 CRC10: 5th 196 + 6th 196
        //   第4组 CRC10: 7th 196 + 8th 196
        case (frame_idx)
            6'd0,  6'd1,  6'd2,  6'd3,  6'd4,  6'd5:   crc0_reg <= crc0_chain[61];  // 1st+2nd 196
            6'd6,  6'd7,  6'd8,  6'd9,  6'd10, 6'd11:  crc1_reg <= crc1_chain[61];  // 3rd+4th 196
            6'd12, 6'd13, 6'd14, 6'd15, 6'd16, 6'd17:  crc2_reg <= crc2_chain[61];  // 5th+6th 196
            6'd18, 6'd19, 6'd20, 6'd21, 6'd22, 6'd23:  crc3_reg <= crc3_chain[61];  // 7th+8th 196
            default: begin
                crc0_reg <= crc0_reg;
                crc1_reg <= crc1_reg;
                crc2_reg <= crc2_reg;
                crc3_reg <= crc3_reg;
            end
        endcase
        if (frame_idx == 6'd25)
            done_reg <= 1'b1;
    end
end

endmodule
