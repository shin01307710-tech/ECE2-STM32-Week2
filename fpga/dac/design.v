`timescale 1ns/1ps
// 데이터는 쓰기 LOW 펄스 전에 등록하고, 펄스 종료까지 유지합니다.
module dac_parallel8(
    input wire clk_50mhz,rst_p,update,channel,
    input wire [7:0] value,
    output wire cs_n,ldac_n,
    output reg we_n,a_b,
    output reg [7:0] data
);
    assign cs_n=0;
    assign ldac_n=0;
    always @(posedge clk_50mhz) begin
        if(rst_p) begin we_n<=1; a_b<=0; data<=0; end
        else begin
            we_n<=1;
            if(update) begin data<=value; a_b<=channel; we_n<=0; end
        end
    end
endmodule

`timescale 1ns/1ps
module dac #(parameter UPDATE_CYCLES=500_000)(
    input wire clk_50mhz,rst_p,add_sel,
    output wire dac_csn,dac_ldacn,dac_wen,dac_a_b,
    output wire [7:0] dac_d,led_out
);
    wire [7:0] value;
    wire update;
    ramp8 #(.UPDATE_CYCLES(UPDATE_CYCLES)) u_ramp(clk_50mhz,rst_p,value,update);
    dac_parallel8 u_bus(clk_50mhz,rst_p,update,add_sel,value,
        dac_csn,dac_ldacn,dac_wen,dac_a_b,dac_d);
    assign led_out=dac_d;
endmodule

`timescale 1ns/1ps
module ramp8 #(parameter UPDATE_CYCLES=500_000)(
    input wire clk_50mhz,rst_p,
    output reg [7:0] value,
    output wire update
);
    reg [31:0] count;
    assign update=(count==UPDATE_CYCLES-1);
    always @(posedge clk_50mhz) begin
        if(rst_p) begin count<=0; value<=0; end
        else if(update) begin count<=0; value<=value+1'b1; end
        else count<=count+1;
    end
endmodule
