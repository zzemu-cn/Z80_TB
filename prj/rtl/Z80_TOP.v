`timescale 1 ns / 1 ns

`define		SIMULATE

// 选择 Z80 软核
//`define	TV80
//`define	NEXTZ80


module Z80_TOP(
	CLK50MHZ,

	BUTTON_N
);


input				CLK50MHZ;

input	[1:0]		BUTTON_N;
wire	[1:0]		BUTTON;
assign	BUTTON	=	~BUTTON_N;


// 10MHz 的频率用于模块计数， 包括产生 50HZ 的中断信号的时钟，uart 模块的时钟，模拟磁带模块的时钟
// 选择 10MHz 是因为 Cyclone II 的DLL 分频最多能到 5。最初打算用 1MHz。
reg					CLK10MHZ;
reg		[2:0]		CLK10MHZ_CNT;

`ifdef SIMULATE
initial
	begin
		CLK10MHZ		=	1'b0;
		CLK10MHZ_CNT	=	3'b0;
	end
`endif

always @(negedge CLK50MHZ)
	case(CLK10MHZ_CNT)
		3'd0:
		begin
			CLK10MHZ		<=	1'b1;
			CLK10MHZ_CNT	<=	3'd1;
		end
		3'd2:
		begin
			CLK10MHZ		<=	1'b0;
			CLK10MHZ_CNT	<=	3'd3;
		end
		3'd4:
		begin
			CLK10MHZ_CNT	<=	3'd0;
		end
		default:
			CLK10MHZ_CNT	<=	CLK10MHZ_CNT+1;
	endcase
		

	
// CLOCK & BUS
wire				BASE_CLK = CLK50MHZ;

reg		[3:0]		CLK;

reg					MEM_OP_WR;
//reg					MEM_RD;

// 50% 方波信号, 引出到 GPIO 端口
reg					GPIO_CPU_CLK;

// Processor
reg					CPU_CLK;

wire	[15:0]		CPU_A;
wire	[7:0]		CPU_DI;
wire	[7:0]		CPU_DO;

wire				CPU_RESET;
wire				CPU_HALT;
wire				CPU_WAIT;

wire				CPU_MREQ;
wire				CPU_RD;
wire				CPU_WR;
wire				CPU_IORQ;

reg					CPU_INT;
wire				CPU_NMI;
wire				CPU_M1;


wire				CPU_BUSRQ;
wire				CPU_BUSAK;

wire				CPU_RFSH;

`ifdef TV80

wire				CPU_RESET_N;
wire				CPU_HALT_N;
wire				CPU_WAIT_N;

wire				CPU_MREQ_N;
wire				CPU_RD_N;
wire				CPU_WR_N;
wire				CPU_IORQ_N;

wire				CPU_INT_N;
wire				CPU_NMI_N;
wire				CPU_M1_N;

wire				CPU_BUSRQ_N;
wire				CPU_BUSAK_N;

wire				CPU_RFSH_N;

`endif

// VRAM
wire	[12:0]		VRAM_ADDRESS;
wire				VRAM_WR;
wire	[7:0]		VRAM_DATA_OUT;

// ROM IO RAM
wire	[7:0]		SYS_ROM_DATA;

wire				RAM_16K_WR;
wire	[7:0]		RAM_16K_DATA_OUT;

wire				ADDRESS_ROM;
wire				ADDRESS_IO;
wire				ADDRESS_VRAM;

wire				ADDRESS_RAM_16K;


/*
74LS174输出的各个控制信号是：
Q5 蜂鸣器B端电平
Q4 IC15（6847）第39脚的CSS信号（控制显示基色）
Q3 IC15（6847）第35脚的~A/G信号（控制显示模式）
Q2 磁带记录信号电平
Q1 未用
Q0 蜂鸣器A端电平
*/

reg		[7:0]		LATCHED_IO_DATA_WR;

reg		[7:0]		LATCHED_KEY_DATA;

// speaker

wire	SPEAKER_A = LATCHED_IO_DATA_WR[0];
wire	SPEAKER_B = LATCHED_IO_DATA_WR[5];

// cassette

wire	[1:0]		CASS_OUT;
wire				CASS_IN;


// other
wire				RESET_N;

// reset
assign RESET_N = !BUTTON[0];



// 频率 50HZ
// 回扫周期暂定为：2线 x 800点 x 10MHZ / 25MHZ

// ~FS 垂直同步信号，送往IC1、IC2称IC4。6847对CPU的唯一直接影响，便是它的~FS输出被作为Z80A的~INT控制信号；
// 每一场扫描结束，6847的~FS信号变低，便向Z80A发出中断请求。在PAL制中，场频为50Hz，每秒就有50次中断请求，以便系统程序利用场消隐期运行监控程序，访问显示RAM。

