--
-- videoout.vhd
--
-- Video display signal generator
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity videoout is
	Port (
		RST    : in std_logic;		-- Reset
		MZMODE : in std_logic_vector(1 downto 0);		-- Hardware Mode
		DMODE  : in std_logic_vector(1 downto 0);		-- Display Mode
		PCGSW  : in std_logic;		-- PCG Mode
		-- Clocks
		CK50M  : in std_logic;		-- Master Clock(50MHz)
		CK12M5 : out std_logic;		-- VGA Clock(12.5MHz)
		CK8M   : out std_logic;		-- 15.6kHz Dot Clock(8MHz)
		CK4M   : out std_logic;		-- CPU/CLOCK Clock(4MHz)
		CK3125 : out std_logic;		-- Music Base Clock(31.25kHz)
		ZCLK   : in std_logic;		-- Z80 Clock
		-- CPU Signals
		A      : in std_logic_vector(11 downto 0);	-- CPU Address Bus
		CSD_x  : in std_logic;								-- CPU Memory Request(VRAM)
		CSE_x  : in std_logic;								-- CPU Memory Request(Control)
		RD_x   : in std_logic;								-- CPU Read Signal
		WR_x   : in std_logic;								-- CPU Write Signal
		MREQ_x : in std_logic;								-- CPU Memory Request
		WAIT_x : out std_logic;								-- CPU Wait Request
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
		BOUT   : out std_logic;		-- Blue Output
		-- BackDoor for Sub-Processor
		NCLK	 : in std_logic;								-- NiosII Clock
		NA		 : in std_logic_vector(15 downto 0);	-- NiosII Address Bus
		NCS_x : in std_logic;								-- NiosII Memory Request
		NWR_x	 : in std_logic;								-- NiosII Write Signal
		NDI	 : in std_logic_vector(7 downto 0);		-- NiosII Data Bus(in)
		NDO	 : out std_logic_vector(7 downto 0);	-- NiosII Data Bus(out)
		BACK	 : in std_logic								-- Z80 Bus Acknowlegde
	);
end videoout;

architecture RTL of videoout is

--
-- Clocks
--
signal CK8Mi   : std_logic;	-- 8MHz
--signal CK2Mi   : std_logic;	-- 2MHz
--
-- Registers
--
signal DIV      : std_logic_vector(8 downto 0);		-- Clock Divider
signal HCOUNT   : std_logic_vector(8 downto 0);		-- Counter for Horizontal Signals
signal VCOUNT   : std_logic_vector(8 downto 0);		-- Counter for Vertical Signals
signal VADR     : std_logic_vector(10 downto 0);	-- VRAM Address(selected)
signal VADRO    : std_logic_vector(10 downto 0);	-- VRAM Address(selected, offseted)
signal VADRC    : std_logic_vector(10 downto 0);	-- VRAM Address
signal VADRL    : std_logic_vector(10 downto 0);	-- VRAM Address(latched)
signal OFST     : std_logic_vector(7 downto 0);		-- VRAM Offset
signal SDAT     : std_logic_vector(7 downto 0);		-- Shift Register to Display
signal ADAT     : std_logic_vector(7 downto 0);		-- Color Attribute(B-in Color)
signal CDAT     : std_logic_vector(7 downto 0);		-- Color Attribute(ColorGal5)
signal ADATi    : std_logic_vector(7 downto 0);		-- Color Attribute(B-in Color, before confrict)
signal CDATi    : std_logic_vector(7 downto 0);		-- Color Attribute(ColorGal5, before confrict)
--
-- CPU Access
--
signal MA       : std_logic_vector(11 downto 0);	-- Masked Address
signal CSV_x    : std_logic;								-- Chip Select (VRAM)
signal CSA_x    : std_logic;								-- Chip Select (ARAM)
signal CSINV_x  : std_logic;								-- Chip Select (Reverse)
signal CSCG5_x  : std_logic;								-- Chip Select (ColorGal5)
signal CSSCL_x  : std_logic;								-- Chip Select (Hardware Scroll)
signal NCSV_x   : std_logic;								-- Chip Select (VRAM, NiosII)
signal NCSA_x   : std_logic;								-- Chip Select (ARAM, NiosII)
signal VWEN     : std_logic;								-- WR + MREQ (VRAM)
signal AWEN     : std_logic;								-- WR + MREQ (ARAM)
signal NWEN0    : std_logic;								-- WR + CS (VRAM, NiosII)
signal NWEN1    : std_logic;								-- WR + CS (ARAM, NiosII)
signal WAITi_x  : std_logic;								-- Wait
signal WAITii_x : std_logic;								-- Wait(delayed)
--
-- Internal Signals
--
signal HDISPEN : std_logic;							-- Display Enable for Horizontal, almost same as HBLANK
signal HBLANKi : std_logic;							-- Horizontal Blanking
signal BLNK		: std_logic;							-- Horizontal Blanking (for wait)
signal XBLNK	: std_logic;							-- Horizontal Blanking (for wait)
signal CPUENi	: std_logic;							-- Address Select w/wait control
signal CPUEN	: std_logic;							-- Address Select w/wait control
signal VDISPEN : std_logic;							-- Display Enable for Vertical, same as VBLANK
signal MB		: std_logic;							-- Display Signal (Mono, Blue)
signal MG		: std_logic;							-- Display Signal (Mono, Green)
signal MR		: std_logic;							-- Display Signal (Mono, Red)
signal BB		: std_logic;							-- Display Signal (B-in, Blue)
signal BG		: std_logic;							-- Display Signal (B-in, Green)
signal BR		: std_logic;							-- Display Signal (B-in, Red)
signal CB		: std_logic;							-- Display Signal (ColorGal5, Blue)
signal CG		: std_logic;							-- Display Signal (ColorGal5, Green)
signal CR		: std_logic;							-- Display Signal (ColorGal5, Red)
signal VRAMDO  : std_logic_vector(7 downto 0);	-- Data Bus Output for VRAM
signal ARAMDO  : std_logic_vector(7 downto 0);	-- Data Bus Output for ARAM
signal CRAMDO  : std_logic_vector(7 downto 0);	-- Data Bus Output for ARAM(ColorGal5)
signal NDO0		: std_logic_vector(7 downto 0);	-- Data Bus Output for ARAM
signal NDO1		: std_logic_vector(7 downto 0);	-- Data Bus Output for ARAM
signal DCODE   : std_logic_vector(7 downto 0);	-- Display Code, Read From VRAM
signal CGDAT   : std_logic_vector(7 downto 0);	-- Font Data To Display
signal CCODE   : std_logic_vector(7 downto 0);	-- Color Code by ColorGal5
signal INV		: std_logic;							-- Reverse Mode

