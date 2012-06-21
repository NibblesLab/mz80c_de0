--
-- cmt.vhd
--
-- Sharp PWM Tape I/F and Pseudo-CMT module
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2012
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity cmt is
	Port (
		-- Avalon Bus
		reset		 : in std_logic;
		clk		 : in std_logic;
		address	 : in std_logic_vector(1 downto 0);
		write		 : in std_logic;
		read		 : in std_logic;
		writedata : in std_logic_vector(15 downto 0);
		readdata  : out std_logic_vector(15 downto 0);
		interrupt : out std_logic;
		-- Z80 Bus
		ZCLK		 : in std_logic;
		ZA8		 : in std_logic_vector(7 downto 0);
		ZIWR_x	 : in std_logic;
		ZDI		 : in std_logic_vector(7 downto 0);
		ZDO		 : out std_logic_vector(7 downto 0);
		-- Tape signals
		SCLK		 : in std_logic;
		LED		 : out std_logic;	-- CMT status indicator
		NUMEN		 : out std_logic;	-- Enable Display Remaining Number
		MOTOR		 : in std_logic;	-- Motor
		SENSE		 : out std_logic;	-- Sense CMT
		PLAYSW	 : in std_logic;	-- Play/Stop Button
		EXIN		 : in std_logic;	-- CMT IN from I/O board
		POUT		 : out std_logic	-- to 8255
	);
end cmt;

architecture RTL of cmt is

--
-- Status
--
signal TAPE : std_logic;
--
-- Pulse Generator
--
signal COUNT : std_logic_vector(13 downto 0);
signal BUSY : std_logic;
signal LIMIT : std_logic_vector(13 downto 0);
--
-- Filters
--
signal CNT15 : std_logic_vector(14 downto 0);
signal PL_BTN : std_logic_vector(7 downto 0);
signal T_BTN : std_logic;
--
-- Divider
--
signal DIV : std_logic_vector(14 downto 0);
--
-- Registers for Z80
--
signal MADR : std_logic_vector(15 downto 0);
signal MBYTE : std_logic_vector(15 downto 0);
signal MCMD : std_logic_vector(7 downto 0);
signal STAT : std_logic_vector(7 downto 0);

begin

	--
	-- PWM Counter & Register
	--
	process( reset, clk ) begin
		if reset='1' then
			BUSY<='0';
			COUNT<=(others=>'0');
			LIMIT<=(others=>'0');
			CNT15<=(others=>'0');
			PL_BTN<=(others=>'1');
			T_BTN<='0';
			STAT<=(others=>'0');
		elsif clk'event and clk='1' then
			if write='1' and address="00" then
				BUSY<='1';
				if writedata(7)='1' then
					LIMIT<=conv_std_logic_vector(7665,14);
					COUNT<=conv_std_logic_vector(-7535,14);
				else
					LIMIT<=conv_std_logic_vector(3835,14);
					COUNT<=conv_std_logic_vector(-3830,14);
				end if;
			elsif write='1' and address="01" then
				TAPE<=writedata(0);
				T_BTN<=T_BTN and writedata(0);
			elsif write='1' and address="10" then
				STAT<=writedata(7 downto 0);
			elsif BUSY='1' then
				if COUNT=LIMIT then
					BUSY<='0';
				elsif MOTOR='1' then
					COUNT<=COUNT+1;
				end if;
			end if;
			if CNT15="111111111111111" then
				PL_BTN<=PL_BTN(6 downto 0)&PLAYSW;	-- Tape Play/Stop
				CNT15<=(others=>'0');
				if PL_BTN="10000000" then
					T_BTN<=not T_BTN;
				end if;
			else
				CNT15<=CNT15+'1';
			end if;
		end if;
	end process;

	POUT<=COUNT(13) when TAPE='1' else EXIN;
	readdata<="00000000"&T_BTN&MOTOR&"00000"&BUSY when address="00" else
				 MADR											 when address="01" else
				 MBYTE										 when address="10" else
				 "00000000"&MCMD							 when address="11" else "0000000000000000";
	SENSE<=not T_BTN;
	NUMEN<='1' when TAPE='1' and T_BTN='1' else '0';

	--
	-- Indicator Divider
	--
	process( reset, SCLK ) begin
		if reset='1' then
			DIV<=(others=>'0');
		elsif SCLK'event and SCLK='1' then
			DIV<=DIV+'1';
		end if;
	end process;

	LED<='1'		 when TAPE='1' and T_BTN='0' else 	-- still
		  DIV(14) when TAPE='1' and MOTOR='0' else	-- blink slow
		  DIV(13) when (TAPE='1' and MOTOR='1') or (TAPE='0' and T_BTN='1') else '0';	-- blink fast

  	--
	-- MZ-80 Action
	--
	process( reset, ZCLK ) begin
		if reset='1' then
			MADR<=(others=>'0');
			MBYTE<=(others=>'0');
			MCMD<=(others=>'0');
			interrupt<='1';
		elsif ZCLK'event and ZCLK='0' then
			if ZIWR_x='0' and ZA8(7 downto 3)="10001" then
				case ZA8(2 downto 0) is
					when "000" => MADR(7 downto 0)<=ZDI; interrupt<='1';
					when "001" => MADR(15 downto 8)<=ZDI; interrupt<='1';
					when "010" => MBYTE(7 downto 0)<=ZDI; interrupt<='1';
					when "011" => MBYTE(15 downto 8)<=ZDI; interrupt<='1';
					when others => MCMD<=ZDI; interrupt<=not(ZDI(7) or ZDI(6) or ZDI(5) or ZDI(4) or ZDI(3) or ZDI(2) or ZDI(1) or ZDI(0));
				end case;
			end if;
		end if;
	end process;

	ZDO<=STAT;

end RTL;
