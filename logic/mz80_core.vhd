--
-- mz80_core.vhd
--
-- SHARP MZ-80 series compatible logic, main module
-- for Altera DE0
--
-- Nibbles Lab. 2012
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mz80_core is
  port(
		-- Core I/O
		RST_x			: in std_logic;
		ZCLK			: out std_logic;
		A				: out std_logic_vector(15 downto 0);
		RAMDO			: out std_logic_vector(7 downto 0);
		RAMDI			: in std_logic_vector(7 downto 0);
		MWR_x			: out std_logic;
		BREQ			: in std_logic;
		BACK			: out std_logic;
		RAMCS_x		: out std_logic;
		MZMODE 		: in std_logic_vector(1 downto 0);		-- Hardware Mode
		DMODE  		: in std_logic_vector(1 downto 0);		-- Display Mode
		KBEN			: in std_logic;								-- Key Data Valid
		KBDT			: in std_logic_vector(7 downto 0);		-- Key Code
		-- BackDoor for Sub-Processor
		NCLK			: in std_logic;								-- NiosII Clock
		NA				: in std_logic_vector(15 downto 0);		-- NiosII Address Bus
		NCS_x			: in std_logic;								-- NiosII Memory Request
		NWR_x			: in std_logic;								-- NiosII Write Signal
		NDI			: in std_logic_vector(7 downto 0);		-- NiosII Data Bus(in)
		NDO			: out std_logic_vector(7 downto 0);		-- NiosII Data Bus(out)
		-- Clock Input	 
		CLOCK_50		: in std_logic;								--	50 MHz
		-- Tape Signals
		SENSE			: in std_logic;								--	Pushbutton[2]
		MOTOR			: out std_logic;								-- Motor On
		RBIT			: in std_logic;								--	Read Data
		-- DPDT Switch
		SW				: in std_logic_vector(5 downto 0);		--	Toggle Switch[5:0]
		-- LED
		LEDG			: out std_logic_vector(9 downto 0);		--	LED Green[9:0]
		-- VGA
		VGA_HS		: out std_logic;								--	VGA H_SYNC
		VGA_VS		: out std_logic;								--	VGA V_SYNC
		VGA_R			: out std_logic_vector(3 downto 0);   	--	VGA Red[3:0]
		VGA_G			: out std_logic_vector(3 downto 0);	 	--	VGA Green[3:0]
		VGA_B			: out std_logic_vector(3 downto 0);  	--	VGA Blue[3:0]
		-- GPIO
		GPIO0_CLKIN	: in std_logic_vector(1 downto 0);		--	GPIO Connection 0 Clock In Bus
		GPIO0_CLKOUT: out std_logic_vector(1 downto 0);		--	GPIO Connection 0 Clock Out Bus
		GPIO0_D		: out std_logic_vector(31 downto 0);	--	GPIO Connection 0 Data Bus
		GPIO1_CLKIN	: in std_logic_vector(1 downto 0);		--	GPIO Connection 1 Clock In Bus
		GPIO1_CLKOUT: out std_logic_vector(1 downto 0);		--	GPIO Connection 1 Clock Out Bus
		GPIO1_D		: inout std_logic_vector(31 downto 0)	--	GPIO Connection 1 Data Bus
  );
end mz80_core;

architecture rtl of mz80_core is

