--
-- mz80c.vhd
--
-- SHARP MZ-80C compatible logic, top module
-- for Altera DE0
--
-- Nibbles Lab. 2012
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mz80c is
  port(
		--------------------				Clock Input					 	----------------------	 
		CLOCK_50		: in std_logic;								--	50 MHz
		CLOCK_50_2	: in std_logic;								--	50 MHz
		--------------------				Push Button						----------------------------
		BUTTON		: in std_logic_vector(2 downto 0);		--	Pushbutton[2:0]
		--------------------				DPDT Switch						----------------------------
		SW				: in std_logic_vector(9 downto 0);		--	Toggle Switch[9:0]
		--------------------				7-SEG Dispaly					----------------------------
		HEX0_D		: out std_logic_vector(6 downto 0);		--	Seven Segment Digit 0
		HEX0_DP		: out std_logic;								--	Seven Segment Digit DP 0
		HEX1_D		: out std_logic_vector(6 downto 0);		--	Seven Segment Digit 1
		HEX1_DP		: out std_logic;								--	Seven Segment Digit DP 1
		HEX2_D		: out std_logic_vector(6 downto 0);		--	Seven Segment Digit 2
		HEX2_DP		: out std_logic;								--	Seven Segment Digit DP 2
		HEX3_D		: out std_logic_vector(6 downto 0);		--	Seven Segment Digit 3
		HEX3_DP		: out std_logic;								--	Seven Segment Digit DP 3
		--------------------						LED						----------------------------
		LEDG			: out std_logic_vector(9 downto 0);		--	LED Green[9:0]
		--------------------						UART						----------------------------
		UART_TXD		: out std_logic;								--	UART Transmitter
		UART_RXD		: in std_logic;								--	UART Receiver
		UART_CTS		: in std_logic;								--	UART Clear To Send
		UART_RTS		: out std_logic;								--	UART Request To Send
		--------------------				SDRAM Interface				----------------------------
		DRAM_DQ		: inout std_logic_vector(15 downto 0);	--	SDRAM Data bus 16 Bits
		DRAM_ADDR	: out std_logic_vector(12 downto 0);	--	SDRAM Address bus 13 Bits
		DRAM_LDQM	: out std_logic;								--	SDRAM Low-byte Data Mask 
		DRAM_UDQM	: out std_logic;								--	SDRAM High-byte Data Mask
		DRAM_WE_N	: out std_logic;								--	SDRAM Write Enable
		DRAM_CAS_N	: out std_logic;								--	SDRAM Column Address Strobe
		DRAM_RAS_N	: out std_logic;								--	SDRAM Row Address Strobe
		DRAM_CS_N	: out std_logic;								--	SDRAM Chip Select
		DRAM_BA_0	: out std_logic;								--	SDRAM Bank Address 0
		DRAM_BA_1	: out std_logic;								--	SDRAM Bank Address 1
		DRAM_CLK		: out std_logic;								--	SDRAM Clock
		DRAM_CKE		: out std_logic;								--	SDRAM Clock Enable
		--------------------				Flash Interface				----------------------------
		FL_DQ			: inout std_logic_vector(15 downto 0);	--	FLASH Data bus 16 Bits
--		FL_DQ15_AM1	: out std_logic;								--	FLASH Data bus Bit 15 or Address A-1
		FL_ADDR		: out std_logic_vector(21 downto 0);	--	FLASH Address bus 22 Bits
		FL_WE_N		: out std_logic;								--	FLASH Write Enable
		FL_RST_N		: out std_logic;								--	FLASH Reset
		FL_OE_N		: out std_logic;								--	FLASH Output Enable
		FL_CE_N		: out std_logic;								--	FLASH Chip Enable
		FL_WP_N		: out std_logic;								--	FLASH Hardware Write Protect
		FL_BYTE_N	: out std_logic;								--	FLASH Selects 8/16-bit mode
		FL_RY			: out std_logic;								--	FLASH Ready/Busy
		--------------------				LCD Module 16X2				----------------------------
		LCD_BLON		: out std_logic;								--	LCD Back Light ON/OFF
		LCD_RW		: out std_logic;								--	LCD Read/Write Select, 0 = Write, 1 = Read
		LCD_EN		: out std_logic;								--	LCD Enable
		LCD_RS		: out std_logic;								--	LCD Command/Data Select, 0 = Command, 1 = Data
		LCD_DATA		: out std_logic_vector(7 downto 0);		--	LCD Data bus 8 bits
		--------------------				SD_Card Interface				----------------------------
		SD_DAT0		: inout std_logic;							--	SD Card Data 0 (DO)
		SD_DAT3		: inout std_logic;							--	SD Card Data 3 (CS)
		SD_CMD		: out std_logic;								--	SD Card Command Signal (DI)
		SD_CLK		: out std_logic;								--	SD Card Clock (SCLK)
		SD_WP_N		: in std_logic;								--	SD Card Write Protect
		--------------------						PS2						----------------------------
		PS2_KBDAT	: in std_logic;								--	PS2 Keyboard Data
		PS2_KBCLK	: in std_logic;								--	PS2 Keyboard Clock
		PS2_MSDAT	: in std_logic;								--	PS2 Mouse Data
		PS2_MSCLK	: in std_logic;								--	PS2 Mouse Clock
		--------------------						VGA						----------------------------
		VGA_HS		: out std_logic;								--	VGA H_SYNC
		VGA_VS		: out std_logic;								--	VGA V_SYNC
		VGA_R			: out std_logic_vector(3 downto 0);   	--	VGA Red[3:0]
		VGA_G			: out std_logic_vector(3 downto 0);	 	--	VGA Green[3:0]
		VGA_B			: out std_logic_vector(3 downto 0);  	--	VGA Blue[3:0]
		--------------------						GPIO						------------------------------
		GPIO0_CLKIN	: in std_logic_vector(1 downto 0);		--	GPIO Connection 0 Clock In Bus
		GPIO0_CLKOUT: out std_logic_vector(1 downto 0);		--	GPIO Connection 0 Clock Out Bus
		GPIO0_D		: out std_logic_vector(31 downto 0);	--	GPIO Connection 0 Data Bus
		GPIO1_CLKIN	: in std_logic_vector(1 downto 0);		--	GPIO Connection 1 Clock In Bus
		GPIO1_CLKOUT: out std_logic_vector(1 downto 0);		--	GPIO Connection 1 Clock Out Bus
		GPIO1_D		: inout std_logic_vector(31 downto 0)	--	GPIO Connection 1 Data Bus
  );
