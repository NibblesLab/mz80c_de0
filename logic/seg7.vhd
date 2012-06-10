--
-- 7seg.vhd
--
-- 4-digit 7-segment LED decorder
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity seg7 is
	Port (
		-- 7-SEG Dispaly
		HEX0_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 0
		HEX0_DP : out std_logic;							--	Seven Segment Digit DP 0
		HEX1_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 1
		HEX1_DP : out std_logic;							--	Seven Segment Digit DP 1
		HEX2_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 2
		HEX2_DP : out std_logic;							--	Seven Segment Digit DP 2
		HEX3_D  : out std_logic_vector(6 downto 0);	--	Seven Segment Digit 3
		HEX3_DP : out std_logic;							--	Seven Segment Digit DP 3
		-- Status Signal
		MZMODE  : in std_logic_vector(1 downto 0);	-- Hardware Mode
																	-- "00" .. MZ-80K/K2/K2E
																	-- "01" .. MZ-80C
																	-- "10" .. MZ-1200
																	-- "11" .. MZ-80A
		DMODE   : in std_logic_vector(1 downto 0);	-- Display Mode
																	-- "00" .. Normal
																	-- "01" .. Nidecom Color (PCG OFF)
																	-- "10" .. Color Gal 5
																	-- "11" .. Bulitin Color
		NUMEN	  : in std_logic;
		NUMBER  : in std_logic_vector(15 downto 0)
	);
end seg7;

architecture RTL of seg7 is