--
-- T80
--
signal MREQ : std_logic;
signal IORQ : std_logic;
signal WR : std_logic;
signal RD : std_logic;
signal MWR : std_logic;
signal MRD : std_logic;
signal M1 : std_logic;
signal RFSH : std_logic;
signal A16 : std_logic_vector(15 downto 0);
signal DO : std_logic_vector(7 downto 0);
signal DI : std_logic_vector(7 downto 0);
--signal ROMDO : std_logic_vector(7 downto 0);
signal MEMDO : std_logic_vector(15 downto 0);
signal BAK : std_logic;
--
-- Clocks
--
signal CK2M : std_logic;
signal CK8M : std_logic;
signal CK12M5 : std_logic;
signal CK3125 : std_logic;
signal SCLK : std_logic;
signal HCLK : std_logic;
signal CASCADE : std_logic;
--
-- Decodes, misc
--
signal CSE_x : std_logic;
signal CSE2_x : std_logic;
signal DO367 : std_logic_vector(7 downto 0);
signal BUF : std_logic_vector(9 downto 0);
signal CSMROM : std_logic;
signal ARST : std_logic;
signal MRST : std_logic;
--
-- SDRAM
--
signal MEMCLK : std_logic;
signal SDRAMDO : std_logic_vector(15 downto 0);
signal SDRAMDOE : std_logic;
signal CSRAM : std_logic;
--
-- Video
--
signal HBLNK : std_logic;
signal VBLNK : std_logic;
signal HSYNCi : std_logic;
signal HSYNC : std_logic;
signal VSYNC : std_logic;
signal Ri : std_logic;
signal Gi : std_logic;
signal Bi : std_logic;
signal R : std_logic;
signal G : std_logic;
signal B : std_logic;
signal VGATE : std_logic;
signal CSD_x : std_logic;
signal VRAMDO : std_logic_vector(7 downto 0);
--
-- PPI
--
signal CSE0_x : std_logic;
signal DOPPI : std_logic_vector(7 downto 0);
signal EIKANA : std_logic;
--
-- PIT
--
signal CSE1_x : std_logic;
signal DOPIT : std_logic_vector(7 downto 0);
signal SOUNDEN : std_logic;
signal SPKOUT : std_logic;
signal XSPKOUT : std_logic;
signal INT : std_logic;
signal INTX : std_logic;
--
-- for Debug
--
signal LDDAT : std_logic_vector(7 downto 0);

--
-- Components
--
component T80s
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	Port(
		RESET_n	: in std_logic;
		CLK_n		: in std_logic;
		WAIT_n	: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n	: in std_logic;
		M1_n		: out std_logic;
		MREQ_n	: out std_logic;
		IORQ_n	: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n	: out std_logic;
		HALT_n	: out std_logic;
		BUSAK_n	: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0)
	);
end component;

component i8255
	Port (
		RST    : in std_logic;
		CLK    : in std_logic;
      A      : in std_logic_vector(1 downto 0);
		CS     : in std_logic;
		WR     : in std_logic;
		DI     : in std_logic_vector(7 downto 0);
		DO     : out std_logic_vector(7 downto 0);
		-- Port A&B
		KBEN   : in std_logic;								-- PS/2 Keyboard Data Valid
		KBDT   : in std_logic_vector(7 downto 0);		-- PS/2 Keyboard Data
		KCLK   : in std_logic;								-- Key controller base clock
		-- Port C
		CLKIN  : in std_logic;								-- Cursor Blink signal
--		FCLK   : in std_logic;
		VBLNK  : in std_logic;								-- V-BLANK signal
		EIKANA : out std_logic;								-- EISUU/KANA LED
		VGATE  : out std_logic;								-- Video Outpu Enable
		RBIT   : in std_logic;								-- Read Tape Bit
		SENSE  : in std_logic;								-- Tape Rotation Sense
		MOTOR  : out std_logic;								-- CMT Motor ON
		-- for Debug
		LDDAT  : out std_logic_vector(7 downto 0);
--		LDDAT2 : out std_logic;
--		LDSNS  : out std_logic;
		-- BackDoor for Sub-Processor
		NCLK	 : in std_logic;								-- NiosII Clock
		NA		 : in std_logic_vector(15 downto 0);	-- NiosII Address Bus
		NCS_x  : in std_logic;								-- NiosII Memory Request
		NWR_x	 : in std_logic;								-- NiosII Write Signal
		NDI	 : in std_logic_vector(7 downto 0)		-- NiosII Data Bus(in)
	);
end component;

component i8253
   Port (
		RST : in std_logic;
		CLK : in std_logic;
		A : in std_logic_vector(1 downto 0);
		DI : in std_logic_vector(7 downto 0);
		DO : out std_logic_vector(7 downto 0);
		CS : in std_logic;
		WR : in std_logic;
		RD : in std_logic;
		CLK0 : in std_logic;
		GATE0 : in std_logic;
		OUT0 : out std_logic;
		CLK1 : in std_logic;
		GATE1 : in std_logic;
		OUT1 : out std_logic;
		CLK2 : in std_logic;
		GATE2 : in std_logic;
		OUT2 : out std_logic
	);
