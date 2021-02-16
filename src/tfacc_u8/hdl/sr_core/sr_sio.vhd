-- sr_sio.vhd
--  mini uart
--
-- 2011/02/11 add dtr/dsr
-- 2010/08/28 add rxe irq
-- 2011/08/18 disable br readback
-- 2016/01/09 add sndbrk reg

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

--use work.pkg_optab.all;
--use work.pkg_sr_pu.all;
use work.pkg_sr_dbg.all;

entity sr_sio is
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;
-- bus
	adr	: in  unsigned(4 downto 0);
	cs	: in  std_logic;
	rdy	: in  std_logic;	-- 111010
	we	: in  std_logic_vector(3 downto 0);
	re	: in  std_logic;
	irq	: out std_logic;
	dw	: in  unsigned(31 downto 0);
	dr	: out unsigned(31 downto 0);
-- port
	txd	: out std_logic;
	rxd	: in  std_logic;
	dsr	: in  std_logic;	-- add 110211 0:en
	dtr	: out std_logic;	-- add 110211 0:en

	txen	: out std_logic		-- add 120815
    );
end sr_sio;

architecture RTL of sr_sio is

-- Registers
type fifo is array (0 to 3) of unsigned(7 downto 0);

signal rfifo, tfifo : fifo;

signal rrp, rwp : unsigned(1 downto 0);
signal trp, twp : unsigned(1 downto 0);

signal tx, rx 	: unsigned(7 downto 0);
signal tbc, rbc	: unsigned(2 downto 0);
signal rxlp	: std_logic_vector(1 downto 0);
signal inte, irq0	: std_logic_vector(1 downto 0);	-- 080323

signal idsr	: std_logic;
signal sndbrk	: std_logic;

signal br, tbrc, rbrc : unsigned(13 downto 0);
-- wire
signal txf, rxe, rxf	: std_logic;
signal cs0, re1	: std_logic;

type state is (idle, startbit, trans, stopbit);
signal rst, tst : state;

begin

  cs0 <= '1' when cs = '1' and adr(4 downto 2) = 16#0#	else '0';

  dr <=	rfifo(conv_integer(rrp)) & 
	sndbrk & '0' & inte(1) & irq0(1) & inte(0) & irq0(0) & txf & rxe &
	"00" & br			when re1 = '1'	else
--	"00" & "00000000000000"		when re1 = '1'	else
	(others => '0');

  txf <= '1'	when (twp + 1) = trp	else '0';
  rxe <= '1'	when rwp = rrp		else '0';
  rxf <= '1'	when (rwp - rrp) > 1	else '0';

  irq0(1) <= '1'	when inte(1) = '1' and rxe = '0'	else '0';	-- 100828
  irq0(0) <= '1'	when inte(0) = '1' and txf = '0'	else '0';	-- 080323
  irq <= irq0(0) or irq0(1);

  process
  begin
  wait until clk'event and clk = '1';
    if(rdy = '1') then
    	re1 <= cs0 and re;
    end if;

    if(xreset = '0') then
	br <= conv_unsigned(10 ,14);
	rrp <= (others => '0');
	twp <= (others => '0');
	inte <= "00";
	sndbrk <= '0';
    else
	if(cs0 = '1' and rdy = '1') then
		if(we(3) = '1') then
			tfifo(conv_integer(twp)) <= dw(31 downto 24);	-- tx
		----	putchar(dw(31 downto 24));	-- for debug print
			twp <= twp + 1;
		end if;
		if(we(2) = '1' and dw(16) = '1') then
			rrp <= rrp + 1;
		end if;
		if(we(2) = '1') then
			sndbrk  <= dw(23);	-- 1: send break (txd --> 0)
			inte(1) <= dw(21);	-- 1: !RX-empty interrupt enable
			inte(0) <= dw(19);	-- 1: !TX-full interrupt enable
		end if;
		if(we(1) = '1') then
			br(13 downto 8) <= dw(13 downto 8);
		end if;
		if(we(0) = '1') then
			br(7 downto 0) <= dw(7 downto 0);
		end if;
	end if;
    end if;
  end process;

  process	-- tx
  begin
  wait until clk'event and clk = '1';
    if(xreset = '0') then
	tbrc <= (1 => '1', others => '0');
	txd <= '1';
	txen <= '0';
	trp <= (others => '0');
	tst <= idle;
	idsr <= '0';
    else
	if(tbrc = 1) then
	    idsr <= dsr;
	    tbrc <= br;
	    case tst is
	    when idle =>
		if(twp = trp or idsr = '1') then
		else
			tx <= tfifo(conv_integer(trp));
			trp <= trp + 1;
			tst <= startbit;
		end if;
	--	txd <= '1';
		txd <= not sndbrk;
		txen <= '0';
		tbc <= "000";
	    when startbit =>
		tst <= trans;
		txd <= '0';
		txen <= '1';
	    when trans =>
		tx <= '0' & tx(7 downto 1);
		txd <= tx(0);
		tbc <= tbc + 1;
		if(tbc = 7) then
			tst <= stopbit;
		end if;
	    when stopbit =>
		txd <= '1';
	--	txen <= '0';
		tst <= idle;
	    when others =>
		tst <= idle;
	    end case;
	else
		tbrc <= tbrc - 1;
	end if;
    end if;
  end process;

  process	-- rx
  begin
  wait until clk'event and clk = '1';
    rxlp <= rxlp(0) & rxd;
    dtr <= rxf;
    if(xreset = '0') then
	rbrc <= (1 => '1', others => '0');
	rst <= idle;
	rwp <= (others => '0');
    else
	if(rst = idle) then
		if(rxlp = "10") then	-- wait for start bit
			rbrc <= '0'&br(13 downto 1);
			rst <= startbit;
		end if;
	elsif(rbrc = 1) then
		rbrc <= br;
		case rst is
		when startbit =>
			rst <= trans;
			rbc <= "000";
		when trans =>
			rx <= rxlp(1) & rx(7 downto 1);	-- sampling
			rbc <= rbc + 1;
			if(rbc = 7) then
				rfifo(conv_integer(rwp)) <= rxlp(1) & rx(7 downto 1);
				rwp <= rwp + 1;
				rst <= idle;
			end if;
		when others => rst <= idle;
		end case;
	else
		rbrc <= rbrc - 1;
	end if;

    end if;
  end process;


end RTL;




