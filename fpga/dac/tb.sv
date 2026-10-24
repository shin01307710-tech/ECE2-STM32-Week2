`timescale 1ns/1ps
module tb;
    initial begin $dumpfile("dac.vcd"); $dumpvars(0, tb); end
    reg clk=0,rst=1,channel=0;
    always #5 clk=~clk;
    wire cs_n,ldac_n,we_n,a_b;
    wire [7:0] data,led;
    dac #(.UPDATE_CYCLES(4)) dut(clk,rst,channel,cs_n,ldac_n,we_n,a_b,data,led);
    integer writes=0;
    time last_fall;
    reg [7:0] held_data;
    reg held_channel;
    // 병렬 DAC 모델: LOW 펄스 동안 안정된 데이터를 종료 에지에서 기록합니다.
    always @(negedge we_n) begin
        #1; held_data=data; held_channel=a_b; last_fall=$time;
    end
    always @(posedge we_n) begin
        if(!rst) begin
            if($time-last_fall != 9) $fatal(1,"DAC write pulse width");
            if(data !== held_data || a_b !== held_channel) $fatal(1,"DAC data hold");
            if(data !== (writes%256) || led !== data) $fatal(1,"DAC ramp %0d",writes);
            if(cs_n!==0 || ldac_n!==0 || a_b!==channel) $fatal(1,"DAC controls");
            writes=writes+1;
        end
    end
    initial begin
        repeat(2) @(negedge clk); rst=0;
        wait(writes==130); @(negedge clk); channel=1;
        wait(writes==260); @(negedge clk); rst=1;
        @(posedge clk); #1;
        if(we_n!==1 || data!==0) $fatal(1,"DAC reset");
        $display("PASS DAC: 260 writes, wraparound, channel, data hold, reset"); $finish;
    end
    initial begin #100000; $fatal(1,"timeout"); end
endmodule
