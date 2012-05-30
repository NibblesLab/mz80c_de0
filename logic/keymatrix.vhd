--
-- keymatrix.vhd
--
-- Convert from PS/2 key-matrix to MZ-700 key-matrix module
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2005-2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

--  Uncomment the following lines to use the declarations that are
--  provided for instantiating Xilinx primitive components.
--library UNISIM;
--use UNISIM.VComponents.all;

entity keymatrix is
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
end keymatrix;

architecture Behavioral of keymatrix is

--
-- prefix flag
--
signal FLGF0 : std_logic;
signal FLGE0 : std_logic;
--
-- MZ-series matrix registers
--
signal SCAN00 : std_logic_vector(7 downto 0);
signal SCAN01 : std_logic_vector(7 downto 0);
signal SCAN02 : std_logic_vector(7 downto 0);
signal SCAN03 : std_logic_vector(7 downto 0);
signal SCAN04 : std_logic_vector(7 downto 0);
signal SCAN05 : std_logic_vector(7 downto 0);
signal SCAN06 : std_logic_vector(7 downto 0);
signal SCAN07 : std_logic_vector(7 downto 0);
signal SCAN08 : std_logic_vector(7 downto 0);
signal SCAN09 : std_logic_vector(7 downto 0);
signal SCAN10 : std_logic_vector(7 downto 0);
signal SCAN11 : std_logic_vector(7 downto 0);
signal SCAN12 : std_logic_vector(7 downto 0);
signal SCAN13 : std_logic_vector(7 downto 0);
signal SCAN14 : std_logic_vector(7 downto 0);
--
-- Key code exchange table
--
signal MTEN : std_logic_vector(3 downto 0);
signal MTDT : std_logic_vector(7 downto 0);
signal F_KBDT : std_logic_vector(7 downto 0);
--
-- Backdoor Access
--
signal NWEN : std_logic;
signal NCSK_x : std_logic;

--
-- Components
--
component dpram1kr
	PORT
	(
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdclock		: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wrclock		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC  := '0';
		q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
end component;

begin

	--
	-- Instantiation
	--
	MAP0 : dpram1kr PORT MAP (
		data	 => NDI,
		rdaddress	 => F_KBDT,
		rdclock	 => KCLK,
		wraddress	 => NA(7 downto 0),
		wrclock	 => NCLK,
		wren	 => NWEN,
		q	 => MTDT
	);

	--
	-- Convert
	--
	process( RST, KCLK ) begin
		if RST='0' then
			SCAN00<=(others=>'0');
			SCAN01<=(others=>'0');
			SCAN02<=(others=>'0');
			SCAN03<=(others=>'0');
			SCAN04<=(others=>'0');
			SCAN05<=(others=>'0');
			SCAN06<=(others=>'0');
			SCAN07<=(others=>'0');
			SCAN08<=(others=>'0');
			SCAN09<=(others=>'0');
			SCAN10<=(others=>'0');
			SCAN11<=(others=>'0');
			SCAN12<=(others=>'0');
			SCAN13<=(others=>'0');
			SCAN14<=(others=>'0');
			FLGF0<='0';
			FLGE0<='0';
			MTEN<=(others=>'0');
			F_KBDT<=(others=>'1');
		elsif KCLK'event and KCLK='1' then
			MTEN<=MTEN(2 downto 0)&KBEN;
			if KBEN='1' then
				case KBDT is
					when X"AA" => F_KBDT<=X"EF";
					when X"F0" => FLGF0<='1'; F_KBDT<=X"EF";
					when X"E0" => FLGE0<='1'; F_KBDT<=X"EF";
					when others =>  F_KBDT<=FLGE0&KBDT(6 downto 0); FLGE0<='0';
				end case;
			end if;

			if MTEN(3)='1' then
				case MTDT(7 downto 4) is								 
					when "0000" => SCAN00(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0001" => SCAN01(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0010" => SCAN02(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0011" => SCAN03(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0100" => SCAN04(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0101" => SCAN05(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0110" => SCAN06(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "0111" => SCAN07(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1000" => SCAN08(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1001" => SCAN09(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1010" => SCAN10(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1011" => SCAN11(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1100" => SCAN12(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1101" => SCAN13(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
					when "1110" => SCAN14(conv_integer(MTDT(2 downto 0)))<=not FLGF0;
					when others => SCAN14(conv_integer(MTDT(2 downto 0)))<=not FLGF0; FLGF0<='0';
				end case;
			end if;
		end if;
	end process;

	--
	-- response from key access
	--
	PB<=(not SCAN00) when PA="0000" else
	    (not SCAN01) when PA="0001" else
	    (not SCAN02) when PA="0010" else
	    (not SCAN03) when PA="0011" else
	    (not SCAN04) when PA="0100" else
	    (not SCAN05) when PA="0101" else
	    (not SCAN06) when PA="0110" else
	    (not SCAN07) when PA="0111" else
	    (not SCAN08) when PA="1000" else
	    (not SCAN09) when PA="1001" else
	    (not SCAN10) when PA="1010" else
	    (not SCAN11) when PA="1011" else
	    (not SCAN12) when PA="1100" else
	    (not SCAN13) when PA="1101" else (others=>'1');

	--
	-- Backdoor access
	--
	NCSK_x<='0' when NCS_x='0' and NA(15 downto 8)="11000000" else '1';
	NWEN<=not(NWR_x or NCSK_x);

end Behavioral;
