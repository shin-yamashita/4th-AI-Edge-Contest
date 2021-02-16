
--
-- interval timer unit
--
-- 2011/08/18 disable br readback
-- 2011/08/21 br -> constant 1kHz, tmo for adc sync
-- 2012/12/18 clk freq change, br->register
-- 2020/03/08 br,brc 16->18bit (f_clk 100M)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--use work.pkg_optab.all;
--use work.pkg_sr_pu.all;
--use work.pkg_sr_dbg.all;

entity sr_timer is
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;
-- bus
	adr	: in  unsigned(4 downto 0);
	cs	: in  std_logic;
	rdy	: in  std_logic;
	we	: in  std_logic_vector(3 downto 0);
	re	: in  std_logic;
	irq	: out std_logic;
	dw	: in  unsigned(31 downto 0);
	dr	: out unsigned(31 downto 0);
-- port
	tmc	: out std_logic;
	tmo	: out std_logic
    );
end sr_timer;

architecture RTL of sr_timer is

-- Registers
signal adr1	: unsigned(4 downto 0);

--constant ibr	: integer := 30000;	--mm7t  1ms @ clk=30MHz
--constant ibr	: integer := 42000;	--mm7t  1ms @ clk=42MHz
constant ibr	: integer := 48000;	--mm7t  1ms @ clk=48MHz
signal br	: unsigned(17 downto 0);
signal brc	: unsigned(17 downto 0);

signal psc      : unsigned(3 downto 0);		-- prescaler 1/10 * 100MHz 
signal frc	: unsigned(31 downto 0);	-- free running counter
signal inte, irq0, tmoe, tm	: std_logic;

-- wire
signal cs0, re1	: std_logic;

begin

  cs0 <= cs;

  dr <=	(others => '0')	when re1 = '0'	else
	conv_unsigned(br, 32)		when adr1(4 downto 2) = 0	else
	conv_unsigned(brc, 32)		when adr1(4 downto 2) = 1	else
	"00000"&tmoe&inte&irq0&"00000000"&"00000000"&"00000000"
			when adr1(4 downto 2) = 2	else
	frc		when adr1(4 downto 2) = 3	else
	(others => '0');

  process
  variable virq0 : std_logic;
  begin
  wait until clk'event and clk = '1';
    if(rdy = '1') then
	re1 <= cs0 and re;
	adr1 <= adr;
    end if;

    if(xreset = '0') then
	br <= conv_unsigned(ibr ,18);
	brc <= conv_unsigned(0 ,18);
	frc <= conv_unsigned(0 ,32);
	psc <= (others => '0');
	inte <= '0';
	irq <= '0';
	irq0 <= '0';
	tm <= '0';
	tmoe <= '0';
    else
	virq0 := irq0;
	if(cs0 = '1') then
	    case (conv_integer(adr(4 downto 2))) is
	    when 16#0# =>
		if(we(1) = '1') then
			br(17 downto 8) <= dw(17 downto 8);
		end if;
		if(we(0) = '1') then
			br(7 downto 0) <= dw(7 downto 0);
		end if;
	    when 16#2# =>
		if(we(3) = '1') then			-- +8
			tmoe <= dw(26);			-- b2 : tmo enable
			inte <= dw(25);			-- b1 : int enable
			virq0 := virq0 and not dw(24);	-- b0 : clear irq
		end if;
	    when others => 	null;
	    end case;
	end if;

	if(psc = 9) then
	    psc <= (others => '0');
	    frc <= frc + 1;	-- countup 10 MHz
	else
	    psc <= psc + 1;
	end if;

	if(brc < br) then	-- interval timer counter
		brc <= brc + 1;
		tmo <= '0';	--mm6a
	else
		if(inte = '1') then
			virq0 := '1';
		end if;
		brc <= conv_unsigned(0 ,18);
	----	tm <= not tm and tmoe;
		tmo <= '1';	--mm6a
	end if;
	tmc <= brc(4);
	if(brc < 32) then
		tm <= tmoe;
	else
		tm <= '0';
	end if;

	irq0 <= virq0;
	irq <= irq0 and inte;
    end if;
  end process;
--mm6a  tmo <= tm;

end RTL;




