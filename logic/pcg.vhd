--
-- pcg.vhd
--
-- Programmable Character Generator(PCG) module
-- (Compatible with PCG-8000/PCG-1200/GB-10)
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pcg is
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
end pcg;

architecture RTL of pcg is

--
-- CG-ROM
--
signal ROMDO : std_logic_vector(7 downto 0);
--
-- CPU Access
--
signal CSPCG_x : std_logic;
signal WEN0 : std_logic;
signal WEN1 : std_logic;
signal NWEN : std_logic;
signal NCSR_x : std_logic;
--
-- PCG
--
signal RAMDO0 : std_logic_vector(7 downto 0);
signal RAMDO1 : std_logic_vector(7 downto 0);
signal CGA : std_logic_vector(10 downto 0);
signal RAMA : std_logic_vector(11 downto 0);
signal PDAT : std_logic_vector(7 downto 0);
signal PCGD : std_logic_vector(7 downto 0);
signal RAMWE : std_logic;
signal DSEL : std_logic;

--
-- Components
--
component cgrom
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
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

begin

	--
	-- Instantiation
	--
	CGROM0 : cgrom PORT MAP (
		data	 => NDI,
		rdaddress	 => CGA,
		rdclock	 => DCLK,
		wraddress	 => NA(10 downto 0),
		wrclock	 => NCLK,
		wren	 => NWEN,
		q	 => ROMDO
	);

	CGRAM0 : ram1k PORT MAP (
		address	 => CGA(9 downto 0),
		clock	 => DCLK,
		data	 => PCGD,
		wren	 => WEN0,
		q	 => RAMDO0
	);

	CGRAM1 : ram1k PORT MAP (
		address	 => CGA(9 downto 0),
		clock	 => DCLK,
		data	 => PCGD,
		wren	 => WEN1,
		q	 => RAMDO1
	);

	--
	-- Font select
	--
	ROMD<=PDAT when CSPCG_x='0' and A="10" and WR_x='0' else
		   ROMDO when PCGSW='0' or CGA(10)='0' else
		   RAMDO0 when PCGSW='1' and RAMA(11)='0' else
		   RAMDO1 when PCGSW='1' and RAMA(11)='1' else (others=>'1');
	CGA<=RAMA(10 downto 0) when RAMWE='0' else ROMA;

	--
	-- Access Registers
	--
	process( RST_x, MCLK ) begin
		if RST_x='0' then
			RAMA<=(others=>'0');
			PDAT<=(others=>'0');
			RAMWE<='1';
		elsif MCLK'event and MCLK='0' then
			if CSPCG_x='0' and WR_x='0' then
				if A(1 downto 0)="00" then
					PDAT<=DI;
				end if;
				if A(1 downto 0)="01" then
					RAMA(7 downto 0)<=DI;
				end if;
				if A(1 downto 0)="10"  then
					RAMA(11 downto 8)<=(DI(2) and MZMODE(1))&'1'&DI(1 downto 0);
					RAMWE<=not DI(4);
					DSEL<=DI(5);
				end if;
			end if;
		end if;
	end process;
	PCGD<=PDAT when DSEL='0' else
		   ROMDO when DSEL='1' else (others=>'0');

	--
	-- CPU access
	--
	CSPCG_x<='0' when CSE_x='0' and A(11 downto 4)="00000001" else '1';
	WEN0<=not(RAMWE or CSPCG_x) and (not RAMA(11));
	WEN1<=not(RAMWE or CSPCG_x) and RAMA(11);

	--
	-- Backdoor access
	--
	NCSR_x<='0' when NCS_x='0' and NA(15 downto 11)="11001" else '1';
	NWEN<=not(NWR_x or NCSR_x);

end RTL;
