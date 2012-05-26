--
-- keymatrix.vhd
--
-- Convert from PS/2 key-matrix to MZ-700 key-matrix module
-- for MZ-700 on FPGA
--
-- Nibbles Lab. 2005
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
		PA    : in std_logic_vector(3 downto 0);
		PB    : out std_logic_vector(7 downto 0);
		KCLK  : in std_logic;
		LDDAT : out std_logic_vector(7 downto 0);
		KBEN  : in std_logic;
		KBDT  : in std_logic_vector(7 downto 0)
	);
end keymatrix;

architecture Behavioral of keymatrix is

--
-- prefix flag
--
signal FLGF0 : std_logic;
signal FLGE0 : std_logic;
--
-- MZ-700 matrix registers
--
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
--
-- for Sub-Z80
--
--signal KEY_A : std_logic;
--signal KEY_X : std_logic;
--signal KEY_P : std_logic;
--signal KEY_S : std_logic;
--signal KEY_C : std_logic;
--signal KEY_G : std_logic;
signal FLGALT : std_logic;

--
-- Components
--

begin

	--
	-- Instantiation
	--

	--
	-- Convert
	--
	process( RST, KCLK ) begin
		if( RST='0' ) then
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
		elsif( KCLK'event and KCLK='1' ) then
			if( KBEN='1' ) then
				LDDAT<=KBDT;
				case KBDT is								 
					when X"13" => SCAN07(5)<=not FLGF0; SCAN09(0)<=not SCAN09(0); FLGF0<='0'; -- KANA
--					when X"0E" => SCAN01(6)<=not FLGF0; FLGF0<='0'; -- GRAPH
					when X"0D" => SCAN10(0)<=not FLGF0; FLGF0<='0'; -- HOME
--					when X"01"|X"78" => SCAN01(5)<=not FLGF0; FLGF0<='0'; -- =
					when X"58" => SCAN07(5)<=not FLGF0; FLGF0<='0'; -- EISUU
					when X"4C" => SCAN06(4)<=not FLGF0; FLGF0<='0'; -- ;
					when X"52" => SCAN05(5)<=not FLGF0; FLGF0<='0'; -- :
					when X"5A" => SCAN09(4)<=not FLGF0; FLGF0<='0'; -- CR
					when X"35" => SCAN04(2)<=not FLGF0; FLGF0<='0'; -- Y
					when X"1A" => SCAN07(0)<=not FLGF0; FLGF0<='0'; -- Z
					when X"54" => SCAN03(5)<=not FLGF0; FLGF0<='0'; -- @
					when X"5B" => SCAN06(5)<=not FLGF0; FLGF0<='0'; -- (
					when X"5D" => SCAN08(5)<=not FLGF0; FLGF0<='0'; -- )
					when X"15" => SCAN03(0)<=not FLGF0; FLGF0<='0'; -- Q
					when X"2D" => SCAN04(1)<=not FLGF0; FLGF0<='0'; -- R
					when X"1B" => SCAN06(0)<=not FLGF0; FLGF0<='0'; -- S
--					when X"1B" => KEY_S<=not FLGF0; FLGF0<='0'; -- S
					when X"2C" => SCAN03(2)<=not FLGF0; FLGF0<='0'; -- T
					when X"3C" => SCAN03(3)<=not FLGF0; FLGF0<='0'; -- U
					when X"2A" => SCAN08(1)<=not FLGF0; FLGF0<='0'; -- V
					when X"1D" => SCAN04(0)<=not FLGF0; FLGF0<='0'; -- W
					when X"22" => SCAN08(0)<=not FLGF0; FLGF0<='0'; -- X
--					when X"22" => KEY_X<=not FLGF0; FLGF0<='0'; -- X
					when X"43" => SCAN04(3)<=not FLGF0; FLGF0<='0'; -- I
					when X"3B" => SCAN05(3)<=not FLGF0; FLGF0<='0'; -- J
					when X"42" => SCAN06(3)<=not FLGF0; FLGF0<='0'; -- K
					when X"4B" => SCAN05(4)<=not FLGF0; FLGF0<='0'; -- L
					when X"3A" => SCAN07(3)<=not FLGF0; FLGF0<='0'; -- M
					when X"31" => SCAN08(2)<=not FLGF0; FLGF0<='0'; -- N
					when X"44" => SCAN03(4)<=not FLGF0; FLGF0<='0'; -- O
					when X"4D" => SCAN04(4)<=not FLGF0; FLGF0<='0'; -- P
--					when X"4D" => KEY_P<=not FLGF0; FLGF0<='0'; -- P
					when X"1C" => SCAN05(0)<=not FLGF0; FLGF0<='0'; -- A
--					when X"1C" => KEY_A<=not FLGF0; FLGF0<='0'; -- A
					when X"32" => SCAN07(2)<=not FLGF0; FLGF0<='0'; -- B
					when X"21" => SCAN07(1)<=not FLGF0; FLGF0<='0'; -- C
--					when X"21" => KEY_C<=not FLGF0; FLGF0<='0'; -- C
					when X"23" => SCAN05(1)<=not FLGF0; FLGF0<='0'; -- D
					when X"24" => SCAN03(1)<=not FLGF0; FLGF0<='0'; -- E
					when X"2B" => SCAN06(1)<=not FLGF0; FLGF0<='0'; -- F
					when X"34" => SCAN05(2)<=not FLGF0; FLGF0<='0'; -- G
--					when X"34" => KEY_G<=not FLGF0; FLGF0<='0'; -- G
					when X"33" => SCAN06(2)<=not FLGF0; FLGF0<='0'; -- H
					when X"16" => SCAN01(0)<=not FLGF0; FLGF0<='0'; -- 1
					when X"1E" => SCAN02(0)<=not FLGF0; FLGF0<='0'; -- 2
					when X"26" => SCAN01(1)<=not FLGF0; FLGF0<='0'; -- 3
					when X"25" => SCAN02(1)<=not FLGF0; FLGF0<='0'; -- 4
					when X"2E" => SCAN01(2)<=not FLGF0; FLGF0<='0'; -- 5
					when X"36" => SCAN02(2)<=not FLGF0; FLGF0<='0'; -- 6
					when X"3D" => SCAN01(3)<=not FLGF0; FLGF0<='0'; -- 7
					when X"3E" => SCAN02(3)<=not FLGF0; FLGF0<='0'; -- 8
					when X"6A" => SCAN04(5)<=not FLGF0; FLGF0<='0'; -- *
					when X"55" => SCAN02(5)<=not FLGF0; FLGF0<='0'; -- +
					when X"4E" => SCAN01(5)<=not FLGF0; FLGF0<='0'; -- -
					when X"29" => SCAN10(1)<=not FLGF0; FLGF0<='0'; -- ' '
					when X"45" => SCAN02(4)<=not FLGF0; FLGF0<='0'; -- 0
					when X"46" => SCAN01(4)<=not FLGF0; FLGF0<='0'; -- 9
					when X"41" => SCAN08(3)<=not FLGF0; FLGF0<='0'; -- ,
					when X"49" => SCAN07(4)<=not FLGF0; FLGF0<='0'; -- .
					when X"70" => SCAN09(1)<=not FLGF0; SCAN09(0)<=not SCAN09(0); FLGF0<='0'; FLGE0<='0'; -- INST
					when X"71" => SCAN09(1)<=not FLGF0; FLGF0<='0'; FLGE0<='0'; -- DEL
					when X"75" => SCAN10(2)<=not FLGF0; SCAN09(0)<=not SCAN09(0); FLGF0<='0'; FLGE0<='0'; -- UP
					when X"72" => SCAN10(2)<=not FLGF0; FLGF0<='0'; FLGE0<='0'; -- DOWN
					when X"74" => SCAN09(3)<=not FLGF0; FLGF0<='0'; FLGE0<='0'; -- RIGHT
					when X"6B" => SCAN09(3)<=not FLGF0; SCAN09(0)<=not SCAN09(0); FLGF0<='0'; FLGE0<='0'; -- LEFT
					when X"51" => SCAN10(5)<=not FLGF0; FLGF0<='0'; -- ?
					when X"4A" => SCAN08(4)<=not FLGF0; FLGF0<='0'; -- /
					when X"66" => SCAN10(3)<=not FLGF0; FLGF0<='0'; -- BREAK
--					when X"58" => SCAN09(6)<=not FLGF0; FLGF0<='0'; -- CTRL
					when X"12" => SCAN09(0)<=((not FLGF0) and (not FLGE0)) or (SCAN09(0) and FLGE0); FLGF0<='0'; FLGE0<='0'; -- SHIFT-L
					when X"59" => SCAN09(5)<=((not FLGF0) and (not FLGE0)) or (SCAN09(5) and FLGE0); FLGF0<='0'; FLGE0<='0'; -- SHIFT-R
--					when X"05" => SCAN10(7)<=not FLGF0; FLGF0<='0'; -- F1
--					when X"06" => SCAN10(6)<=not FLGF0; FLGF0<='0'; -- F2
--					when X"04" => SCAN10(5)<=not FLGF0; FLGF0<='0'; -- F3
--					when X"0C" => SCAN10(4)<=not FLGF0; FLGF0<='0'; -- F4
--					when X"03" => SCAN10(3)<=not FLGF0; FLGF0<='0'; -- F5
					when X"F0" => FLGF0<='1';
					when X"E0" => FLGE0<='1';
					when X"11" => FLGALT<=not FLGF0; FLGF0<='0'; -- ALT
					when others => FLGF0<='0'; FLGE0<='0';
				end case;
			end if;
		end if;
	end process;

	--
	-- response from key access
	--
	PB<=(not SCAN01) when PA="0000" else
	    (not SCAN02) when PA="0001" else
	    (not SCAN03) when PA="0010" else
	    (not SCAN04) when PA="0011" else
	    (not SCAN05) when PA="0100" else
	    (not SCAN06) when PA="0101" else
--	    (not (SCAN07(7 downto 5)&(SCAN07(4) or JOYB(4))&SCAN07(3 downto 0))) when PA="0110" else
	    (not SCAN07) when PA="0110" else
--	    (not (SCAN08(7 downto 6)&(SCAN08(5) or JOYA(0) or JOYB(0))&(SCAN08(4) or JOYA(1) or JOYB(1))&(SCAN08(3) or JOYA(3) or JOYB(3))&(SCAN08(2) or JOYA(2) or JOYB(2))&SCAN08(1 downto 0))) when PA="0111" else
	    (not SCAN08) when PA="0111" else
--	    (not (SCAN09(7)&(SCAN09(6) or JOYA(4))&SCAN09(5 downto 1)&(SCAN09(0) or JOYA(5)))) when PA="1000" else
	    (not SCAN09) when PA="1000" else
	    (not SCAN10) when PA="1001" else (others=>'1');

	--
	-- for Sub processor
	--
--	KEY_UP<=SCAN08(5);
--	KEY_DOWN<=SCAN08(4);
--	KEY_LEFT<=SCAN08(2);
--	KEY_RIGHT<=SCAN08(3);
--	KEY_CR<=SCAN01(0);
--	KEY_SPACE<=SCAN07(4);
--	ALT_ALT<=KEY_A when FLGALT='1' else '0';
--	ALT_EXIT<=KEY_X when FLGALT='1' else '0';
--	ALT_PLAY<=KEY_P when FLGALT='1' else '0';
--	ALT_STOP<=KEY_S when FLGALT='1' else '0';
--	ALT_CG<=KEY_C when FLGALT='1' else '0';
--	ALT_PCG<=KEY_G when FLGALT='1' else '0';
--	SCAN05(7)<=KEY_A when FLGALT='0' else '0';
--	SCAN03(0)<=KEY_X when FLGALT='0' else '0';
--	SCAN04(0)<=KEY_P when FLGALT='0' else '0';
--	SCAN03(5)<=KEY_S when FLGALT='0' else '0';
--	SCAN05(5)<=KEY_C when FLGALT='0' else '0';
--	SCAN05(1)<=KEY_G when FLGALT='0' else '0';

end Behavioral;