end component;

component videoout is
    Port (
		RST    : in std_logic;		-- Reset
		MZMODE : in std_logic_vector(1 downto 0);		-- Hardware Mode
		DMODE  : in std_logic_vector(1 downto 0);		-- Display Mode
		PCGSW  : in std_logic;		-- PCG Mode
		-- Clocks
		CK50M  : in std_logic;		-- Master Clock(50MHz)
		CK12M5 : out std_logic;		-- VGA Clock(12.5MHz)
		CK8M   : out std_logic;		-- 15.6kHz Dot Clock(8MHz)
		CK2M   : out std_logic;		-- CPU/CLOCK Clock(2MHz)
		CK3125 : out std_logic;		-- Music Base Clock(31.25kHz)
		-- CPU Signals
		A      : in std_logic_vector(11 downto 0);	-- CPU Address Bus
		CSD_x  : in std_logic;								-- CPU Memory Request(VRAM)
		CSE_x  : in std_logic;								-- CPU Memory Request(Control)
		RD_x   : in std_logic;								-- CPU Read Signal
		WR_x   : in std_logic;								-- CPU Write Signal
		DI     : in std_logic_vector(7 downto 0);		-- CPU Data Bus(in)
		DO     : out std_logic_vector(7 downto 0);	-- CPU Data Bus(out)
		-- Video Signals
		VGATE  : in std_logic;		-- Video Output Control
		HBLANK : out std_logic;		-- Horizontal Blanking
		VBLANK : out std_logic;		-- Vertical Blanking
		HSYNC  : out std_logic;		-- Horizontal Sync
		VSYNC  : out std_logic;		-- Vertical Sync
		ROUT   : out std_logic;		-- Red Output
		GOUT   : out std_logic;		-- Green Output
		BOUT   : out std_logic;		-- Green Output
		-- BackDoor for Sub-Processor
		NCLK	 : in std_logic;								-- NiosII Clock
		NA		 : in std_logic_vector(15 downto 0);	-- NiosII Address Bus
		NCS_x  : in std_logic;								-- NiosII Memory Request
		NWR_x	 : in std_logic;								-- NiosII Write Signal
		NDI	 : in std_logic_vector(7 downto 0);		-- NiosII Data Bus(in)
		NDO	 : out std_logic_vector(7 downto 0);	-- NiosII Data Bus(out)
		BACK	 : in std_logic								-- Z80 Bus Acknowlegde
	);
end component;

component ScanConv
	Port (
		CK8M   : in STD_LOGIC;		-- MZ Dot Clock
		CK12M5 : in STD_LOGIC;		-- VGA Dot Clock
		RI     : in STD_LOGIC;		-- Red Input
		GI     : in STD_LOGIC;		-- Green Input
		BI     : in STD_LOGIC;		-- Blue Input
		HSI    : in STD_LOGIC;		-- H-Sync Input(MZ,15.6kHz)
		RO     : out STD_LOGIC;		-- Red Output
		GO     : out STD_LOGIC;		-- Green Output
		BO     : out STD_LOGIC;		-- Blue Output
		HSO    : out STD_LOGIC		-- H-Sync Output(VGA, 31kHz)
	);
end component;

component ls367
   Port (
		RST : in std_logic;
		CLKIN : in std_logic;
		CLKOUT : out std_logic;
		GATE : out std_logic;
		CS : in std_logic;
		WR : in std_logic;
		DI : in std_logic_vector(7 downto 0);
		DO : out std_logic_vector(7 downto 0)
	);
end component;

