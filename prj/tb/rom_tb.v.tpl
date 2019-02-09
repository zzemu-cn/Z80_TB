module <?=$modulename?> (
	input		[<?=$aw_?>:0]		adr,
	output		[<?=$dw_?>:0]		q,
	input					en
);

	// 内存
	reg		[<?=$dw_?>:0]	Mem	[0:<?=$MemSize_?>];

	initial $readmemh("<?=$datfile?>",Mem);

	// 读操作
	assign q = (en)?Mem[adr]:<?=$dw?>'bz;

endmodule