begin

	HEX3_D<= "1111111" when NUMEN='0' and DMODE="00" and MZMODE="00" else	-- " "
				"1111111" when NUMEN='0' and DMODE="00" and MZMODE="01" else	-- " "
				"1111001" when NUMEN='0' and DMODE="00" and MZMODE="10" else	-- "1"
				"1111111" when NUMEN='0' and DMODE="00" and MZMODE="11" else	-- " "
				"1111111" when NUMEN='0' and DMODE="01" else							-- " "
				"1000010" when NUMEN='0' and DMODE="10" else							-- "G"
				"0000011" when NUMEN='0' and DMODE="11" else							-- "b"
				"1000000" when NUMEN='1' and NUMBER(15 downto 12)=X"0" else		-- "0"
				"1111001" when NUMEN='1' and NUMBER(15 downto 12)=X"1" else		-- "1"
				"0100100" when NUMEN='1' and NUMBER(15 downto 12)=X"2" else		-- "2"
				"0110000" when NUMEN='1' and NUMBER(15 downto 12)=X"3" else		-- "3"
				"0011001" when NUMEN='1' and NUMBER(15 downto 12)=X"4" else		-- "4"
				"0010010" when NUMEN='1' and NUMBER(15 downto 12)=X"5" else		-- "5"
				"0000010" when NUMEN='1' and NUMBER(15 downto 12)=X"6" else		-- "6"
				"1011000" when NUMEN='1' and NUMBER(15 downto 12)=X"7" else		-- "7"
				"0000000" when NUMEN='1' and NUMBER(15 downto 12)=X"8" else		-- "8"
				"0010000" when NUMEN='1' and NUMBER(15 downto 12)=X"9" else		-- "9"
				"0001000" when NUMEN='1' and NUMBER(15 downto 12)=X"a" else		-- "A"
				"0000011" when NUMEN='1' and NUMBER(15 downto 12)=X"b" else		-- "b"
				"1000110" when NUMEN='1' and NUMBER(15 downto 12)=X"c" else		-- "C"
				"0100001" when NUMEN='1' and NUMBER(15 downto 12)=X"d" else		-- "d"
				"0000110" when NUMEN='1' and NUMBER(15 downto 12)=X"e" else		-- "E"
				"0001110" when NUMEN='1' and NUMBER(15 downto 12)=X"f" else		-- "F"
				"1111111";
	HEX3_DP<='0' when NUMEN='0' and DMODE="11" else '1';

	HEX2_D<= "0000000" when NUMEN='0' and DMODE="00" and MZMODE="00" else	-- "8"
				"0000000" when NUMEN='0' and DMODE="00" and MZMODE="01" else	-- "8"
				"0100100" when NUMEN='0' and DMODE="00" and MZMODE="10" else	-- "2"
				"0000000" when NUMEN='0' and DMODE="00" and MZMODE="11" else	-- "8"
				"0101011" when NUMEN='0' and DMODE="01" else							-- "n"
				"0001000" when NUMEN='0' and DMODE="10" else							-- "A"
				"1000110" when NUMEN='0' and DMODE="11" else							-- "C"
				"1000000" when NUMEN='1' and NUMBER(11 downto 8)=X"0" else		-- "0"
				"1111001" when NUMEN='1' and NUMBER(11 downto 8)=X"1" else		-- "1"
				"0100100" when NUMEN='1' and NUMBER(11 downto 8)=X"2" else		-- "2"
				"0110000" when NUMEN='1' and NUMBER(11 downto 8)=X"3" else		-- "3"
				"0011001" when NUMEN='1' and NUMBER(11 downto 8)=X"4" else		-- "4"
				"0010010" when NUMEN='1' and NUMBER(11 downto 8)=X"5" else		-- "5"
				"0000010" when NUMEN='1' and NUMBER(11 downto 8)=X"6" else		-- "6"
				"1011000" when NUMEN='1' and NUMBER(11 downto 8)=X"7" else		-- "7"
				"0000000" when NUMEN='1' and NUMBER(11 downto 8)=X"8" else		-- "8"
				"0010000" when NUMEN='1' and NUMBER(11 downto 8)=X"9" else		-- "9"
				"0001000" when NUMEN='1' and NUMBER(11 downto 8)=X"a" else		-- "A"
				"0000011" when NUMEN='1' and NUMBER(11 downto 8)=X"b" else		-- "b"
				"1000110" when NUMEN='1' and NUMBER(11 downto 8)=X"c" else		-- "C"
				"0100001" when NUMEN='1' and NUMBER(11 downto 8)=X"d" else		-- "d"
				"0000110" when NUMEN='1' and NUMBER(11 downto 8)=X"e" else		-- "E"
				"0001110" when NUMEN='1' and NUMBER(11 downto 8)=X"f" else		-- "F"
				"1111111";
	HEX2_DP<='0' when NUMEN='0' and DMODE="01" else '1';

	HEX1_D<= "1000000" when NUMEN='0' and DMODE="00" else							-- "0"
				"0100001" when NUMEN='0' and DMODE="01" else							-- "d"
				"1000111" when NUMEN='0' and DMODE="10" else							-- "L"
				"0100011" when NUMEN='0' and DMODE="11" else							-- "o"
				"1000000" when NUMEN='1' and NUMBER(7 downto 4)=X"0" else		-- "0"
				"1111001" when NUMEN='1' and NUMBER(7 downto 4)=X"1" else		-- "1"
				"0100100" when NUMEN='1' and NUMBER(7 downto 4)=X"2" else		-- "2"
				"0110000" when NUMEN='1' and NUMBER(7 downto 4)=X"3" else		-- "3"
				"0011001" when NUMEN='1' and NUMBER(7 downto 4)=X"4" else		-- "4"
				"0010010" when NUMEN='1' and NUMBER(7 downto 4)=X"5" else		-- "5"
				"0000010" when NUMEN='1' and NUMBER(7 downto 4)=X"6" else		-- "6"
				"1011000" when NUMEN='1' and NUMBER(7 downto 4)=X"7" else		-- "7"
				"0000000" when NUMEN='1' and NUMBER(7 downto 4)=X"8" else		-- "8"
				"0010000" when NUMEN='1' and NUMBER(7 downto 4)=X"9" else		-- "9"
				"0001000" when NUMEN='1' and NUMBER(7 downto 4)=X"a" else		-- "A"
				"0000011" when NUMEN='1' and NUMBER(7 downto 4)=X"b" else		-- "b"
				"1000110" when NUMEN='1' and NUMBER(7 downto 4)=X"c" else		-- "C"
				"0100001" when NUMEN='1' and NUMBER(7 downto 4)=X"d" else		-- "d"
				"0000110" when NUMEN='1' and NUMBER(7 downto 4)=X"e" else		-- "E"
				"0001110" when NUMEN='1' and NUMBER(7 downto 4)=X"f" else		-- "F"
				"1111111";
	HEX1_DP<='0' when NUMEN='0' and DMODE="01" else '1';

	HEX0_D<= "0000101" when NUMEN='0' and DMODE="00" and MZMODE="00" else	-- "K"
				"1000110" when NUMEN='0' and DMODE="00" and MZMODE="01" else	-- "C"
				"1000000" when NUMEN='0' and DMODE="00" and MZMODE="10" else	-- "0"
				"0001000" when NUMEN='0' and DMODE="00" and MZMODE="11" else	-- "A"
				"1000110" when NUMEN='0' and DMODE="01" else							-- "C"
				"0010010" when NUMEN='0' and DMODE="10" else							-- "5"
				"1000111" when NUMEN='0' and DMODE="11" else							-- "L"
				"1000000" when NUMEN='1' and NUMBER(3 downto 0)=X"0" else		-- "0"
				"1111001" when NUMEN='1' and NUMBER(3 downto 0)=X"1" else		-- "1"
				"0100100" when NUMEN='1' and NUMBER(3 downto 0)=X"2" else		-- "2"
				"0110000" when NUMEN='1' and NUMBER(3 downto 0)=X"3" else		-- "3"
				"0011001" when NUMEN='1' and NUMBER(3 downto 0)=X"4" else		-- "4"
				"0010010" when NUMEN='1' and NUMBER(3 downto 0)=X"5" else		-- "5"
				"0000010" when NUMEN='1' and NUMBER(3 downto 0)=X"6" else		-- "6"
				"1011000" when NUMEN='1' and NUMBER(3 downto 0)=X"7" else		-- "7"
				"0000000" when NUMEN='1' and NUMBER(3 downto 0)=X"8" else		-- "8"
				"0010000" when NUMEN='1' and NUMBER(3 downto 0)=X"9" else		-- "9"
				"0001000" when NUMEN='1' and NUMBER(3 downto 0)=X"a" else		-- "A"
				"0000011" when NUMEN='1' and NUMBER(3 downto 0)=X"b" else		-- "b"
				"1000110" when NUMEN='1' and NUMBER(3 downto 0)=X"c" else		-- "C"
				"0100001" when NUMEN='1' and NUMBER(3 downto 0)=X"d" else		-- "d"
				"0000110" when NUMEN='1' and NUMBER(3 downto 0)=X"e" else		-- "E"
				"0001110" when NUMEN='1' and NUMBER(3 downto 0)=X"f" else		-- "F"
				"1111111";
	HEX0_DP<='0' when NUMEN='0' and DMODE="01" else '1';

end RTL;
