--
-- sr_core.vhd
--
-- 2015/09 -  
-- 2015/12/31 -  FP5/6  Ver-0 board uart rx port damaged --> FP6:rx FP5:sel
-- 2016/9/24     pin[5:4] = TX,TXD  for debug port connection check


library ieee, work, UNISIM;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use UNISIM.Vcomponents.ALL;

use work.pkg_sr_core.all;
use work.pkg_optab.all;
use work.pkg_sr_pu.all;
use work.pkg_sr_dbg.all;

entity sr_core is
    port (
	cclk	: in	std_logic;

	-- memory access bus
	p_adr	: in  unsigned(31 downto 0);
        p_we    : in  std_logic;
        p_re    : in  std_logic;
        p_dw    : in  unsigned(31 downto 0);
        p_dr    : out unsigned(31 downto 0);
	p_ack	: out std_logic;

	-- data bus
        xreset  : in  std_logic;
        adr     : out unsigned(31 downto 0);
        we      : out std_logic_vector(3 downto 0);
        re      : out std_logic;
        rdy     : in  std_logic;
        dw      : out unsigned(31 downto 0);
        dr      : in  unsigned(31 downto 0);

	-- debug port
	RXD	: out std_logic;	-- to debug terminal 
	TXD	: in  std_logic;	-- from debug terminal

	-- ext irq input
	eirq	: in  std_logic;

	-- para port out
	pout	: out unsigned(7 downto 0)
    );
    end sr_core;


architecture RTL of sr_core is

-- Registers
signal pout_i		: unsigned(7 downto 0);

signal rstcnt		: unsigned(7 downto 0) := (others => '0');

-- wire
signal xrst0, xrst	: std_logic;
signal xtxd, xrxd	: std_logic;
signal dsr, dtr, st0	: std_logic;

signal i_adr, i_dr	: unsigned(31 downto 0);
signal i_re, i_rdy	: std_logic;
signal d_adr, d_dw, d_dr: unsigned(31 downto 0);
signal d_dr0, d_dr1, d_dr2, d_dr3 : unsigned(31 downto 0);
signal d_we		: std_logic_vector(3 downto 0);
signal d_re, d_rdy	: std_logic;
signal rdy0, rdy1	: std_logic := '1';
signal irq		: unsigned(1 downto 0);
signal irq0, irq1	: std_logic;
signal cs_io		: std_logic;
signal cs_pout		: std_logic;
signal cs_timer		: std_logic;
signal cs_sio		: std_logic;
signal cs_dma		: std_logic;
signal pout_rd1		: std_logic;

signal m_adr, m_dw, m_dr: unsigned(31 downto 0);
signal m_we             : std_logic_vector(3 downto 0);
signal m_re, m_rdy      : std_logic;


