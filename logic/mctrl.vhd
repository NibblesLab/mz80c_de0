--
-- mctrl.vhd
--
-- MZ mode and Display mode control
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mctrl is
	Port (
		-- Switches
		SW     : in std_logic_vector(3 downto 0);
		-- Status Signal
		MZMODE : out std_logic_vector(1 downto 0);	-- Hardware Mode
																	-- "00" .. MZ-80K/K2/K2E
																	-- "01" .. MZ-80C
																	-- "10" .. MZ-1200
																	-- "11" .. MZ-80A
		DMODE  : out std_logic_vector(1 downto 0)		-- Display Mode
																	-- "00" .. Normal
																	-- "01" .. Nidecom Color (PCG OFF)
																	-- "10" .. Color Gal 5
																	-- "11" .. Bulitin Color
	);
end mctrl;

architecture RTL of mctrl is

begin

	process( SW ) begin
		case SW is
			when "0000" => MZMODE<="00"; DMODE<="00";	-- MZ-80K, Normal
			when "0010" => MZMODE<="00"; DMODE<="01";	-- MZ-80K, NIDECO
			when "0001" => MZMODE<="00"; DMODE<="10";	-- MZ-80K, Gal5
			when "0011" => MZMODE<="00"; DMODE<="00";	-- MZ-80K, Normal
			when "1000" => MZMODE<="01"; DMODE<="00";	-- MZ-80C, Normal
			when "1010" => MZMODE<="01"; DMODE<="01";	-- MZ-80C, NIDECO
			when "1001" => MZMODE<="01"; DMODE<="10";	-- MZ-80C, Gal5
			when "1011" => MZMODE<="01"; DMODE<="00";	-- MZ-80C, Normal
			when "0100" => MZMODE<="10"; DMODE<="00";	-- MZ-1200, Normal
			when "0110" => MZMODE<="10"; DMODE<="01";	-- MZ-1200, NIDECO
			when "0101" => MZMODE<="10"; DMODE<="10";	-- MZ-1200, Gal5
			when "0111" => MZMODE<="10"; DMODE<="11";	-- MZ-1200, B-in.Col
			when "1100" => MZMODE<="11"; DMODE<="00";	-- MZ-80A, Normal
			when "1110" => MZMODE<="11"; DMODE<="01";	-- MZ-80A, NIDECO
			when "1101" => MZMODE<="11"; DMODE<="10";	-- MZ-80A, Gal5
			when "1111" => MZMODE<="11"; DMODE<="11";	-- MZ-80A, B-in.Col
			when others =>
		end case;
	end process;

end rtl;
