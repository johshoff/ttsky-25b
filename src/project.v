/*
 * Copyright (c) 2025 Johannes Hoff
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_quick_cpu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  assign uio_out = 0;
  assign uio_oe  = 0;

  // instruction
  reg[7:0] pc;
  reg[7:0] inst;
  reg[7:0] reg_a;
  reg[7:0] reg_b;
  reg rst;

  assign uo_out = inst == 0 ? reg_a
    : inst == 1 ? reg_b
    : 0;

  always @(negedge rst_n or posedge clk) begin
    rst <= ~rst_n;
  end

  always @(posedge clk) begin
    if (rst) begin
      pc <= 0;
      inst <= 0;
      reg_a <= 0;
      reg_b <= 1;
    end else begin
      pc <= pc + 1;
      inst <= inst + 1;
    end
  end

  // List all unused inputs to prevent warnings
  wire _unused = &{ena};

endmodule
