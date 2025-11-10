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
  assign uio_oe  = 8'b00000011;

  wire mem_read;
  wire mem_write;
  //reg mem_read;
  assign uio_out[0] = mem_read;
  assign uio_out[1] = mem_write;

  // instruction
  reg[7:0] pc;    // program counter
  reg[1:0] mc;    // micro instruction counter
  reg[7:0] instr; // current instruction
  //reg[7:0] micro; // current micro instruction
  reg[7:0] reg_a;
  reg[7:0] reg_b;
  reg[7:0] reg_c;
  reg[7:0] reg_d;

  // micro instruction cycle:
  //   0. set ou_out to value of pc
  //      set memory_read to 1
  //   1. read value ui_in into instr
  //      set memory_read to 0
  // then:
  //
  // load instruction:
  //    load reg_a, [reg_b]  # load value at address [reg_b] into reg_a
  //    micro:
  //       2. set ou_out to value of reg_b
  //          set memory_read to 1
  //       3. read value of ui_in into reg_a
  // store instruction:
  //    store [reg_b], reg_a
  //    micro:
  //       2. set ou_out to value of reg_b
  //          set memory_write to 1
  //       3. set ou_out to value of reg_a
  //          set memory_write to 0
  // add instruction:
  //    add reg_left, reg_right
  //    micro:
  //       2. reg_left <= reg_left + reg_right
  // sub instruction:
  //    sub reg_left, reg_right
  //    micro:
  //       2. reg_left <= reg_left - reg_right

  // 0000leri load [ri] into le
  // 0001leri store le into [ri]
  // 0010leri le = le-ri
  // 0011leri le = le+ri
  // 0100leri le==0: jmp to ri

  wire[7:0] left_bus =
        instr[3:2] == 0 ? reg_a
      : instr[3:2] == 1 ? reg_b
      : instr[3:2] == 2 ? reg_c
      : reg_d;
  wire[7:0] right_bus =
        instr[1:0] == 0 ? reg_a
      : instr[1:0] == 1 ? reg_b
      : instr[1:0] == 2 ? reg_c
      : reg_d;
  wire[7:0] result =
      (instr[7:4] == 4'b0010) ? left_bus - right_bus
    //: instr[7:4] == 4'b0011) ? left_bus + right_bus
    : left_bus + right_bus;

  assign uo_out = (mc == 0) ? pc
    : (mc == 2 && instr[7:5] == 3'b000) ? right_bus // load/store
    : (mc == 3 && instr[7:4] == 4'b0001) ? left_bus // store
    : 0;

  assign mem_read = (mc == 0) ||
      (mc == 2 && instr[7:4] == 4'b0000); // load

  assign mem_write =
      (mc == 2 && instr[7:4] == 4'b0001); // store

  always @(negedge rst_n or posedge clk) begin
    if (~rst_n) begin
      pc <= 0;
      mc <= 0;
      instr <= 0;
      reg_a <= 0;
      reg_b <= 0;
      reg_c <= 0;
      reg_d <= 0;
    end else begin
      if (mc == 3) begin
        mc <= 0;
        pc <= pc + 1;
      end else begin
        mc <= mc + 1;
      end
      if (mc == 0) begin // coming from 0 to 1
        instr <= ui_in;
      end
      if (mc == 2) begin // coming from 2 to 3
        if (instr[7:4] == 4'b0000) begin
          case (instr[3:2])
            0: reg_a <= ui_in;
            1: reg_b <= ui_in;
            2: reg_c <= ui_in;
            3: reg_d <= ui_in;
          endcase
        end else if (instr[7:5] == 4'b001) begin // add/sub
          case (instr[3:2])
            0: reg_a <= result;
            1: reg_b <= result;
            2: reg_c <= result;
            3: reg_d <= result;
          endcase
        end
      end
    end
  end

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, uio_in};

endmodule
