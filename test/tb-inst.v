`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Wire up the inputs and outputs:
  reg clk = 0;
  reg rst_n = 1;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;
`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

	always #1 clk <= ~clk;

  tt_um_quick_cpu cpu (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(VPWR),
      .VGND(VGND),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

	initial begin
		// optionally overwrite the program in RAM
		//$readmemh("build/largest_divisor.hex", m.m.data);

		$monitor(
			"  uo_out ", uo_out,
			"  mc ", cpu.mc,
			"  pc ", cpu.pc,
			"  rst_n ", rst_n,
			""
		);

		for (integer i=0; i<50; i=i+1) begin
			if (i==5) rst_n<=0;
			if (i==10) rst_n<=1;
			//if (halted) $finish();
			@(posedge clk);
		end
		$display("INSTRUCTION TEST LIMIT REACHED!");
		$finish();
	end


endmodule