function "or" (L, R:unsigned) return unsigned is
variable rv : unsigned(L'range);
begin
	for i in 0 to L'length-1 loop
		rv(i) := L(i) or R(i);
	end loop;
	return rv;
end;
-- 

begin

-- external bus connection
 adr <= d_adr;
 we <= d_we;
 re <= d_re;
 dw <= d_dw;
--        adr     : out unsigned(31 downto 0);
--        we      : out std_logic_vector(3 downto 0);
--        re      : out std_logic;
--        rdy     : in  std_logic;
--        dw      : out unsigned(31 downto 0);
--        dr      : in  unsigned(31 downto 0);


 process
 begin
 wait until cclk'event and cclk = '1';
  xrst0 <= xreset;
  if(xrst0 = '0') then
   xrst <= '0';
   rstcnt <= (others => '0');
  elsif(rstcnt < 255) then
   xrst <= '0';
   rstcnt <= rstcnt + 1;
  else
   xrst <= '1';
  end if;
 end process;

 pout <= pout_i;

 d_rdy <= rdy0 and rdy1 and rdy;

--
-- mm6 fpga-top

-- peripheral chip select
 cs_io	<= '1' when d_adr(31 downto 16) = 16#ffff#	else '0';

 cs_pout  <= '1' when cs_io = '1' and d_adr(15 downto 2) = 0	else '0';	-- ffff0000
 cs_sio   <= '1' when cs_io = '1' and d_adr(15 downto 5) = 1	else '0';	-- ffff0020
 cs_timer <= '1' when cs_io = '1' and d_adr(15 downto 5) = 2	else '0';	-- ffff0040
 cs_dma   <= '1' when cs_io = '1' and d_adr(15 downto 5) = 14   else '0';       -- ffff01c0

-- pararel port

 process
 begin
 wait until cclk'event and cclk = '1';
	if(d_rdy = '1') then
		pout_rd1 <= cs_pout and d_re;
	end if;
	if(xrst = '0') then
		pout_i <= (others => '0');
	elsif(cs_pout = '1') then
		if(d_we(3) = '1') then
			pout_i <= d_dw(31 downto 24);
			putchar(d_dw(31 downto 24));
		end if;
	end if;
 end process;

-- pin
 --       0    |  1   2   3
 d_dr1 <= pout_i & conv_unsigned(0, 24)	when pout_rd1 = '1'	else
	  (others => '0');
 
--  main memory
 u_sr_mem : sr_mem
 port map (
	clk	=> cclk,	xreset	=> xrst,	rdy	=> d_rdy,
	-- Instruction bus
	i_adr	=> i_adr,	i_dr	=> i_dr,	i_re	=> i_re,
	-- Data bus
	d_adr	=> d_adr,	d_dw	=> d_dw,	d_dr	=> d_dr0,
	d_we	=> d_we,	d_re	=> d_re,
	-- Peripheral bus
	p_adr	=> p_adr,	p_dw	=> p_dw,	p_dr	=> p_dr,
	p_we	=> p_we,	p_re	=> p_re,	p_ack	=> p_ack
	);

 d_dr <= d_dr0 or d_dr1 or d_dr2 or d_dr3 or dr;

 irq(0) <= irq0 or irq1;
 irq(1) <= eirq;

 i_rdy <= '1';

-- Processor core
 u_sr_pu : sr_pu
 generic map(
	debug 	=> true,
	fpu_en	=> false
	)
 port map (
	clk	=> cclk,		xreset	=> xrst,
	i_adr	=> i_adr,	i_dr	=> i_dr,	i_re	=> i_re,
	i_rdy	=> i_rdy,
	d_adr	=> d_adr,	d_dw	=> d_dw,	d_dr	=> d_dr,
	d_we	=> d_we,	d_re	=> d_re,	d_rdy	=> d_rdy,
--      d_adr   => m_adr,       d_dw    => m_dw,        d_dr    => m_dr,	-- enable dmac
--      d_we    => m_we,        d_re    => m_re,        d_rdy   => m_rdy,
	irq	=> irq
	);

-- Interval timer
 u_sr_timer: sr_timer PORT MAP(
	clk     => cclk,
	xreset  => xrst,	adr     => d_adr(4 downto 0),
	cs      => cs_timer,	rdy	=> d_rdy,
	we      => d_we,	re      => d_re,
	irq     => irq0,	dw      => d_dw,	dr      => d_dr2,
	tmc	=> open,	tmo     => open
	);

-- Asynchronous serial port
 st0 <= '0';
 u_sr_sio: sr_sio PORT MAP(	-- debug terminal
	clk     => cclk,
	xreset  => xrst,	adr     => d_adr(4 downto 0),
	cs      => cs_sio,	rdy	=> d_rdy,
	we      => d_we,	re      => d_re,
	irq     => irq1,	dw      => d_dw,	dr      => d_dr3,
	txd     => xtxd,	rxd     => xrxd,
	dsr	=> st0,		dtr	=> open
	);

  RXD <= not xtxd;					-- to cp2014 rx   160920 invert
  xrxd <= not TXD;  -- when FP(5) = '0' else not FP(6);	-- from cp2104 tx 151231 160920 invert

-- u_sr_dmac: sr_dmac
-- port map(
--        clk     => cclk,                xreset  => xrst,
--
---- bus in
--        cs      => cs_dma,
--
--        m_adr   => m_adr,       m_rdy   => m_rdy,
--        m_we    => m_we,        m_re    => m_re,
--        m_dw    => m_dw,        m_dr    => m_dr,
--
---- bus out       
--        d_adr   => d_adr,       d_rdy   => d_rdy,
--        d_we    => d_we,        d_re    => d_re,
--        d_dw    => d_dw,        d_dr    => d_dr
--    );


end RTL;


