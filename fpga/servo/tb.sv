`timescale 1ns/1ps
module tb;
    initial begin $dumpfile("servo.vcd"); $dumpvars(0, tb); end
    reg clk=0,rst=1,l=0,r=0;
    always #5 clk=~clk;
    wire [31:0] us;
    wire servo;
    servo_position position_dut(clk,rst,l,r,us);
    servo_pwm #(.CLK_HZ(100000)) pwm_dut(clk,rst,us,servo);
    integer i,high_count;
    task step; begin @(posedge clk); #1; end endtask
    task press(input bit left_button,input bit right_button);
        begin
            @(negedge clk); l=left_button; r=right_button; step;
            @(negedge clk); l=0; r=0;
        end
    endtask
    task check_frame(input integer expected_high);
        begin
            // 폭이 적용된 새 프레임부터 한 프레임 전체를 셉니다.
            @(posedge servo); #1;
            high_count=0;
            for(i=0;i<2000;i=i+1) begin
                if(servo) high_count=high_count+1;
                step;
            end
            if(high_count != expected_high)
                $fatal(1,"servo width expected=%0d got=%0d",expected_high,high_count);
        end
    endtask
    initial begin
        step; if(us!==1500 || servo!==0) $fatal(1,"servo reset");
        @(negedge clk); rst=0;
        check_frame(150);
        repeat(8) press(1,0);
        if(us!==1000) $fatal(1,"left limit");
        check_frame(100);
        repeat(15) press(0,1);
        if(us!==2000) $fatal(1,"right limit");
        check_frame(200);
        press(1,1);
        if(us!==2000) $fatal(1,"both buttons");
        @(negedge clk); rst=1; step;
        if(us!==1500 || servo!==0) $fatal(1,"reset after running");
        $display("PASS servo: 20ms frame, 1/1.5/2ms pulse, limits, reset"); $finish;
    end
    initial begin #300000; $fatal(1,"timeout"); end
endmodule
