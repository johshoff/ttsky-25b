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
  reg[7:0] pc;    // program counter
  reg[1:0] mc;    // micro instruction counter
  reg[7:0] instr; // current instruction
  //reg[7:0] micro; // current micro instruction
  reg[7:0] reg_a;
  reg[7:0] reg_b;

  // micro instruction cycle:
  //   0. set ou_out to value of pc
  //      set memory_read to 1
  //   1. read value ui_in into instr
  //   2. set memory_read to 0
  // then:
  //
  // load instruction:
  //    load reg_a, [reg_b]  # load value at address [reg_b] into reg_a
  //    micro:
  //       2. set ou_out to value of reg_b
  //          set memory_read to 1
  //       3. read value of ui_in into reg_a

  assign uo_out = (mc == 0 || mc == 1) ? pc
    : 0;

  always @(negedge rst_n or posedge clk) begin
    if (~rst_n) begin
      pc <= 0;
      mc <= 0;
      instr <= 0;
      reg_a <= 0;
      reg_b <= 1;
    end else begin
      if (mc == 3) begin
        mc <= 0;
        pc <= pc + 1;
      end else begin
        mc <= mc + 1;
      end
      if (mc == 1) begin
        instr <= ui_in;
      end
    end
  end

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in};

endmodule
