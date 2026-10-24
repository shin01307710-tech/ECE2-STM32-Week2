`timescale 1ns/1ps
// 간단한 비동기 SRAM 모델. 실제 장치의 ns 단위 접근 시간은 별도입니다.
module sram_model(
    input wire cs_n,oe_n,we_n,
    input wire [17:0] address,
    inout wire [15:0] data
);
    reg [15:0] memory[0:15];
    assign data=(!cs_n && !oe_n && we_n) ? memory[address[3:0]] : 16'bz;
    always @(negedge we_n) begin
        #1;
        if(!cs_n && !we_n) memory[address[3:0]]=data;
    end
endmodule

module tb;
    initial begin $dumpfile("sram.vcd"); $dumpvars(0, tb); end
    reg wr=0,rd=0;
    reg [3:0] address=0,data_in=0;
    wire cs_n,oe_n,we_n;
    wire [17:0] ram_address;
    wire [15:0] bus;
    wire [7:0] led;
    sram dut(wr,rd,address,data_in,cs_n,oe_n,we_n,ram_address,bus,led);
    sram_model memory(cs_n,oe_n,we_n,ram_address,bus);
    integer i;
    initial begin
        #2;
        if(bus !== 16'bz || led !== 0) $fatal(1,"idle");
        for(i=0;i<16;i=i+1) begin
            address=i; data_in=15-i; #2;
            wr=1; #2;
            if(bus !== 15-i || ram_address !== i) $fatal(1,"write bus");
            wr=0; #2;
        end
        for(i=0;i<16;i=i+1) begin
            address=i; rd=1; #2;
            if(led !== 15-i || bus !== 15-i) $fatal(1,"read address=%0d",i);
            rd=0; #2;
        end
        wr=1; rd=1; #2;
        if(bus !== 16'bz || {cs_n,oe_n,we_n} !== 3'b111) $fatal(1,"conflict");
        $display("PASS SRAM: 16 addresses, bus release, simultaneous request"); $finish;
    end
    initial begin #1000; $fatal(1,"timeout"); end
endmodule
