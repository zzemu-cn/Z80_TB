module rom_16k_tb (
	input		[13:0]		adr,
	output		[7:0]		q,
	input					en
);

	// 内存
	reg		[7:0]	Mem	[0:16383];

	initial $readmemh("tb/ROM.d",Mem);

	// 读操作
	assign q = (en)?Mem[adr]:8'bz;

endmodule
