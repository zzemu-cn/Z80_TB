module <?=$modulename?>(
	input					clk,
	input		[<?=$aw_?>:0]		adr,
	input		[<?=$dw_?>:0]		data,
	output		[<?=$dw_?>:0]		q,
	input					we,
	input					en
);

	// 内存
	reg		[<?=$dw_?>:0]	Mem	[0:<?=$MemSize_?>];

	//initial $readmemh("<?=$datfile?>",Mem);

	// 写操作
	always @(posedge clk)
		if (en&&we)
			Mem[adr] <= data;

	// 读操作
	assign q = (en && ~we)?Mem[adr]:<?=$dw?>'bz;

endmodule