// 在加速模式中，要考虑对该计数器的影响

// 系统中断：简化处理是直接接到 VGA 的垂直回扫信号，频率60HZ。带来的问题是软件计时器会产生偏差。

reg 		[17:0]	INT_CNT;

`ifdef SIMULATE
initial
	begin
		CPU_INT = 1'b0;
		INT_CNT = 18'd0;
	end
`endif

always @ (negedge CLK10MHZ)
	case(INT_CNT[17:0])
		18'd0:
		begin
			CPU_INT <= 1'b1;
			INT_CNT <= 18'd1;
		end
		18'd640:
		begin
			CPU_INT <= 1'b0;
			INT_CNT <= 18'd641;
		end
		18'd199999:
		begin
			INT_CNT <= 18'd0;
		end
		default:
		begin
			INT_CNT <= INT_CNT + 1;
		end
	endcase

// CPU clock

// 17.7MHz/5 = 3.54MHz
// LASER310 CPU：Z-80A/3.54MHz
// VZ300 CPU：Z-80A/3.54MHz

// 正常速度 50MHZ / 14 = 3.57MHz

// 同步内存操作
// 写 0 CPU 写信号和地址 1 锁存写和地址 2 完成写操作
// 读 0 CPU 读信号和地址 1 锁存读和地址 2 完读写操作，开始输出数据

// 读取需要中间间隔一个时钟


`ifdef SIMULATE
initial
	begin
		CLK			=	4'b0;
		CPU_CLK		=	1'b0;
	end
`endif

