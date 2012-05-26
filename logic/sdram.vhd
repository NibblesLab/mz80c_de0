--
-- sdram.vhd
--
-- SDRAM access module with self refresh and multi ports
-- for MZ-80C on FPGA
--
-- Nibbles Lab. 2007-2012
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity sdram is
	port (
		reset			: in std_logic;								-- Reset
		RSTOUT		: out std_logic;								-- Reset After Init. SDRAM
		CLOCK_50		: in std_logic;								-- Clock(50MHz)
		PCLK			: out std_logic;								-- NiosII system Clock
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
end sdram;

architecture rtl of sdram is

signal A : std_logic_vector(21 downto 0);
--signal DI : std_logic_vector(15 downto 0);
signal WCNT : std_logic_vector(2 downto 0);
signal CNT200 : std_logic;
signal CNT3 : std_logic_vector(2 downto 0);
--signal BUF    : std_logic_vector(7 downto 0);
signal CSAi   : std_logic;
signal CSAii  : std_logic_vector(3 downto 0);
signal CSBi   : std_logic;
signal CSBii  : std_logic_vector(3 downto 0);
signal CSCi   : std_logic;
signal CSCii  : std_logic_vector(3 downto 0);
signal CSDi   : std_logic;
signal CSDii  : std_logic_vector(3 downto 0);
signal REFCNT : std_logic_vector(10 downto 0);
signal PA : std_logic;
signal PB : std_logic;
signal PC : std_logic;
signal PD : std_logic;
signal WB : std_logic;
signal DAIR : std_logic_vector(15 downto 0);
signal DBIR : std_logic_vector(15 downto 0);
signal DCIR : std_logic_vector(15 downto 0);
signal DDIR : std_logic_vector(15 downto 0);
signal WAITB : std_logic;
signal WAITD : std_logic;
signal RDEN : std_logic;
signal WREN : std_logic;
signal UBEN : std_logic;
signal LBEN : std_logic;
signal RWAIT : std_logic;
signal MEMCLK : std_logic;
signal SCLKi : std_logic;
--
-- State Machine
--
signal CUR : std_logic_vector(5 downto 0);						-- Current Status
signal NXT : std_logic_vector(5 downto 0);						-- Next Status
constant IWAIT  : std_logic_vector(5 downto 0) := "000000";	-- 200us Wait
constant IPALL  : std_logic_vector(5 downto 0) := "000001";	-- All Bank Precharge
constant IDLY1  : std_logic_vector(5 downto 0) := "000010";	-- Initial Delay 1
constant IRFSH  : std_logic_vector(5 downto 0) := "000011";	-- Auto Refresh
constant IDLY2  : std_logic_vector(5 downto 0) := "000100";	-- Initial Delay 2
constant IDLY3  : std_logic_vector(5 downto 0) := "000101";	-- Initial Delay 3
constant IDLY4  : std_logic_vector(5 downto 0) := "000110";	-- Initial Delay 4
constant IDLY5  : std_logic_vector(5 downto 0) := "000111";	-- Initial Delay 5
constant IDLY6  : std_logic_vector(5 downto 0) := "001000";	-- Initial Delay 6
constant IMODE  : std_logic_vector(5 downto 0) := "001001";	-- Mode Register Setting
constant RACT   : std_logic_vector(5 downto 0) := "001010";	-- Read Activate
constant RDLY1  : std_logic_vector(5 downto 0) := "001011";	-- Read Delay 1
constant RDA    : std_logic_vector(5 downto 0) := "001100";	-- Read with Precharge
constant RDLY2  : std_logic_vector(5 downto 0) := "001101";	-- Read Delay 2
constant RDLY3  : std_logic_vector(5 downto 0) := "001110";	-- Read Delay 3
constant RDLY4  : std_logic_vector(5 downto 0) := "001111";	-- Read Delay 4
constant HALT   : std_logic_vector(5 downto 0) := "010000";	--	Waiting
constant WACT   : std_logic_vector(5 downto 0) := "010001";	-- Write Activate
constant WDLY1  : std_logic_vector(5 downto 0) := "010010";	-- Write Delay 1
constant WRA    : std_logic_vector(5 downto 0) := "010011";	-- Write with Precharge
constant WDLY2  : std_logic_vector(5 downto 0) := "010100";	-- Write Delay 2
constant WDLY3  : std_logic_vector(5 downto 0) := "010101";	-- Write Delay 3
constant FRFSH  : std_logic_vector(5 downto 0) := "010110";	-- Auto Refresh
constant FDLY1  : std_logic_vector(5 downto 0) := "010111";	-- Refresh Delay 1
constant FDLY2  : std_logic_vector(5 downto 0) := "011000";	-- Refresh Delay 2
constant FDLY3  : std_logic_vector(5 downto 0) := "011001";	-- Refresh Delay 3
constant FDLY4  : std_logic_vector(5 downto 0) := "011010";	-- Refresh Delay 4
constant WRACT  : std_logic_vector(5 downto 0) := "011011";	-- Read Activate
constant WRDLY1 : std_logic_vector(5 downto 0) := "011100";	-- Read Delay 1
constant WRDA   : std_logic_vector(5 downto 0) := "011101";	-- Read with Precharge
constant WRDLY2 : std_logic_vector(5 downto 0) := "011110";	-- Read Delay 2
constant WRDLY3 : std_logic_vector(5 downto 0) := "011111";	-- Read Delay 3
constant WRDLY4 : std_logic_vector(5 downto 0) := "100000";	-- Read Delay 4
constant WRDLY5 : std_logic_vector(5 downto 0) := "100001";	-- Read Delay 5
constant WRDLY6 : std_logic_vector(5 downto 0) := "100010";	-- Read Delay 6
constant WRDLY7 : std_logic_vector(5 downto 0) := "100011";	-- Read Delay 7
constant WWACT  : std_logic_vector(5 downto 0) := "100100";	-- Write Activate
constant WWDLY1 : std_logic_vector(5 downto 0) := "100101";	-- Write Delay 1
constant WWRA   : std_logic_vector(5 downto 0) := "100110";	-- Write with Precharge
constant WWDLY2 : std_logic_vector(5 downto 0) := "100111";	-- Write Delay 2
constant WWDLY3 : std_logic_vector(5 downto 0) := "101000";	-- Write Delay 3
constant WWDLY4 : std_logic_vector(5 downto 0) := "101001";	-- Write Delay 4
constant WWDLY5 : std_logic_vector(5 downto 0) := "101010";	-- Write Delay 5
constant WWDLY6 : std_logic_vector(5 downto 0) := "101011";	-- Write Delay 6
--
-- Components
--
component pll100
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
	RCKGEN0 : pll100 PORT MAP (
		inclk0	=> CLOCK_50,	-- Master Clock (50MHz) ... input
		c0	 => MEMCLK,				-- SDRAM Controler Clock (100MHz) ... internal use
		c1	 => MCLK,				-- SDRAM Clock (100MHz:-60deg) ... output
		c2	 => PCLK,				-- Nios II Clock (20MHz) ... output
		c3	 => SCLKi				-- Slow Clock (31.25kHz) ... internal use/output
	);

	--
	-- Seqence control
	--
	process( reset, MEMCLK ) begin
		if reset='0' then
			CUR<=IWAIT;			-- Start at Initial-Waiting(200us)
		elsif MEMCLK'event and MEMCLK='1' then
			CUR<=NXT;			-- Move to Next State
		end if;
	end process;

	--
	-- Arbitoration and Data Output
	--
	process( reset, MEMCLK ) begin
		if reset='0' then
			CSAi<='0';
			CSBi<='0';
			CSCi<='0';
			CSDi<='0';
			CSAii<=(others=>'1');
			CSBii<=(others=>'1');
			CSCii<=(others=>'1');
			CSDii<=(others=>'1');
			PA<='0';
			PB<='0';
			PC<='0';
			PD<='0';
			WAITB<='0';
			WAITD<='0';
		elsif MEMCLK'event and MEMCLK='1' then
			--
			-- Sense CS
			--
			CSAii<=CSAii(2 downto 0)&CSA;
			if CSAii="1000" then
				CSAi<='1';
				DAIR<=DAI;
			end if;
			CSBii<=CSBii(2 downto 0)&CSB;
			if CSBii="1000" then
				CSBi<='1';
				DBIR<=DBI;
				WAITB<='0';
			end if;
			CSCii<=CSCii(2 downto 0)&CSC;
			if CSCii="1000" then
				CSCi<='1';
				DCIR<=DCI;
			end if;
			CSDii<=CSDii(2 downto 0)&CSD;
			if CSDii="1000" then
				CSDi<='1';
				DDIR<=DDI;
				WAITD<='0';
			end if;

			--
			-- Select Response Port
			--
			if CUR=HALT then
				WAITB<='0';
				if CSAi='1' and PB='0' and PC='0' and PD='0' then
					PA<='1';
					RDEN<=WEA;
					WREN<=not WEA;
					UBEN<=BEA(1);
					LBEN<=BEA(0);
				elsif CSCi='1' and PA='0' and PB='0' and PD='0' then
					PC<='1';
					RDEN<=WEC;
					WREN<=not WEC;
					UBEN<=BEC(1);
					LBEN<=BEC(0);
				elsif CSBi='1' and PA='0' and PC='0' and PD='0' then
					PB<='1';
					RDEN<=WEB;
					WREN<=not WEB;
					UBEN<=BEB(1);
					LBEN<=BEB(0);
				elsif CSDi='1' and PA='0' and PB='0' and PC='0' then
					PD<='1';
					RDEN<=WED;
					WREN<=not WED;
					UBEN<=BED(1);
					LBEN<=BED(0);
				else
					PA<='0'; PB<='0'; PC<='0'; PD<='0';
					RDEN<='0';
					WREN<='0';
					UBEN<='1';
					LBEN<='1';
				end if;
			end if;

			--
			-- Deselect Port
			--
			if CUR=RDLY3 or CUR=WDLY2 or CUR=WRDLY3 or CUR=WWDLY2 then
				PA<='0'; PC<='0';
				RDEN<='0'; WREN<='0';
				if PA='1' then
					CSAi<='0';
				end if;
				if PB='1' then
					CSBi<='0';
					WAITB<='1';
				end if;
				if PC='1' then
					CSCi<='0';
				end if;
				if PD='1' then
					CSDi<='0';
					WAITD<='1';
				end if;
			end if;
			if CUR=WRDLY5 or CUR=WWDLY5 then
				PB<='0'; PD<='0';
				if PB='1' then
					CSBii<="1111";
				end if;
				if PD='1' then
					CSDii<="1111";
				end if;
			end if;

			--
			-- Data Output for Processor
			--
			if CUR=RDLY3 or CUR=WRDLY3 then		-- Ready for Data Output
				if PA='1' then
					DAO<=MDI;
				elsif PB='1' then
					DBO<=MDI;
				elsif PC='1' then
					DCO<=MDI;
--					DCO(31 downto 16)<=MDI;
				elsif PD='1' then
					DDO<=MDI;
				end if;
			end if;
--			if CUR=RDLY4 then
--				if PC='1' then
--					DCO(15 downto 0)<=MDI;
--				end if;
--			end if;

			--
			-- Data Output for SDRAM
			--
			if CUR=WACT or CUR=WWACT then
				if PA='1' then
					MDO<=DAIR;
				elsif PB='1' then
					MDO<=DBIR;
				elsif PC='1' then
					MDO<=DCIR;
				elsif PD='1' then
					MDO<=DDIR;
				end if;
			end if;
		end if;
	end process;

	--
	-- Round Robin
	--
--	process( RROBIN ) begin
--		case RROBIN is
--			when "00" =>
--				if CSAi='1' then
--					PA<='1'; PB<='0'; PC<='0';
--					RDEN<=WEA;
--					WREN<=not WEA;
--					NROBIN<="01";
--				elsif CSBi='1' then
--					PA<='0'; PB<='1'; PC<='0';
--					RDEN<=read;
--					WREN<=write;
--					NROBIN<="01";
--				elsif CSCi='1' then
--					PA<='0'; PB<='0'; PC<='1';
--					RDEN<=WEC;
--					WREN<=not WEC;
--					NROBIN<="01";
--				else
--					PA<='0'; PB<='0'; PC<='0';
--					RDEN<='0';
--					WREN<='0';
--					NROBIN<="00";
--				end if;
--			when "01" =>
--				if CSBi='1' then
--					PA<='0'; PB<='1'; PC<='0';
--					RDEN<=read;
--					WREN<=write;
--					NROBIN<="10";
--				elsif CSCi='1' then
--					PA<='0'; PB<='0'; PC<='1';
--					RDEN<=WEC;
--					WREN<=not WEC;
--					NROBIN<="10";
--				elsif CSAi='1' then
--					PA<='1'; PB<='0'; PC<='0';
--					RDEN<=WEA;
--					WREN<=not WEA;
--					NROBIN<="10";
--				else
--					PA<='0'; PB<='0'; PC<='0';
--					RDEN<='0';
--					WREN<='0';
--					NROBIN<="01";
--				end if;
--			when "10" =>
--				if CSCi='1' then
--					PA<='0'; PB<='0'; PC<='1';
--					RDEN<=WEC;
--					WREN<=not WEC;
--					NROBIN<="00";
--				elsif CSAi='1' then
--					PA<='1'; PB<='0'; PC<='0';
--					RDEN<=WEA;
--					WREN<=not WEA;
--					NROBIN<="00";
--				elsif CSBi='1' then
--					PA<='0'; PB<='1'; PC<='0';
--					RDEN<=read;
--					WREN<=write;
--					NROBIN<="00";
--				else
--					PA<='0'; PB<='0'; PC<='0';
--					RDEN<='0';
--					WREN<='0';
--					NROBIN<="10";
--				end if;
--			when others =>
--				PA<='0'; PB<='0'; PC<='0';
--				RDEN<='0';
--				WREN<='0';
--				NROBIN<="00";
--		end case;
--	end process;

	--
	-- Wait Control for NiosII
	--
	WQB<=CSB or WAITB;
	WQD<=CSD or WAITD;

	--
	-- Wait after Reset
	--
	process( reset, SCLKi ) begin			-- SCLKi=31.25kHz
		if reset='0' then
			WCNT<=(others=>'0');
			CNT200<='0';
		elsif SCLKi'event and SCLKi='1' then
			if WCNT="110" then
				CNT200<='1';
			else
				WCNT<=WCNT+1;
			end if;
		end if;
	end process;

	--
	-- Refresh Times Counter for Initialize (8 times)
	--
	process( reset, MEMCLK ) begin
		if reset='0' then
			CNT3<=(others=>'0');
		elsif MEMCLK'event and MEMCLK='1' then
			if CUR=IWAIT then
				CNT3<=(others=>'0');
			elsif CUR=IDLY3 then
				CNT3<=CNT3+1;
			end if;
		end if;
	end process;

	--
	-- Refresh Cycle Counter
	--
	process( reset, MEMCLK ) begin
		if reset='0' then
			REFCNT<=(others=>'0');
		elsif MEMCLK'event and MEMCLK='1' then
			if CUR=FRFSH then				-- Enter Refresh Command
				REFCNT<=(others=>'0');
			else
				REFCNT<=REFCNT+'1';
			end if;
		end if;
	end process;

	--
	-- Sequencer
	--
	process( CUR ) begin
		case CUR is
			-- Initialize
			when IWAIT =>	-- 200us Wait
				if CNT200='1' then
					NXT<=IPALL;
				else
					NXT<=IWAIT;
				end if;
			when IPALL =>	-- All Bank Precharge
				NXT<=IDLY1;
			when IDLY1 =>	-- Initial Delay 1
				NXT<=IRFSH;
			when IRFSH =>	-- Auto Refresh
				NXT<=IDLY2;
			when IDLY2 =>	-- Initial Delay 2
				NXT<=IDLY3;
			when IDLY3 =>	-- Initial Delay 2
				NXT<=IDLY4;
			when IDLY4 =>	-- Initial Delay 2
				NXT<=IDLY5;
			when IDLY5 =>	-- Initial Delay 2
				NXT<=IDLY6;
			when IDLY6 =>	-- Initial Delay 3
				if CNT3="111" then
					NXT<=IMODE;
				else
					NXT<=IDLY1;
				end if;
			when IMODE =>	-- Mode Register Setting
				NXT<=HALT;

			-- Read
			when RACT  =>	-- Read Activate
				NXT<=RDLY1;
			when RDLY1 =>	-- Read Delay 1
				NXT<=RDA;
			when RDA   =>	-- Read with Precharge
				NXT<=RDLY2;
			when RDLY2 =>	-- Read Delay 2
				NXT<=RDLY3;
			when RDLY3 =>	-- Read Delay 3
--				NXT<=RDLY4;
--			when RDLY4 =>	-- Read Delay 4
				NXT<=HALT;

			-- Read with wait
			when WRACT  =>	-- Read Activate
				NXT<=WRDLY1;
			when WRDLY1 =>	-- Read Delay 1
				NXT<=WRDA;
			when WRDA   =>	-- Read with Precharge
				NXT<=WRDLY2;
			when WRDLY2 =>	-- Read Delay 2
				NXT<=WRDLY3;
			when WRDLY3 =>	-- Read Delay 3
				NXT<=WRDLY4;
			when WRDLY4 =>	-- Read Delay 4
				NXT<=WRDLY5;
			when WRDLY5 =>	-- Read Delay 5
				NXT<=WRDLY6;
			when WRDLY6 =>	-- Read Delay 6
				NXT<=WRDLY7;
			when WRDLY7 =>	-- Read Delay 7
				NXT<=HALT;

			-- Waiting
			when HALT  =>	--	Waiting
				if REFCNT>"11000000100" then	-- Over 1540 Counts
					NXT<=FRFSH;
				elsif RDEN='1' then
					if PB='1' or PD='1' then
						NXT<=WRACT;
					else
						NXT<=RACT;
					end if;
				elsif WREN='1' then
					if PB='1' or PD='1' then
						NXT<=WWACT;
					else
						NXT<=WACT;
					end if;
				else
					NXT<=HALT;
				end if;

			-- Write
			when WACT  =>	-- Write Activate
				NXT<=WDLY1;
			when WDLY1 =>	-- Write Delay 1
				NXT<=WRA;
			when WRA   =>	-- Write with Precharge
				NXT<=WDLY2;
			when WDLY2 =>	-- Write Delay 2
				NXT<=WDLY3;
			when WDLY3 =>	-- Write Delay 3
				NXT<=HALT;

			-- Write with wait
			when WWACT  =>	-- Write Activate
				NXT<=WWDLY1;
			when WWDLY1 =>	-- Write Delay 1
				NXT<=WWRA;
			when WWRA   =>	-- Write with Precharge
				NXT<=WWDLY2;
			when WWDLY2 =>	-- Write Delay 2
				NXT<=WWDLY3;
			when WWDLY3 =>	-- Write Delay 3
				NXT<=WWDLY4;
			when WWDLY4 =>	-- Write Delay 4
				NXT<=WWDLY5;
			when WWDLY5 =>	-- Write Delay 5
				NXT<=WWDLY6;
			when WWDLY6 =>	-- Write Delay 6
				NXT<=HALT;

			-- Refresh
			when FRFSH =>	-- Auto Refresh
				NXT<=FDLY1;
			when FDLY1 =>	-- Refresh Delay 1
				NXT<=FDLY2;
			when FDLY2 =>	-- Refresh Delay 2
				NXT<=FDLY3;
			when FDLY3 =>	-- Refresh Delay 3
				NXT<=FDLY4;
			when FDLY4 =>	-- Refresh Delay 4
				NXT<=HALT;

			when others =>
				NXT<=HALT;
		end case;
	end process;

	--
	-- Command operation
	--
	process( CUR ) begin
		case CUR is
			when IMODE =>		-- Mode Register Setting
				MCS<='0';
				MRAS<='0';
				MCAS<='0';
				MWE<='0';
				MA<="0010" & "0" & "010" & "0" & "000";	-- w-single,CL=2,WT=0(seq),BL=1
				--MA<="0010" & "0" & "010" & "0" & "001";	-- w-single,CL=2,WT=0(seq),BL=2
				MDOE<='0';
				MLDQ<='1';
				MUDQ<='1';
			when RACT|WACT|WRACT|WWACT =>	-- Read/Write Activate
				MCS<='0';
				MRAS<='0';
				MCAS<='1';
				MWE<='1';
				MA<=A(19 downto 8);
				MDOE<='0';
				MLDQ<='1';
				MUDQ<='1';
			when IPALL =>		-- All Bank Precharge
				MCS<='0';
				MRAS<='0';
				MCAS<='1';
				MWE<='0';
				MA<="010000000000";
				MDOE<='0';
				MLDQ<='1';
				MUDQ<='1';
			when RDA|WRDA =>			-- Read with Precharge
				MCS<='0';
				MRAS<='1';
				MCAS<='0';
				MWE<='1';
				MA(11 downto 8)<="0100";	-- auto precharge
				--MA(11 downto 8)<="0000";	-- manual precharge
				MA(7 downto 0)<=A(7 downto 0);
				MDOE<='0';
				MLDQ<=LBEN;
				MUDQ<=UBEN;
			when WRA|WWRA =>			-- Write with Precharge
				MCS<='0';
				MRAS<='1';
				MCAS<='0';
				MWE<='0';
				MA(11 downto 8)<="0100";	-- auto precharge
				--MA(11 downto 8)<="0000";	-- manual precharge
				MA(7 downto 0)<=A(7 downto 0);
				MLDQ<=LBEN;
				MUDQ<=UBEN;
				MDOE<='1';
			when IRFSH|FRFSH =>		-- auto refresh
				MCS<='0';
				MRAS<='0';
				MCAS<='0';
				MWE<='1';
				MA<=(others=>'0');
				MDOE<='0';
				MLDQ<='1';
				MUDQ<='1';
			when others =>
				MCS<='1';
				MRAS<='1';
				MCAS<='1';
				MWE<='1';
				MA<=(others=>'0');
				MLDQ<='1';
				MUDQ<='1';
				MDOE<='0';
		end case;
	end process;

	--
	-- Reset Control
	--
	process( reset, MEMCLK ) begin
		if reset='0' then
			RSTOUT<='0';
		elsif MEMCLK'event and MEMCLK='1' then
			if CUR=HALT then
				RSTOUT<='1';
			end if;
		end if;
	end process;

	--
	-- SDRAM ports(Fixed Signals)
	--
	MCKE<='1';
	MBA0<=A(20);
	MBA1<=A(21);

	--
	-- Ports select
	--
	A <=AA when PA='1' else
		 AB when PB='1' else
		 AC when PC='1' else
		 AD when PD='1' else (others=>'0');
--	MDO<=DAIR when PA='1' and CUR=WRA else
--		DBIR when PB='1' and CUR=WRA else
--		DCIR when PC='1' and CUR=WRA else (others=>'0');

	--
	-- I/O ports
	--
	SCLK<=SCLKi;

end rtl;