end mz80c;

architecture rtl of mz80c is

--
-- MZ-80
--
signal ZCLK : std_logic;
signal ZMWR : std_logic;
signal MRD : std_logic;
signal ZA16 : std_logic_vector(15 downto 0);
signal ZDO : std_logic_vector(7 downto 0);
signal ZDI : std_logic_vector(15 downto 0);
signal ZRAMCS : std_logic;
signal ZCTRL : std_logic_vector(1 downto 0);
signal ZBACK : std_logic;
--
-- NiosII processor
--
signal PCLK : std_logic;
signal NA : std_logic_vector(18 downto 0);
signal NDI : std_logic_vector(15 downto 0);
signal NDO : std_logic_vector(15 downto 0);
signal NBEN : std_logic_vector(1 downto 0);
signal NWE : std_logic;
signal NWRQ : std_logic;
signal NRAMCS : std_logic;
signal MA : std_logic_vector(15 downto 0);
signal MRAMCS : std_logic;
signal MWE : std_logic;
signal MDI : std_logic_vector(7 downto 0);
signal MDO : std_logic_vector(7 downto 0);
signal SA : std_logic_vector(15 downto 0);
signal SDI : std_logic_vector(15 downto 0);
signal SDO : std_logic_vector(15 downto 0);
signal SBEN : std_logic_vector(1 downto 0);
signal SWE : std_logic;
signal SWRQ : std_logic;
signal SRAMCS : std_logic;
signal SPAGE : std_logic_vector(5 downto 0);
--
-- SDRAM
--
signal SDRAMDO : std_logic_vector(15 downto 0);
signal SDRAMDOE : std_logic;
--
-- MMC/SD CARD
--
signal SD_CS : std_logic;
signal SD_DEN : std_logic_vector(1 downto 0);
signal SD_DO : std_logic;
--
-- Flash Memory
--
signal FL_ADDR0 : std_logic_vector(21 downto 0);
--
-- Misc
--
signal URST : std_logic;
signal FRST : std_logic;
signal ARST : std_logic;
signal MRST : std_logic;
signal ZRST : std_logic;
signal SCLK : std_logic;
signal BUF : std_logic_vector(9 downto 0);
signal CNT5 : std_logic_vector(4 downto 0);
signal SR_BTN : std_logic_vector(7 downto 0);
signal ZR_BTN : std_logic_vector(7 downto 0);
signal FR_BTN : std_logic_vector(7 downto 0);
signal F_BTN : std_logic;
signal MZMODE : std_logic_vector(1 downto 0);
signal DMODE : std_logic_vector(1 downto 0);
signal KBEN : std_logic;
signal KBEN_M : std_logic;
signal KBDT : std_logic_vector(7 downto 0);
signal T_LEDG : std_logic_vector(9 downto 0);
signal ZLEDG : std_logic_vector(9 downto 0);