always @(posedge BASE_CLK or negedge RESET_N)
	if(~RESET_N)
	begin
		CPU_CLK					<=	1'b0;
		GPIO_CPU_CLK			<=	1'b0;


		MEM_OP_WR				<=	1'b0;

		LATCHED_KEY_DATA		<=	8'b0;
		LATCHED_IO_DATA_WR		<=	8'b0;

		CLK						<=	4'd0;
	end
	else
	begin
		case (CLK[3:0])
		4'd0:
			begin
				// 同步内存，等待读写信号建立
				CPU_CLK				<=	1'b1;
				GPIO_CPU_CLK		<=	1'b1;

				MEM_OP_WR			<=	1'b1;

				CLK					<=	4'd1;
			end

		4'd1:
			begin
				// 同步内存，锁存读写信号和地址
				CPU_CLK				<=	1'b0;
				MEM_OP_WR			<=	1'b0;

				LATCHED_KEY_DATA	<=	KEY_DATA;

				if({CPU_MREQ,CPU_RD,CPU_WR,ADDRESS_IO}==4'b1011)
					LATCHED_IO_DATA_WR	<=	CPU_DO;

				CLK					<=	4'd2;
			end

		4'd2:
			begin
				// 完成读写操作，开始输出
				CPU_CLK				<=	1'b0;

				MEM_OP_WR			<=	1'b0;

				CLK					<=	4'd3;
			end


		4'd7:
			begin
				CPU_CLK				<=	1'b0;
				GPIO_CPU_CLK		<=	1'b0;

				MEM_OP_WR			<=	1'b0;

				CLK					<=	4'd8;
			end

		// 正常速度
		4'd13:
			begin
				CPU_CLK				<=	1'b0;

				MEM_OP_WR			<=	1'b0;

				CLK					<=	4'd0;
			end
		default:
			begin
				CPU_CLK				<=	1'b0;

				MEM_OP_WR			<=	1'b0;

				CLK					<=	CLK + 1'b1;
			end
		endcase
	end

	//vga_pll vgapll(CLK50MHZ, VGA_CLOCK);
	/* This module generates a clock with half the frequency of the input clock.
	 * For the VGA adapter to operate correctly the clock signal 'clock' must be
	 * a 50MHz clock. The derived clock, which will then operate at 25MHz, is
	 * required to set the monitor into the 640x480@60Hz display mode (also known as
	 * the VGA mode).
	 */


wire [7:0] InPort = 8'b0;

// CPU

`ifdef NEXTZ80

`ifdef TV80

// 可以用来对比 NEXTZ80 和 TV80 的差别
wire	[15:0]		NEXT_CPU_A;
wire	[7:0]		NEXT_CPU_DO;
wire				NEXT_CPU_MREQ;
wire				NEXT_CPU_RD;
wire				NEXT_CPU_WR;
wire				NEXT_CPU_IORQ;
wire				NEXT_CPU_M1;

NextZ80 NEXT_Z80CPU (
	.DI(CPU_IORQ ? (NEXT_CPU_M1 ? 8'b00000000 : InPort) : CPU_DI),
	.DO(NEXT_CPU_DO),
	.ADDR(NEXT_CPU_A),
	.WR(NEXT_CPU_WR),
	.MREQ(NEXT_CPU_MREQ),
	.IORQ(NEXT_CPU_IORQ),
	.HALT(NEXT_CPU_HALT),
	.CLK(CPU_CLK),
	.RESET(CPU_RESET),
	.INT(CPU_INT),
	.NMI(CPU_NMI),
	.WAIT(CPU_WAIT),
	.M1(NEXT_CPU_M1)
);

`else

NextZ80 NEXT_Z80CPU (
	.DI(CPU_IORQ ? (CPU_M1 ? 8'b00000000 : InPort) : CPU_DI),
	.DO(CPU_DO),
	.ADDR(CPU_A),
	.WR(CPU_WR),
	.MREQ(CPU_MREQ),
	.IORQ(CPU_IORQ),
	.HALT(CPU_HALT),
	.CLK(CPU_CLK),
	.RESET(CPU_RESET),
	.INT(CPU_INT),
	.NMI(CPU_NMI),
	.WAIT(CPU_WAIT),
	.M1(CPU_M1)
);

assign CPU_RD = ~CPU_WR;

`endif

`endif


`ifdef TV80

assign CPU_M1 = ~CPU_M1_N;
assign CPU_MREQ = ~CPU_MREQ_N;
assign CPU_IORQ = ~CPU_IORQ_N;
assign CPU_RD = ~CPU_RD_N;
assign CPU_WR = ~CPU_WR_N;
assign CPU_RFSH = ~CPU_RFSH_N;
assign CPU_HALT= ~CPU_HALT_N;
assign CPU_BUSAK = ~CPU_BUSAK_N;

assign CPU_RESET_N = ~CPU_RESET;
assign CPU_WAIT_N = ~CPU_WAIT;
assign CPU_INT_N = ~CPU_INT;	// 50HZ
//assign CPU_INT_N = ~VGA_VS;	// 接 VGA 垂直回扫信号 60HZ
assign CPU_NMI_N = ~CPU_NMI;
assign CPU_BUSRQ_N = ~CPU_BUSRQ;


/*
  // Outputs
  m1_n, mreq_n, iorq_n, rd_n, wr_n, rfsh_n, halt_n, busak_n, A, dout,
  // Inputs
  reset_n, clk, wait_n, int_n, nmi_n, busrq_n, di
*/

tv80s Z80CPU (
	.m1_n(CPU_M1_N),
	.mreq_n(CPU_MREQ_N),
	.iorq_n(CPU_IORQ_N),
	.rd_n(CPU_RD_N),
	.wr_n(CPU_WR_N),
	.rfsh_n(CPU_RFSH_N),
	.halt_n(CPU_HALT_N),
	.busak_n(CPU_BUSAK_N),
	.A(CPU_A),
	.dout(CPU_DO),
	.reset_n(CPU_RESET_N),
	.clk(CPU_CLK),
	.wait_n(CPU_WAIT_N),
	.int_n(CPU_INT_N),
	.nmi_n(CPU_NMI_N),
	.busrq_n(CPU_BUSRQ_N),
	.di(CPU_IORQ_N ? CPU_DI : (CPU_M1_N ? InPort: 8'b00000000))
);

`endif

assign CPU_RESET = ~RESET_N;

assign CPU_NMI = 1'b0;

// LASER310 的 WAIT_N 始终是高电平。
assign CPU_WAIT = 1'b0;

//assign CPU_WAIT = CPU_MREQ && (~CLKStage[2]);


// 0000 -- 3FFF ROM 16KB
// 4000 -- 5FFF DOS
// 6000 -- 67FF BOOT ROM
// 6800 -- 6FFF I/O
// 7000 -- 77FF VRAM 2KB (SRAM 6116)
// 7800 -- 7FFF RAM 2KB
// 8000 -- B7FF RAM 14KB
// B800 -- BFFF RAM ext 2KB
// C000 -- F7FF RAM ext 14KB

assign ADDRESS_ROM			=	(CPU_A[15:14] == 2'b00)?1'b1:1'b0;
assign ADDRESS_IO			=	(CPU_A[15:11] == 5'b01101)?1'b1:1'b0;
assign ADDRESS_VRAM			=	(CPU_A[15:11] == 5'b01110)?1'b1:1'b0;

// 7800 -- 7FFF RAM 2KB
// 8000 -- B7FF RAM 14KB
assign ADDRESS_RAM_16K		=	(CPU_A[15:12] == 4'h8)?1'b1:
								(CPU_A[15:12] == 4'h9)?1'b1:
								(CPU_A[15:12] == 4'hA)?1'b1:
								(CPU_A[15:11] == 5'b01111)?1'b1:
								(CPU_A[15:11] == 5'b10110)?1'b1:
								1'b0;


assign VRAM_WR			= ({ADDRESS_VRAM,MEM_OP_WR,CPU_WR,CPU_IORQ} == 4'b1110)?1'b1:1'b0;

assign RAM_16K_WR		= ({ADDRESS_RAM_16K,MEM_OP_WR,CPU_WR,CPU_IORQ} == 4'b1110)?1'b1:1'b0;


assign CPU_DI = 	ADDRESS_ROM			? SYS_ROM_DATA		:
					ADDRESS_IO			? LATCHED_KEY_DATA	:
					ADDRESS_VRAM		? VRAM_DATA_OUT		:
					ADDRESS_RAM_16K		? RAM_16K_DATA_OUT	:
`ifdef SIMULATE
					8'b1;
`else
					8'bz;
`endif

rom_16k_tb sys_rom(
	.adr(CPU_A[13:0]),
	.en(1'b1),
	.q(SYS_ROM_DATA)
);


ram_2k_tb vram_2k(
	.adr(CPU_A[10:0]),
	.clk(BASE_CLK),
	.data(CPU_DO),
	.we(CPU_MREQ & VRAM_WR),
	.en(1'b1),
	.q(VRAM_DATA_OUT)
);


ram_16k_tb sys_ram_16k(
	.adr(CPU_A[13:0]),
	.clk(BASE_CLK),
	.data(CPU_DO),
	.we(CPU_MREQ & RAM_16K_WR),
	.en(1'b1),
	.q(RAM_16K_DATA_OUT)
);

/*****************************************************************************
* Video
******************************************************************************/
// Request for every other line to be black
// Looks more like the original video


// keyboard

/*****************************************************************************
* Convert PS/2 keyboard to ASCII keyboard
******************************************************************************/

/*
   KD5 KD4 KD3 KD2 KD1 KD0 扫描用地址
A0  R   Q   E       W   T  68FEH       0
A1  F   A   D  CTRL S   G  68FDH       8
A2  V   Z   C  SHFT X   B  68FBH      16
A3  4   1   3       2   5  68F7H      24
A4  M  空格 ，      .   N  68EFH      32
A5  7   0   8   -   9   6  68DFH      40
A6  U   P   I  RETN O   Y  68BFH      48
A7  J   ；  K   :   L   H  687FH      56
*/


// 键盘检测的方法，就是循环地问每一行线发送低电平信号，也就是用该地址线为“0”的地址去读取数据。
// 例如，检测第一行时，使A0为0，其余为1；加上选通IC4的高五位地址01101，成为01101***11111110B（A8~A10不起作用，
// 可为任意值，故68FEH，69FEH，6AFEH，6BFEH，6CFEH，6DFEH，6EFEH，6FFEH均可）。
// 读 6800H 判断是否有按键按下。

// 键盘选通，整个竖列有一个选通的位置被按下，对应值为0。

// 键盘扩展
// 加入方向键盘
// left:  ctrl M      37 KEY_EX[5]
// right: ctrl ,      35 KEY_EX[6]
// up:    ctrl .      33 KEY_EX[4]
// down:  ctrl space  36 KEY_EX[7]
// esc:   ctrl -      42 KEY_EX[3]
// backspace:  ctrl M      37 KEY_EX[8]

// R-Shift


wire KEY_DATA_BIT7 = 1'b1;	// 没有空置，具体用途没有理解
//wire KEY_DATA_BIT6 = CASS_IN;
wire KEY_DATA_BIT6 = ~CASS_IN;
wire KEY_DATA_BIT5 = 1'b1;
wire KEY_DATA_BIT4 = 1'b1;
wire KEY_DATA_BIT3 = 1'b1;
wire KEY_DATA_BIT2 = 1'b1;
wire KEY_DATA_BIT1 = 1'b1;
wire KEY_DATA_BIT0 = 1'b1;

assign KEY_DATA = { KEY_DATA_BIT7, KEY_DATA_BIT6, KEY_DATA_BIT5, KEY_DATA_BIT4, KEY_DATA_BIT3, KEY_DATA_BIT2, KEY_DATA_BIT1, KEY_DATA_BIT0 };

assign	CASS_OUT		=	{LATCHED_IO_DATA_WR[2], 1'b0};

assign	CASS_IN			=	1'b0;


endmodule
