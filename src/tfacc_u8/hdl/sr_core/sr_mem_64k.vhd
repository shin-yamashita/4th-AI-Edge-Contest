--
-- 64kB RAM
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.pkg_optab.all;

entity sr_mem is
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;
	rdy	: in  std_logic;
-- Insn Bus
	i_adr	: in  unsigned(31 downto 0);
	i_dr	: out unsigned(31 downto 0);
	i_re	: in  std_logic;
-- Data Bus
	d_adr	: in  unsigned(31 downto 0);
	d_dw	: in  unsigned(31 downto 0);
	d_dr	: out unsigned(31 downto 0);
	d_we	: in  std_logic_vector(3 downto 0);
	d_re	: in  std_logic;
-- Peripheral Bus
        p_adr   : in  unsigned(31 downto 0);
        p_dw    : in  unsigned(31 downto 0);
        p_dr    : out unsigned(31 downto 0);
        p_we    : in  std_logic;
        p_re    : in  std_logic;
        p_ack   : out std_logic
    );
end sr_mem;

architecture RTL of sr_mem is

COMPONENT dpram64kB
  PORT (
    clka  : IN STD_LOGIC;
    ena   : IN STD_LOGIC;
    wea   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    dina  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    clkb  : IN STD_LOGIC;
    enb   : IN STD_LOGIC;
    web   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addrb : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
    dinb  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

-- Registers
-- wire
signal addra, addrb	: std_logic_vector(13 downto 0);
signal doa, dob		: std_logic_vector(31 downto 0);
signal dob2		: unsigned(31 downto 0);
signal dia, dib		: std_logic_vector(31 downto 0);
signal csa, csb	: std_logic;
signal csb2	: std_logic;
signal ena, enb	: std_logic;
signal wea, web	: std_logic_vector(3 downto 0);
signal d_re1	: std_logic;
signal i_re1	: std_logic;
signal den	: std_logic;

-- 
begin

  den <= (csb and xreset) when d_we /= 0 or d_re = '1'	else '0';	-- d-bus enable

  addra <= std_logic_vector(i_adr(15 downto 2));	-- long word addr
  addrb <= std_logic_vector(d_adr(15 downto 2))	when den = '1'	else
	   std_logic_vector(p_adr(15 downto 2));
  csa <= '1' 	when i_adr(31 downto 16) = 16#0000#	else '0';	-- bank 0000
  csb <= '1' 	when d_adr(31 downto 16) = 16#0000#	else '0';
  csb2 <= '1'	when p_adr(31 downto 16) = 16#0000#	else '0';
  ena <= i_re and rdy 	when csa = '1'	else '0';
  enb <= (csb or csb2) and rdy;
  wea <= (others => '0');
  web <= "0000"	when rdy = '0'	else
	d_we	when den = '1'	else
	"1111"	when p_we = '1' and csb2 = '1'	else 
	"0000";
  dia  <= (others => '0');
  dib  <= std_logic_vector(d_dw)	when den = '1' else
	  std_logic_vector(p_dw);


  i_dr <= unsigned(doa) when i_re1 = '1'	else (others => '0');
  d_dr <= unsigned(dob) when d_re1 = '1'	else (others => '0');
  p_dr <= unsigned(dob);
  p_ack <= (p_we or p_re) and not den;

  process
  begin
  wait until clk'event and clk = '1';
    if(rdy = '1') then
	d_re1 <= csb and d_re;
	i_re1 <= csa and i_re;
    end if;
  end process;

u_dpram64kB : dpram64kB
  PORT MAP (
    clka  => clk,    ena   => ena,    wea   => wea,
    addra => addra(13 downto 0),      dina  => dia,    douta => doa,
    clkb  => clk,    enb   => enb,    web   => web,
    addrb => addrb(13 downto 0),      dinb  => dib,    doutb => dob
  );

end RTL;


