`timescale 1ns/1ps
module sram(
    input wire ctrl_w,ctrl_r,
    input wire [3:0] address,data_in,
    output wire ram_cs,ram_oe,ram_we,
    output wire [17:0] ram_address,
    inout wire [15:0] ram_data,
    output wire [7:0] led_out
);
    wire drive_data,read_data;
    sram_bus_control u_control(ctrl_w,ctrl_r,drive_data,read_data,ram_cs,ram_oe,ram_we);
    assign ram_address={14'b0,address};
    assign ram_data=drive_data ? {12'b0,data_in} : 16'bz;
    assign led_out=read_data ? {4'b0,ram_data[3:0]} : 8'b0;
endmodule

`timescale 1ns/1ps
// SRAM 버스는 읽을 때 FPGA가 구동하지 않고 Z 상태로 놓습니다.
// ctrl_w와 ctrl_r가 동시에 들어오면 둘 다 수행하지 않습니다.
module sram_bus_control(
    input wire ctrl_w,ctrl_r,
    output wire drive_data,read_data,
    output wire ram_cs,ram_oe,ram_we
);
    assign drive_data=ctrl_w && !ctrl_r;
    assign read_data=ctrl_r && !ctrl_w;
    assign ram_cs=!(drive_data || read_data);
    assign ram_oe=!read_data;
    assign ram_we=!drive_data;
endmodule
