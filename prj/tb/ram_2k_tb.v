module ram_2k_tb(
	input					clk,
	input		[10:0]		adr,
	input		[7:0]		data,
	output		[7:0]		q,
	input					we,
	input					en
);

	// 内存
	reg		[7:0]	Mem	[0:2047];

	//initial $readmemh("",Mem);

	// 写操作
	always @(posedge clk)
		if (en&&we)
			Mem[adr] <= data;

	// 读操作
	assign q = (en && ~we)?Mem[adr]:8'bz;

endmodule