begin

	--
	-- Instantiation
	--
	CPU0 : T80s port map (
		RESET_n => RST_x,
		CLK_n => CK2M,
		WAIT_n => '1',		--ZWAIT,
		INT_n => INT,
		NMI_n => '1',
		BUSRQ_n => BREQ,
		M1_n => M1,
		MREQ_n => MREQ,
		IORQ_n => IORQ,
		RD_n => RD,
		WR_n => WR,
		RFSH_n => open,	--RFSH,
		HALT_n => open,
		BUSAK_n => BAK,
		A => A16,
		DI => DI,
		DO => DO
	);

	PPI0 : i8255 port map (
		RST => RST_x,
		CLK => CK2M,
		A => A16(1 downto 0),
		CS => CSE0_x,
		WR => WR,
		DI => DO,
		DO => DOPPI,
		-- Port A&B
		KBEN => KBEN,								-- PS/2 Keyboard Data Valid
		KBDT => KBDT,								-- PS/2 Keyboard Data
		KCLK => CK2M,								-- Key controller base clock
		-- Port C
		CLKIN => SCLK,								-- Cursor Blink signal
--		FCLK => NTSCCLK,
		VBLNK => VBLNK,							-- V-BLANK signal
		EIKANA => EIKANA,							-- EISUU/KANA LED
		VGATE => VGATE,							-- Video Outpu Enable
		RBIT => RBIT,								-- Read Tape Bit
		SENSE => SENSE,							-- Tape Rotation Sense
		MOTOR => MOTOR,							-- CMT Motor ON
		-- for Debug
		LDDAT => LDDAT,
--		LDDAT2 => LD(5),
--		LDSNS => LD(6),
		-- BackDoor for Sub-Processor
		NCLK => NCLK,								-- NiosII Clock
		NA => NA,									-- NiosII Address Bus
		NCS_x => NCS_x,							-- NiosII Memory Request
		NWR_x => NWR_x,							-- NiosII Write Signal
		NDI => NDI									-- NiosII Data Bus(in)
	);

	PIT0 : i8253 port map (
		RST => RST_x,
		CLK => CK2M,
		A => A16(1 downto 0),
		DI => DO,
		DO => DOPIT,
		CS => CSE1_x,
		WR => WR,
		RD => RD,
		CLK0 => CK2M,
		GATE0 => SOUNDEN,
		OUT0 => SPKOUT,
		CLK1 => CK3125,
		GATE1 => '1',
		OUT1 => CASCADE,
		CLK2 => CASCADE,
		GATE2 => '1',
		OUT2 => INTX
	);

	VIDEO0 : videoout Port map (
		RST => RST_x,				-- Reset
		MZMODE => MZMODE,			-- Hardware Mode
		DMODE => DMODE,			-- Display Mode
		PCGSW => SW(0),			-- PCG Mode
		-- Clocks
		CK50M => CLOCK_50,		-- Master Clock(50MHz)
		CK12M5 => CK12M5,			-- VGA Clock(12.5MHz)
		CK8M => CK8M,				-- 15.6kHz Dot Clock(8MHz)
		CK2M => CK2M,				-- CPU/CLOCK Clock(2MHz)
		CK3125 => CK3125,			-- Music Base Clock(31.25kHz)
		-- CPU Signals
		A => A16(11 downto 0),	-- CPU Address Bus
		CSD_x => CSD_x,			-- CPU Memory Request(VRAM)
		CSE_x => CSE_x,			-- CPU Memory Request(Control)
		RD_x => RD,					-- CPU Read Signal
		WR_x => WR,					-- CPU Write Signal
		DI => DO,					-- CPU Data Bus(in)
		DO => VRAMDO,				-- CPU Data Bus(out)
		-- Video Signals
		VGATE => VGATE,			-- Video Output Control
		HBLANK => HBLNK,			-- Horizontal Blanking
		VBLANK => VBLNK,			-- Vertical Blanking
		HSYNC => HSYNCi,			-- Horizontal Sync
		VSYNC => VSYNC,			-- Vertical Sync
		ROUT => Ri,					-- Red Output
		GOUT => Gi,					-- Green Output
		BOUT => Bi,					-- Blue Output
		-- BackDoor for Sub-Processor
		NCLK => NCLK,				-- NiosII Clock
		NA => NA,					-- NiosII Address Bus
		NCS_x => NCS_x,			-- NiosII VRAM Request
		NWR_x => NWR_x,			-- NiosII Write Signal
		NDI => NDI,					-- NiosII Data Bus(in)
		NDO => NDO,					-- NiosII Data Bus(out)
		BACK => BAK					-- Z80 Bus Acknowlegde
	);

	SCONV0 : ScanConv Port map (
		CK8M => CK8M,			-- MZ Dot Clock
		CK12M5 => CK12M5,		-- VGA Dot Clock
		RI => Ri,				-- Red Input
		GI => Gi,				-- Green Input
		BI => Bi,				-- Blue Input
		HSI => HSYNCi,			-- H-Sync Input(MZ,15.6kHz)
		RO => R,					-- Red Output
		GO => G,					-- Green Output
		BO => B,					-- Blue Output
		HSO => HSYNC			-- H-Sync Output(VGA, 31kHz)
	);

	GPIO0 : ls367 port map (
		RST => RST_x,
		CLKIN => CK2M,
		CLKOUT => SCLK,
		GATE => SOUNDEN,
		CS => CSE2_x,
		WR => WR,
		DI => DO,
		DO => DO367
	);

	--
	-- Control Signals
	--
	MRD<=MREQ or RD;
	MWR<=MREQ or WR;

	--
	-- Data Bus
	--
	DI <=	DOPPI when CSE0_x='0' else
			DOPIT when CSE1_x='0' else
			DO367 when CSE2_x='0' else
			VRAMDO when CSD_x='0' else
			--ROMDO when CSMROM='0' else
			RAMDI when CSRAM='0' else (others=>'0');

	--
	-- Chip Select
	--
	CSE_x <='0' when A16(15 downto 12)="1110" and MREQ='0' else '1';
	CSE0_x<='0' when CSE_x='0' and A16(4 downto 2)="000" and ((A16(11) or A16(10) or A16(9)) and MZMODE(1))='0' else '1';
	CSE1_x<='0' when CSE_x='0' and A16(4 downto 2)="001" and ((A16(11) or A16(10) or A16(9)) and MZMODE(1))='0' else '1';
	CSE2_x<='0' when CSE_x='0' and A16(4 downto 2)="010" and ((A16(11) or A16(10) or A16(9)) and MZMODE(1))='0' else '1';
	--CSE3_x<='0' when CSE_x='0' and A16(4 downto 2)="011" and ((A16(11) or A16(10) or A16(9)) and MZMODE(1))='0' else '1';
	CSD_x<='0' when A16(15 downto 12)="1101" and MREQ='0' else '1';
	--CSMROM<='0' when A16(15 downto 12)="0000" and MREQ='0' else '1';
	CSRAM<='0' when ( A16(15)='0' or A16(15 downto 14)="10" or A16(15 downto 12)="1100" or A16(15 downto 12)="1111" or (A16(15 downto 11)="11101" and MZMODE(1)='1') ) and MREQ='0' else '1';

	--
	-- Video Output
	--
	VGA_HS<=HSYNC;
	VGA_VS<=VSYNC;
	VGA_R<=R&R&R&R;
	VGA_G<=G&G&G&G;
	VGA_B<=B&B&B&B;

	--
	-- Ports
	--
	ZCLK<=CK2M;
	A<=A16;
	BACK<=BAK;
	RAMDO<=DO;
	RAMCS_x<=CSRAM;
	MWR_x<='1' when A16(15 downto 12)="0000" or A16(15 downto 12)="1111" or A16(15 downto 11)="11101" else MWR;

	--
	-- Misc
	--
	INT<=not INTX;
	process( SPKOUT ) begin
		if( SPKOUT'event and SPKOUT='1' ) then
			XSPKOUT<=not XSPKOUT;
		end if;
	end process;

	GPIO1_D(14)<=XSPKOUT;	-- Sound Output
	GPIO1_D(15)<=XSPKOUT;

	LEDG(9 downto 3)<=(others=>'0');
	LEDG(2)<=GPIO1_D(0);
	LEDG(1 downto 0)<="00" when MZMODE(1)='1' else
							"10" when EIKANA='1' else "01";

end rtl;
