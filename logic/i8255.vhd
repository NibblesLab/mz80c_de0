--
-- i8255.vhd
--
-- Intel 8255 (PPI:Programmable Peripheral Interface) partiality compatible module
-- for MZ-80C on FPGA
--
-- Port A : Output, mode 0 only
-- Port B : Input, mode 0 only
-- Port C : Input(7-4)&Output(3-0), mode 0 only, bit set/reset support
--
-- Nibbles Lab. 2005-2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity i8255 is
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
end i8255;

architecture Behavioral of i8255 is

--
-- Port Register
--
signal PA : std_logic_vector(7 downto 0);
signal PB : std_logic_vector(7 downto 0);
signal PC : std_logic_vector(7 downto 0);
--
-- Port Selecter
--
signal SELPA : std_logic;
signal SELPB : std_logic;
signal SELPC : std_logic;
signal SELCT : std_logic;
--
-- CURSOR blink
--
signal TBLNK : std_logic;
signal CCOUNT : std_logic_vector(3 downto 0);
--
-- Remote
--
signal SNS : std_logic;
signal MTR : std_logic;
signal M_ON : std_logic;
signal SENSE0 : std_logic;
signal SWIN : std_logic_vector(3 downto 0);

--
-- Components
--
component keymatrix
	Port (
		RST   : in std_logic;
		-- i8255
		PA    : in std_logic_vector(3 downto 0);
		PB    : out std_logic_vector(7 downto 0);
		-- PS/2 Keyboard Data
		KCLK  : in std_logic;								-- Key controller base clock
		KBEN  : in std_logic;								-- PS/2 Keyboard Data Valid
		KBDT  : in std_logic_vector(7 downto 0);		-- PS/2 Keyboard Data
		-- for Debug
		LDDAT : out std_logic_vector(7 downto 0);
		-- BackDoor for Sub-Processor
		NCLK	: in std_logic;								-- NiosII Clock
		NA		: in std_logic_vector(15 downto 0);		-- NiosII Address Bus
		NCS_x : in std_logic;								-- NiosII Memory Request
		NWR_x	: in std_logic;								-- NiosII Write Signal
		NDI	: in std_logic_vector(7 downto 0)		-- NiosII Data Bus(in)
	);
end component;

begin

	--
	-- Instantiation
	--
	keys : keymatrix port map (
		RST => RST,
		-- i8255
		PA => PA(3 downto 0),
		PB => PB,
		-- PS/2 Keyboard Data
		KCLK => KCLK,							-- Key controller base clock
		KBEN => KBEN,							-- PS/2 Keyboard Data Valid
		KBDT => KBDT,							-- PS/2 Keyboard Data
		-- for Debug
		LDDAT => LDDAT,
		-- BackDoor for Sub-Processor
		NCLK => NCLK,							-- NiosII Clock
		NA => NA,								-- NiosII Address Bus
		NCS_x => NCS_x,						-- NiosII Memory Request
		NWR_x => NWR_x,						-- NiosII Write Signal
		NDI => NDI								-- NiosII Data Bus(in)
	);

	--
	-- Port select for Output
	--
	SELPA<='1' when A="00" else '0';
	SELPB<='1' when A="01" else '0';
	SELPC<='1' when A="10" else '0';
	SELCT<='1' when A="11" else '0';

	--
	-- Output
	--
	process( RST, CLK ) begin
		if( RST='0' ) then
			PA<=(others=>'0');
--			PB<=(others=>'0');
			PC<=(others=>'0');
		elsif( CLK'event and CLK='0' ) then
			if( CS='0' and WR='0' ) then
				if( SELPA='1' ) then
					PA<=DI;
				end if;
--				if( SELPB='1' ) then
--					PB<=DI;
--				end if;
				if( SELPC='1' ) then
					PC(3 downto 0)<=DI(3 downto 0);
				end if;
				if( SELCT='1' and DI(7)='0' ) then
					case DI(3 downto 0) is
						when "0000" => PC(0)<='0';
						when "0001" => PC(0)<='1';
						when "0010" => PC(1)<='0';
						when "0011" => PC(1)<='1';
						when "0100" => PC(2)<='0';
						when "0101" => PC(2)<='1';
						when "0110" => PC(3)<='0';
						when "0111" => PC(3)<='1';
--						when "1000" => PC(4)<='0';
--						when "1001" => PC(4)<='1';
--						when "1010" => PC(5)<='0';
--						when "1011" => PC(5)<='1';
--						when "1100" => PC(6)<='0';
--						when "1101" => PC(6)<='1';
--						when "1110" => PC(7)<='0';
--						when "1111" => PC(7)<='1';
						when others => PC<="XXXXXXXX";
					end case;
				end if;
			end if;
		end if;
	end process;

	--
	-- CURSOR blink Clock
	--
	process( CLKIN, PA(7) ) begin
		if( PA(7)='0' ) then
			CCOUNT<=(others=>'0');
		elsif( CLKIN'event and CLKIN='1' ) then
			CCOUNT<=CCOUNT+'1';
			if( CCOUNT=13 ) then
				CCOUNT<=(others=>'0');
				TBLNK<=not TBLNK;
			end if;
		end if;
	end process;

	--
	-- Input select
	--
	DO<=PB                       when SELPB='1' else
	    VBLNK&TBLNK&RBIT&MTR&PC(3 downto 0) when SELPC='1' else (others=>'1');

	--
	-- CMT Remote Control
	--
	MOTOR<=MTR;
	process( KCLK ) begin
		if( KCLK'event and KCLK='1' ) then
			M_ON<=PC(3);
			SNS<=SENSE0;
			if( SENSE0='1' ) then
				MTR<='0';
			elsif( SNS='1' and SENSE0='0' ) then
				MTR<='1';
			elsif( M_ON='0' and PC(3)='1' ) then
				MTR<=not MTR;
			end if;

			SWIN<=SWIN(2 downto 0)&(not SENSE);
			if( SWIN="1111" and SENSE='0' ) then
				SENSE0<='0';
			elsif( SWIN="0000" and SENSE='1' ) then
				SENSE0<='1';
			end if;
		end if;
	end process;

	--
	-- Others
	--
	EIKANA<=PC(2);
	VGATE<=PC(0);

--	LDDAT<=TBLNK&"0000000";

end Behavioral;
