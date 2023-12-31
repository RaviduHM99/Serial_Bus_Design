`timescale 1ns/1ps

module Address_Decoder(
    input logic CLK,
    input logic RSTN,

    input logic B_UTIL,
    output logic [2:0] AD_SEL,
    input logic A_ADD,
    input logic B_BUS_OUT,
    input logic [2:0] B_SBSY, //split one
    output logic SPL_4K_SEL
);
    reg [1:0] SLAVE_SEL;
    logic valid;
    always_comb begin
        unique case (SLAVE_SEL)
            2'd1 : AD_SEL = (valid & ~B_SBSY[0]) ? 3'b001 : 3'b0;
            2'd2 : AD_SEL = (valid) ? 3'b010 : 3'b0;
            2'd3 : AD_SEL = (valid) ? 3'b100 : 3'b0;
            default : AD_SEL = 3'b0;
        endcase
        SPL_4K_SEL = (valid & SLAVE_SEL == 2'd1 & B_SBSY[0]) ? 1'b1 : 1'b0;
        rst = (~A_ADD) ? 1'b1 : 1'b0;
        incr = (B_UTIL & A_ADD) ? 1'b1 : 1'b0;

    end

    localparam WIDTH = 4;
    logic rst, incr;
    logic [WIDTH-1:0] count;
    counter #(.WIDTH(WIDTH)) counter (.rst(rst), .CLK(CLK), .incr(incr), .count(count));

    always_ff @( posedge CLK or negedge RSTN ) begin
        if (!RSTN) begin
            SLAVE_SEL <= 2'b00;
            valid <= 1'b0;
        end
        else begin
            SLAVE_SEL[count] <= (B_UTIL & A_ADD) ? B_BUS_OUT : SLAVE_SEL[count];
            if (B_UTIL & count == 1) valid <= 1'b1;
            else if (B_UTIL & ~A_ADD) valid <= valid;
            else if (~B_UTIL & B_SBSY[2:1] != 2'b00) valid <= valid;
            else valid <= 1'b0;
        end
    end

endmodule