--
-- Components
--
component mz80_core
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
		-- Push Button
		BUTTON		: in std_logic;								--	Pushbutton[2]
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
end component;

component mz80c_de0_sopc
	port (
		-- 1) global signals:
		signal PCLK : IN STD_LOGIC;
		signal reset_n : IN STD_LOGIC;

		-- the_INT_BUTTON
		signal in_port_to_the_INT_BUTTON : IN STD_LOGIC;

		-- the_KBDATA
		signal in_port_to_the_KBDATA : IN STD_LOGIC_VECTOR (7 DOWNTO 0);

		-- the_KBEN
		signal in_port_to_the_KBEN : IN STD_LOGIC;

		-- the_PAGE
		signal out_port_from_the_PAGE : OUT STD_LOGIC_VECTOR (5 DOWNTO 0);

		-- the_SPI_CS
		signal out_port_from_the_SPI_CS : OUT STD_LOGIC;

		-- the_Z80CTRL
		signal out_port_from_the_Z80CTRL : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

		-- the_Z80STAT
		signal in_port_to_the_Z80STAT : IN STD_LOGIC;

		-- the_internal_sram2_0_avalon_int_sram_slave
		signal ADDR_to_the_internal_sram2_0 : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal CS_to_the_internal_sram2_0 : OUT STD_LOGIC;
		signal DATA_I_to_the_internal_sram2_0 : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal DATA_O_from_the_internal_sram2_0 : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal DEN_to_the_internal_sram2_0 : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		signal WE_to_the_internal_sram2_0 : OUT STD_LOGIC;
		signal WREQ_from_the_internal_sram2_0 : IN STD_LOGIC;

		-- the_internal_sram8_0_avalon_int_sram_slave
		signal ADDR_to_the_internal_sram8_0 : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal CS_to_the_internal_sram8_0 : OUT STD_LOGIC;
		signal DATA_I_to_the_internal_sram8_0 : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		signal DATA_O_from_the_internal_sram8_0 : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		signal WE_to_the_internal_sram8_0 : OUT STD_LOGIC;

		-- the_internal_sram_0_avalon_int_sram_slave
		signal ADDR_to_the_internal_sram_0 : OUT STD_LOGIC_VECTOR (18 DOWNTO 0);
		signal CS_to_the_internal_sram_0 : OUT STD_LOGIC;
		signal DATA_I_to_the_internal_sram_0 : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal DATA_O_from_the_internal_sram_0 : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal DEN_to_the_internal_sram_0 : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
		signal WE_to_the_internal_sram_0 : OUT STD_LOGIC;
		signal WREQ_from_the_internal_sram_0 : IN STD_LOGIC;

		-- the_pio_0
		signal in_port_to_the_pio_0 : IN STD_LOGIC_VECTOR (9 DOWNTO 0);

		-- the_pio_1
		signal out_port_from_the_pio_1 : OUT STD_LOGIC_VECTOR (9 DOWNTO 0);

		-- the_spi_0
		signal MISO_to_the_spi_0 : IN STD_LOGIC;
		signal MOSI_from_the_spi_0 : OUT STD_LOGIC;
		signal SCLK_from_the_spi_0 : OUT STD_LOGIC;
		signal SS_n_from_the_spi_0 : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

		-- the_tri_state_bridge_0_avalon_slave
		signal address_to_the_cfi_flash_0 : OUT STD_LOGIC_VECTOR (21 DOWNTO 0);
		signal data_to_and_from_the_cfi_flash_0 : INOUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		signal read_n_to_the_cfi_flash_0 : OUT STD_LOGIC;
		signal select_n_to_the_cfi_flash_0 : OUT STD_LOGIC;
		signal write_n_to_the_cfi_flash_0 : OUT STD_LOGIC;

		-- the_uart_0
		signal cts_n_to_the_uart_0 : IN STD_LOGIC;
		signal rts_n_from_the_uart_0 : OUT STD_LOGIC;
		signal rxd_to_the_uart_0 : IN STD_LOGIC;
		signal txd_from_the_uart_0 : OUT STD_LOGIC
	);