--
-- Components
--
component dpram2k
	PORT
	(
		address_a		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		address_b		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		q_b		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component ram1k
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

component pcg
	Port (
		RST_x  : in std_logic;
		-- CG-ROM I/F
		ROMA   : in std_logic_vector(10 downto 0);
		ROMD   : out std_logic_vector(7 downto 0);
		DCLK   : in std_logic;
		-- CPU Bus
		A      : in std_logic_vector(11 downto 0);
		DI     : in std_logic_vector(7 downto 0);
		CSE_x  : in std_logic;
		WR_x   : in std_logic;
		MCLK   : in std_logic;
		-- Settings
		PCGSW  : in std_logic;
		MZMODE : in std_logic_vector(1 downto 0);
		-- BackDoor for Sub-Processor
		NCLK	 : in std_logic;								-- NiosII Clock
		NA		 : in std_logic_vector(15 downto 0);	-- NiosII Address Bus
		NCS_x  : in std_logic;								-- NiosII Memory Request
		NWR_x	 : in std_logic;								-- NiosII Write Signal
		NDI	 : in std_logic_vector(7 downto 0)		-- NiosII Data Bus(in)
	);
end component;

component pll50
	PORT
	(
		inclk0	: IN STD_LOGIC  := '0';
		c0			: OUT STD_LOGIC ;
		c1			: OUT STD_LOGIC ;
		c2			: OUT STD_LOGIC ;
		c3			: OUT STD_LOGIC 
	);
end component;

begin

	--
	-- Instantiation
	--
	VVRAM0 : dpram2k PORT MAP (
		address_a	 => VADR,
		address_b	 => NA(10 downto 0),
		clock_a	 => CK8Mi,
		clock_b	 => NCLK,
		data_a	 => DI,
		data_b	 => NDI,
		wren_a	 => VWEN,
		wren_b	 => NWEN0,
		q_a	 => VRAMDO,
		q_b	 => NDO0
	);

	VARAM0 : dpram2k PORT MAP (
		address_a	 => VADR,
		address_b	 => NA(10 downto 0),
		clock_a	 => CK8Mi,
		clock_b	 => NCLK,
		data_a	 => DI,
		data_b	 => NDI,
		wren_a	 => AWEN,
		wren_b	 => NWEN1,
		q_a	 => ARAMDO,
		q_b	 => NDO1
	);

	VCGAL5 : ram1k PORT MAP (
		address	 => VADR(9 downto 0),
		clock	 => CK8Mi,
		data	 => CCODE,
		wren	 => VWEN,
		q	 => CRAMDO
	);

	VPCG0 : pcg PORT MAP (
		RST_x => RST,
		-- CG-ROM I/F
		ROMA => DCODE&VCOUNT(2 downto 0),
		ROMD => CGDAT,
		DCLK => CK8Mi,
		-- CPU Bus
		A => A,
		DI => DI,
		CSE_x => CSE_x,
		WR_x => WR_x,
		MCLK => ZCLK,
		-- Settings
		PCGSW => PCGSW,
		MZMODE => MZMODE,
		-- BackDoor for Sub-Processor
		NCLK => NCLK,								-- NiosII Clock
		NA => NA,									-- NiosII Address Bus
		NCS_x => NCS_x,							-- NiosII Memory Request
		NWR_x => NWR_x,							-- NiosII Write Signal
		NDI => NDI									-- NiosII Data Bus(in)
	);

	--
	-- Clock Generator
	--
	VCKGEN : pll50 PORT MAP (
			inclk0	 => CK50M,
			c0	 => CK12M5,
			c1	 => CK8Mi,
			c2	 => CK4M,
			c3	 => CK3125);

	--
	-- Blank & Sync Generation
	--
	process( RST, CK8Mi ) begin

		if RST='0' then
			HCOUNT<="111111100";
			HBLANKi<='1';
			BLNK<='0';
			HSYNC<='1';
			VDISPEN<='1';
			VSYNC<='1';
			VADRC<=(others=>'0');
			VADRL<=(others=>'0');
		elsif CK8Mi'event and CK8Mi='1' then

			-- Counters
			if HCOUNT=507 then
				--HCOUNT<=(others=>'0');
				HCOUNT<="111111100";
				VADRC<=VADRL;				-- Return to Most-Left-Column Address
				if VCOUNT=259 then
					VCOUNT<=(others=>'0');
					VADRC<=(others=>'0');	-- Home Position
					VADRL<=(others=>'0');
				else
					VCOUNT<=VCOUNT+'1';
				end if;
			else
				HCOUNT<=HCOUNT+'1';
			end if;

			-- Horizontal Signals Decode
			if HCOUNT=0 then
				HDISPEN<=VDISPEN;		-- if V-DISP is Enable then H-DISP Start
			elsif HCOUNT=318 then
				HBLANKi<='1';			-- H-Blank Start
				BLNK<='1';
			elsif HCOUNT=320 then
				HDISPEN<='0';			-- H-DISP End
			elsif HCOUNT=393 then
				HSYNC<='0';				-- H-Sync Pulse Start
			elsif HCOUNT=399 and VCOUNT(2 downto 0)="111" then
				VADRL<=VADRC;			-- Save Most-Left-Column Address
			elsif HCOUNT=438 then
				HSYNC<='1';				-- H-Sync Pulse End
			elsif HCOUNT=486 then
				BLNK<='0';
			elsif HCOUNT=510 then
				HBLANKi<='0';			-- H-Blank End
			end if;

			-- VRAM Address counter(per 8dot)
			if HCOUNT(2 downto 0)="111" and HBLANKi='0' then
				VADRC<=VADRC+'1';
			end if;

			-- Get Font data and Shift
			if HCOUNT(2 downto 0)="000" then
				SDAT<=CGDAT;
				ADATi<=ARAMDO;
				CDATi<=CRAMDO;
			else
				SDAT<=SDAT(6 downto 0)&'0';
			end if;

			-- Vertical Signals Decode
			if VCOUNT=0 then
				VDISPEN<='1';			-- V-DISP Start
			elsif VCOUNT=200 then
				VDISPEN<='0';			-- V-DISP End
			elsif VCOUNT=219 then
				VSYNC<='0';				-- V-Sync Pulse Start
			elsif VCOUNT=223 then
				VSYNC<='1';				-- V-Sync Pulse End
			end if;

		end if;

	end process;

	--
	-- Control Registers
	--
	process( RST, ZCLK ) begin
		if RST='0' then
			INV<='0';
			OFST<=(others=>'0');
		elsif ZCLK'event and ZCLK='0' then
			if CSINV_x='0' and RD_x='0' then
				INV<=MA(0);
			end if;
			if CSCG5_x='0' and WR_x='0' then
				CCODE<=DI;
			end if;
			if CSSCL_x='0' and RD_x='0' then
				OFST<=A(7 downto 0);
			end if;
		end if;
	end process;

	--
	-- Timing Conditioning and Wait
	--
	process( MREQ_x ) begin
		if MREQ_x'event and MREQ_x='0' then
			XBLNK<=BLNK;
		end if;
	end process;

	process( MREQ_x, ZCLK ) begin
		if MREQ_x='1' then
			CPUENi<='0';
		elsif ZCLK'event and ZCLK='0' then
			CPUENi<=not XBLNK;
		end if;
	end process;

	process( ZCLK ) begin
		if ZCLK'event and ZCLK='1' then
			WAITii_x<=WAITi_x;
		end if;
	end process;
	WAITi_x<='0' when CSD_x='0' and XBLNK='0' and BLNK='0' and MZMODE(1)='1' else '1';
	WAIT_x<=WAITi_x and WAITii_x;

	--
	-- Mask by Mode
	--
	MA<=A when MZMODE(1)='1' else "00"&A(9 downto 0);
	CSV_x<='0' when CSD_x='0' and MA(11)='0' else '1';
	CSA_x<='0' when CSD_x='0' and MA(11)='1' else '1';
	NCSV_x<='0' when NCS_x='0' and NA(15 downto 11)="11010" else '1';
	NCSA_x<='0' when NCS_x='0' and NA(15 downto 11)="11011" else '1';
	VWEN<='1' when WR_x='0' and CSV_x='0' and CPUEN='1' else '0';
	AWEN<='1' when WR_x='0' and CSA_x='0' and CPUEN='1' else '0';
	NWEN0<=not(NWR_x or NCSV_x);
	NWEN1<=not(NWR_x or NCSA_x);
	CSINV_x<='0' when CSE_x='0' and MZMODE(1)='1' and MA(11 downto 9)="000" and MA(4 downto 2)="101" else '1';
	CSCG5_x<='0' when CSE_x='0' and MA(4 downto 2)="011" and ((MA(11) or MA(10) or MA(9)) and MZMODE(1))='0' else '1';
	CSSCL_x<='0' when CSE_x='0' and A(11 downto 8)="0010" and MZMODE="11" else '1';
	CPUEN<='1' when MZMODE(1)='0' or (CPUENi='1' and BLNK='1' and MZMODE(1)='1') or BLNK='1' else '0';

	--
	-- Bus Select
	--
	VADRO<=VADRC when MZMODE/="11" or BACK='0' else VADRC+(OFST&"000");
	VADR<=MA(10 downto 0) when CSD_x='0' and CPUEN='1' else VADRO;
	DCODE<=DI when CSV_x='0' and CPUEN='1' and WR_x='0' else VRAMDO;
	ADAT<=DI when CSA_x='0' and CPUEN='1' and WR_x='0' else ADATi;
	CDAT<=DI when CSD_x='0' and CPUEN='1' and WR_x='0' else CDATi;
	DO<=VRAMDO when MA(11)='0' else ARAMDO;
	NDO<=NDO0 when NCSV_x='0' else
		  NDO1 when NCSA_x='0' else
		  (others=>'0');

	--
	-- Color Decode
	--
	-- Monoclome Monitor
	MB<=SDAT(7) when HDISPEN='1' and VGATE='1' and MZMODE="00" else '0';
	MR<=SDAT(7) when HDISPEN='1' and VGATE='1' and MZMODE="00" else '0';
	MG<=not SDAT(7) when HDISPEN='1' and VGATE='1' and MZMODE(1)='1' and INV='1' else
		 SDAT(7) when HDISPEN='1' and VGATE='1' else '0';
	-- NIDECOM Color Board - not yet
	-- Color Gal 5
	CB<=CDAT(0) when HDISPEN='1' and SDAT(7)='1' else
		 CDAT(4) when HDISPEN='1' and SDAT(7)='0' else '0';
	CR<=CDAT(2) when HDISPEN='1' and SDAT(7)='1' else
		 CDAT(6) when HDISPEN='1' and SDAT(7)='0' else '0';
	CG<=CDAT(1) when HDISPEN='1' and SDAT(7)='1' else
		 CDAT(5) when HDISPEN='1' and SDAT(7)='0' else '0';
	-- Builtin Color
	BB<=ADAT(2) when HDISPEN='1' and VGATE='1' and SDAT(7)='1' else
		 ADAT(6) when HDISPEN='1' and VGATE='1' and SDAT(7)='0' else '0';
	BR<=ADAT(0) when HDISPEN='1' and VGATE='1' and SDAT(7)='1' else
		 ADAT(4) when HDISPEN='1' and VGATE='1' and SDAT(7)='0' else '0';
	BG<=ADAT(1) when HDISPEN='1' and VGATE='1' and SDAT(7)='1' else
		 ADAT(5) when HDISPEN='1' and VGATE='1' and SDAT(7)='0' else '0';

	--
	-- Output
	--
	CK8M<=CK8Mi;
	VBLANK<=VDISPEN;
	HBLANK<=HBLANKi;
	ROUT<=BR  when DMODE="11" or BACK='0' else
			MR  when DMODE="00" else
			'0' when DMODE="01" else
			CR  when DMODE="10" else
			'0';
	GOUT<=BG  when DMODE="11" or BACK='0' else
			MG  when DMODE="00" else
			'0' when DMODE="01" else
			CG  when DMODE="10" else
			'0';
	BOUT<=BB  when DMODE="11" or BACK='0' else
			MB  when DMODE="00" else
			'0' when DMODE="01" else
			CB  when DMODE="10" else
			'0';

end RTL;
