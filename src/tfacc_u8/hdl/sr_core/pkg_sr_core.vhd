--
-- 2015/08/23
-- 2020/03/01
-- package for sr_core
-- component decl

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package pkg_sr_core is

component sr_mem
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
	rdy	: in  std_logic;
-- Insn Bus
        i_adr   : in  unsigned(31 downto 0);
        i_dr    : out unsigned(31 downto 0);
        i_re    : in  std_logic;
-- Data Bus
        d_adr   : in  unsigned(31 downto 0);
        d_dw    : in  unsigned(31 downto 0);
        d_dr    : out unsigned(31 downto 0);
        d_we    : in  std_logic_vector(3 downto 0);
        d_re    : in  std_logic;
-- Peripheral Bus
        p_adr   : in  unsigned(31 downto 0);
        p_dw    : in  unsigned(31 downto 0);
        p_dr    : out unsigned(31 downto 0);
        p_we    : in  std_logic;
        p_re    : in  std_logic;
        p_ack   : out std_logic
    );
end component;

component sr_pu 
generic (
	debug : boolean := true;
	fpu_en : boolean := false
    );
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
-- Insn Bus
        i_adr   : out unsigned(31 downto 0);
        i_dr    : in  unsigned(31 downto 0);
        i_re    : out std_logic;
        i_rdy   : in  std_logic;
-- Data Bus
        d_adr   : out unsigned(31 downto 0);
        d_dw    : out unsigned(31 downto 0);
        d_dr    : in  unsigned(31 downto 0);
        d_we    : out std_logic_vector(3 downto 0);
        d_re    : out std_logic;
        d_rdy   : in  std_logic;
-- Interrupt
        irq     : in  unsigned(1 downto 0)
    );
end component;

component sr_sio
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
-- bus
        adr     : in  unsigned(4 downto 0);
        cs      : in  std_logic;
        rdy     : in  std_logic;
        we      : in  std_logic_vector(3 downto 0);
        re      : in  std_logic;
        irq     : out std_logic;
        dw      : in  unsigned(31 downto 0);
        dr      : out unsigned(31 downto 0);
-- port
        txd     : out std_logic;
        rxd     : in  std_logic;
        dsr     : in  std_logic;        -- add 110211 0:en
        dtr     : out std_logic;        -- add 110211 0:en
	txen	: out std_logic		-- add 120815
    );
end component;

component sr_timer
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
-- bus
        adr     : in  unsigned(4 downto 0);
        cs      : in  std_logic;
        rdy     : in  std_logic;
        we      : in  std_logic_vector(3 downto 0);
        re      : in  std_logic;
        irq     : out std_logic;
        dw      : in  unsigned(31 downto 0);
        dr      : out unsigned(31 downto 0);
-- port
        tmc     : out std_logic;
        tmo     : out std_logic
    );
end component;

component sr_dmac
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;

-- bus in
        cs      : in  std_logic;

        m_adr   : in  unsigned(31 downto 0);
        m_rdy   : out std_logic;
        m_we    : in  std_logic_vector(3 downto 0);
        m_re    : in  std_logic;
        m_dw    : in  unsigned(31 downto 0);
        m_dr    : out unsigned(31 downto 0);

-- bus out
        d_adr   : out unsigned(31 downto 0);
        d_rdy   : in  std_logic;
        d_we    : out std_logic_vector(3 downto 0);
        d_re    : out std_logic;
        d_dw    : out unsigned(31 downto 0);
        d_dr    : in  unsigned(31 downto 0)
    );
end component;

end pkg_sr_core;