end component;

component sdram
	port (
		reset			: in std_logic;								-- Reset
		RSTOUT		: out std_logic;								-- Reset After Init. SDRAM
		CLOCK_50		: in std_logic;								-- Clock(50MHz)
		PCLK			: out std_logic;								-- CPU Clock
		SCLK			: out std_logic;								-- Slow Clock (31.25kHz)
		-- RAM access(port-A:Z80 bus)
		AA				: in std_logic_vector(21 downto 0);
		DAI			: in std_logic_vector(15 downto 0);
		DAO			: out std_logic_vector(15 downto 0);
		CSA			: in std_logic;
		WEA			: in std_logic;
		BEA			: in std_logic_vector(1 downto 0);		-- Byte Enable
		-- RAM access(port-B:Avalon bus bridge)
		AB				: in std_logic_vector(21 downto 0);		-- Address
		DBI			: in std_logic_vector(15 downto 0);		-- Data Input(16bit)
		DBO			: out std_logic_vector(15 downto 0);	-- Data Output(16bit)
		CSB			: in std_logic;
		WEB			: in std_logic;								-- Write Enable
		BEB			: in std_logic_vector(1 downto 0);		-- Byte Enable
		WQB			: out std_logic;								-- CPU Wait
		-- RAM access(port-C:Z80 bus peripheral)
		AC				: in std_logic_vector(21 downto 0);
		DCI			: in std_logic_vector(15 downto 0);
		DCO			: out std_logic_vector(15 downto 0);
		CSC			: in std_logic;
		WEC			: in std_logic;
		BEC			: in std_logic_vector(1 downto 0);		-- Byte Enable
		-- RAM access(port-D:Avalon bus bridge snoop)
		AD				: in std_logic_vector(21 downto 0);		-- Address
		DDI			: in std_logic_vector(15 downto 0);		-- Data Input(16bit)
		DDO			: out std_logic_vector(15 downto 0);	-- Data Output(16bit)
		CSD			: in std_logic;
		WED			: in std_logic;								-- Write Enable
		BED			: in std_logic_vector(1 downto 0);		-- Byte Enable
		WQD			: out std_logic;								-- CPU Wait
		-- SDRAM signal
		MA				: out std_logic_vector(11 downto 0);	-- Address
		MBA0			: out std_logic;								-- Bank Address 0
		MBA1			: out std_logic;								-- Bank Address 1
		MDI			: in std_logic_vector(15 downto 0);		-- Data Input(16bit)
		MDO			: out std_logic_vector(15 downto 0);	-- Data Output(16bit)
		MDOE			: out std_logic;								-- Data Output Enable
		MLDQ			: out std_logic;								-- Lower Data Mask
		MUDQ			: out std_logic;								-- Upper Data Mask
		MCAS			: out std_logic;								-- Column Address Strobe
		MRAS			: out std_logic;								-- Raw Address Strobe
		MCS			: out std_logic;								-- Chip Select
		MWE			: out std_logic;								-- Write Enable
		MCKE			: out std_logic;								-- Clock Enable
		MCLK			: out std_logic								-- SDRAM Clock
	);
end component;

component ps2kb
	Port (
		RST   : in std_logic;
		KCLK  : in std_logic;
		PS2CK : in std_logic;
		PS2DT : in std_logic;
		DTEN  : out std_logic;
		DATA  : out std_logic_vector(7 downto 0)
	);
