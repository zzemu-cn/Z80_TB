`timescale 1 ns / 1 ns

module top_tb;

reg				CLK50MHZ;

reg [1:0]		BUTTON_N;			//  0 RESET
									//  1 Not used

parameter period = 20;

initial
	begin
        CLK50MHZ = 0;
        #(period)
        forever
        	#(period/2) CLK50MHZ = !CLK50MHZ;
	end

initial
	begin
        #500000 $finish;
	end


initial
	begin
		BUTTON_N = 2'b10;
		#100 BUTTON_N = 2'b11;
	end


initial
begin
        $dumpfile("z80sys.dump");
        $dumpvars(0, DUT);
end


Z80_TOP DUT(
	CLK50MHZ,
	// Extra Buttons and Switches
	BUTTON_N
);

endmodule