end component;

component seg7
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
		DMODE   : in std_logic_vector(1 downto 0);	-- Display Mode
		NUMEN	  : in std_logic;
		NUMBER  : in std_logic_vector(15 downto 0)
	);
end component;

component mctrl
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
end component;

begin

	--
	-- Instantiation
	--
	MZ80 : mz80_core port map(
		-- Core I/O
		RST_x => ZRST,
		ZCLK => ZCLK,
		A => ZA16,
		RAMDO => ZDO,
		RAMDI => ZDI(7 downto 0),
		MWR_x => ZMWR,
		BREQ => ZCTRL(0),
		BACK => ZBACK,
		RAMCS_x => ZRAMCS,
		MZMODE => MZMODE,				-- Hardware Mode
		DMODE => DMODE,				-- Display Mode
		KBEN => KBEN,					-- Key Data Valid
		KBDT => KBDT,					-- Key Code
		-- BackDoor for Sub-Processor
		NCLK => PCLK,					-- NiosII Clock
		NA => MA,						-- NiosII Address Bus
		NCS_x => MRAMCS,				-- NiosII Memory Request
		NWR_x => MWE,					-- NiosII Write Signal
		NDI => MDO,						-- NiosII Data Bus(in)
		NDO => MDI,						-- NiosII Data Bus(out)
		-- Clock Input
		CLOCK_50 => CLOCK_50,		--	50 MHz
		-- Push Button
		BUTTON => BUTTON(2),			--	Pushbutton[2]
		-- DPDT Switch
		SW => SW(5 downto 0),		--	Toggle Switch[5:0]
		-- LED
		LEDG => ZLEDG,					--	LED Green[9:0]
		-- VGA
		VGA_HS => VGA_HS,				--	VGA H_SYNC
		VGA_VS => VGA_VS,				--	VGA V_SYNC
		VGA_R => VGA_R,		   	--	VGA Red[3:0]
		VGA_G => VGA_G,			 	--	VGA Green[3:0]
		VGA_B => VGA_B,			  	--	VGA Blue[3:0]
		-- GPIO
		GPIO0_CLKIN	=> "00",			--	GPIO Connection 0 Clock In Bus
		GPIO0_CLKOUT => open,		--	GPIO Connection 0 Clock Out Bus
		GPIO0_D => GPIO0_D,			--	GPIO Connection 0 Data Bus
		GPIO1_CLKIN	=> "00",			--	GPIO Connection 1 Clock In Bus
		GPIO1_CLKOUT => open,		--	GPIO Connection 1 Clock Out Bus
		GPIO1_D => GPIO1_D			--	GPIO Connection 1 Data Bus
	);

	SOPC0 : mz80c_de0_sopc port map(
		-- 1) global signals:
		PCLK => PCLK,
      reset_n => ARST,
		-- the_INT_BUTTON
		in_port_to_the_INT_BUTTON => F_BTN,
		-- the_KBDATA
		in_port_to_the_KBDATA => KBDT,
		-- the_KBEN
		in_port_to_the_KBEN => KBEN_M,
		-- the_PAGE
		out_port_from_the_PAGE => SPAGE,
		-- the_SPI_CS
		out_port_from_the_SPI_CS => SD_CS,
		-- the_Z80CTRL
		out_port_from_the_Z80CTRL => ZCTRL,
		-- the_Z80STAT
		in_port_to_the_Z80STAT => ZBACK,
		-- the_internal_sram2_0_avalon_int_sram_slave
		ADDR_to_the_internal_sram2_0 		=> SA,
		CS_to_the_internal_sram2_0 		=> SRAMCS,
		DATA_I_to_the_internal_sram2_0 	=> SDO,
		DATA_O_from_the_internal_sram2_0 => SDI,
		DEN_to_the_internal_sram2_0 		=> SBEN,
		WE_to_the_internal_sram2_0 		=> SWE,
		WREQ_from_the_internal_sram2_0 	=> SWRQ,
		-- the_internal_sram8_0_avalon_int_sram_slave
		ADDR_to_the_internal_sram8_0 		=> MA,
		CS_to_the_internal_sram8_0 		=> MRAMCS,
		DATA_I_to_the_internal_sram8_0 	=> MDO,
		DATA_O_from_the_internal_sram8_0 => MDI,
		WE_to_the_internal_sram8_0 		=> MWE,
		-- the_internal_sram_0_avalon_int_sram_slave
		ADDR_to_the_internal_sram_0 		=> NA,
		CS_to_the_internal_sram_0 			=> NRAMCS,
		DATA_I_to_the_internal_sram_0 	=> NDO,
		DATA_O_from_the_internal_sram_0 	=> NDI,
		DEN_to_the_internal_sram_0 		=> NBEN,
		WE_to_the_internal_sram_0 			=> NWE,
		WREQ_from_the_internal_sram_0 	=> NWRQ,
		-- the_pio_0
		in_port_to_the_pio_0 => SW,
		-- the_pio_1
		out_port_from_the_pio_1 => T_LEDG,
		-- the_spi_0
		MISO_to_the_spi_0   => SD_DAT0,
		MOSI_from_the_spi_0 => SD_DO,
		SCLK_from_the_spi_0 => SD_CLK,
		SS_n_from_the_spi_0 => SD_DEN,
		-- the_tri_state_bridge_0_avalon_slave
		address_to_the_cfi_flash_0 		=> FL_ADDR0,
		data_to_and_from_the_cfi_flash_0 => FL_DQ,
		read_n_to_the_cfi_flash_0 			=> FL_OE_N,
		select_n_to_the_cfi_flash_0 		=> FL_CE_N,
		write_n_to_the_cfi_flash_0 		=> FL_WE_N,
		-- the_uart_0
		cts_n_to_the_uart_0 => UART_CTS,
		rts_n_from_the_uart_0 => UART_RTS,
		rxd_to_the_uart_0 => UART_RXD,
		txd_from_the_uart_0 => UART_TXD
   );

	DRAM0 : sdram port map (
		reset => URST,							-- Reset
		RSTOUT => MRST,						-- Reset After Init. SDRAM
		CLOCK_50 => CLOCK_50_2,				-- Clock(50MHz)
		PCLK => PCLK,							-- CPU Clock
		SCLK => SCLK,							-- Slow Clock (31.25kHz)
		-- RAM access(port-A:Z80 bus)
		AA => "000000"&ZA16,
		DAI => "00000000"&ZDO,
		DAO => ZDI,
		CSA => ZRAMCS,
		WEA => ZMWR,
		BEA => "10",							-- Byte Enable
		-- RAM access(port-B:Avalon bus bridge)
		AB => "010"&NA,						-- Address
		DBI => NDO,								-- Data Input(16bit)
		DBO => NDI,								-- Data Output(16bit)
		CSB => NRAMCS,
		WEB => NWE,								-- Write Enable
		BEB => NBEN,							-- Byte Enable
		WQB => NWRQ,							-- CPU Wait
		-- RAM access(port-C:Z80 bus peripheral)
		AC => (others=>'1'),
		DCI => (others=>'0'),
		DCO => open,
		CSC => '1',
		WEC => '1',
		BEC => "00",							-- Byte Enable
		-- RAM access(port-D:Avalon bus bridge snoop)
		AD => SPAGE&SA,						-- Address
		DDI => SDO,								-- Data Input(16bit)
		DDO => SDI,								-- Data Output(16bit)
		CSD => SRAMCS,
		WED => SWE,								-- Write Enable
		BED => SBEN,							-- Byte Enable
		WQD => SWRQ,							-- CPU Wait
		-- SDRAM signal
		MA => DRAM_ADDR(11 downto 0),		-- Address
		MBA0 => DRAM_BA_0,					-- Bank Address 0
		MBA1 => DRAM_BA_1,					-- Bank Address 1
		MDI => DRAM_DQ,						-- Data Input(16bit)
		MDO => SDRAMDO,						-- Data Output(16bit)
		MDOE => SDRAMDOE,						-- Data Output Enable
		MLDQ => DRAM_LDQM,					-- Lower Data Mask
		MUDQ => DRAM_UDQM,					-- Upper Data Mask
		MCAS => DRAM_CAS_N,					-- Column Address Strobe
		MRAS => DRAM_RAS_N,					-- Raw Address Strobe
		MCS => DRAM_CS_N,						-- Chip Select
		MWE => DRAM_WE_N,						-- Write Enable
		MCKE => DRAM_CKE,						-- Clock Enable
		MCLK => DRAM_CLK						-- SDRAM Clock
	);

	PS2RCV : ps2kb port map (
		RST => ARST,
		KCLK => ZCLK,
		PS2CK => PS2_KBCLK,
		PS2DT => PS2_KBDAT,
		DTEN => KBEN,
		DATA => KBDT
	);

	LED70 : seg7 Port map(
		-- 7-SEG Dispaly
		HEX0_D => HEX0_D,				--	Seven Segment Digit 0
		HEX0_DP => HEX0_DP,			--	Seven Segment Digit DP 0
		HEX1_D => HEX1_D,				--	Seven Segment Digit 1
		HEX1_DP => HEX1_DP,			--	Seven Segment Digit DP 1
		HEX2_D => HEX2_D,				--	Seven Segment Digit 2
		HEX2_DP => HEX2_DP,			--	Seven Segment Digit DP 2
		HEX3_D => HEX3_D,				--	Seven Segment Digit 3
		HEX3_DP => HEX3_DP,			--	Seven Segment Digit DP 3
		-- Status Signal
		MZMODE => MZMODE,				-- Hardware Mode
		DMODE => DMODE,				-- Display Mode
		NUMEN => '0',
		NUMBER => (others=>'0')
	);

	CTRL0 : mctrl Port map(
		-- Switches
		SW => SW(9 downto 6),
		-- Status Signal
		MZMODE => MZMODE,				-- Hardware Mode
		DMODE => DMODE					-- Display Mode
	);

	--
	-- MMC/SD CARD
	--
	SD_CMD<=SD_DO when SD_DEN(1)='0' else '1';
	SD_DAT3<=SD_CS;

	--
	-- SDRAM
	--
	DRAM_DQ<=SDRAMDO when SDRAMDOE='1' else (others=>'Z');

	--
	-- Flash Memory
	--
	FL_ADDR<='0'&FL_ADDR0(21 downto 1);
	FL_RST_N<=URST;
	FL_WP_N<='1';
	FL_BYTE_N<='1';

	--
	-- Filter and Asynchronous Reset with automatic
	--
	URST<='0' when BUF(9 downto 5)="00000" else '1';
	process( CLOCK_50_2 ) begin
		if( CLOCK_50_2'event and CLOCK_50_2='1' ) then
			BUF<=BUF(8 downto 0)&'1';
		end if;
	end process;

	process( URST, SCLK ) begin
		if URST='0' then
			CNT5<=(others=>'0');
			SR_BTN<=(others=>'1');
			ZR_BTN<=(others=>'1');
			FR_BTN<=(others=>'0');
		elsif SCLK'event and SCLK='1' then
			if CNT5="11111" then
				SR_BTN<=SR_BTN(6 downto 0)&(BUTTON(1) or (not BUTTON(0)));	-- only BUTTON1
				ZR_BTN<=ZR_BTN(6 downto 0)&((not BUTTON(1)) or BUTTON(0));	-- only BUTTON0
				FR_BTN<=FR_BTN(6 downto 0)&(BUTTON(1) or BUTTON(0));			-- both 0&1
				CNT5<=(others=>'0');
			else
				CNT5<=CNT5+'1';
			end if;
		end if;
	end process;
	F_BTN<='0' when SR_BTN="00000000" else '1';
	FRST<='0' when FR_BTN="00000000" else '1';
	ARST<=URST and FRST and MRST;
	ZRST<='0' when (ZR_BTN="00000000" and ZBACK='1') or ZCTRL(1)='0' else '1';

	--
	-- Misc
	--
	KBEN_M<=KBEN and (not ZBACK);
	LEDG<=(not SD_CS)&T_LEDG(8 downto 2)&ZLEDG(1 downto 0);
	--GPIO0_D(0)<=PS2_KBCLK;
	--GPIO0_D(1)<=PS2_KBDAT;
	--GPIO0_D(2)<=KBEN;
	--GPIO0_D(10 downto 3)<=KBDT;
	--GPIO0_D(11)<=ARST;

end rtl;
