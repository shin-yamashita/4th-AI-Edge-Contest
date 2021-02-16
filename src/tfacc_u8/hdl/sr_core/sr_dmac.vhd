--
-- sr_dmac.vhd
--   
-- 2013/01/10
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity sr_dmac is
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;

-- bus in
	cs	: in  std_logic;

	m_adr	: in  unsigned(31 downto 0);
	m_rdy	: out std_logic;
	m_we	: in  std_logic_vector(3 downto 0);
	m_re	: in  std_logic;
	m_dw	: in  unsigned(31 downto 0);
	m_dr	: out unsigned(31 downto 0);

-- bus out
	d_adr	: out unsigned(31 downto 0);
	d_rdy	: in  std_logic;
	d_we	: out std_logic_vector(3 downto 0);
	d_re	: out std_logic;
	d_dw	: out unsigned(31 downto 0);
	d_dr	: in  unsigned(31 downto 0)
    );
end sr_dmac;

architecture RTL of sr_dmac is

-- Registers / wire

signal srcpt, dstpt	: unsigned(31 downto 0);
signal r_adr, w_adr	: unsigned(31 downto 0);
signal ddr		: unsigned(63 downto 0);
signal drh, w_dat	: unsigned(31 downto 0);
signal len 		: unsigned(15 downto 0);
signal rcnt, wcnt	: unsigned(15 downto 0);
signal bph		: unsigned(1 downto 0);
signal bwe		: std_logic_vector(3 downto 0);

signal re1, trig	: std_logic;
signal ren, ren1	: std_logic;
signal wen, men		: std_logic;
signal rinc, winc	: integer;

type state is (idle, pre, run, hold, term);
signal rst, wst 	: state;

begin

-- bus switch
-- m_* : master(sr_pu)   d_* : slave(periph / memory / cache)
  m_dr   <= d_dr  when re1 = '0' else
	    (24 => '1', others => '0') when rst /= idle else	-- dma busy flag
	    (others => '0');
  m_rdy  <= d_rdy;
  d_dw   <= w_dat when wen = '1' 	else m_dw;
  d_adr  <= r_adr when ren = '1' 	else
	    w_adr when wen = '1' 	else m_adr;
  d_we   <= bwe   when wen = '1'	else m_we;
  d_re   <= m_re or ren;

-- dmac control registers
  process
  variable vtrig : std_logic;
  begin
  wait until clk'event and clk = '1';
    vtrig := '0';

    if(d_rdy = '1') then
    	re1 <= cs and m_re;
    end if;

    if(xreset = '0') then
	trig <= '0';
    else
	if(cs = '1' and d_rdy = '1') then
	    case conv_integer(m_adr(4 downto 2)) is
	    when 0 =>
		if(m_we /= 0) then	-- +00 u32 source pointer
			srcpt <= m_dw;
		end if;
	    when 1 =>
		if(m_we /= 0) then	-- +04 u32 destination pointer
			dstpt <= m_dw;
		end if;
	    when 2 =>
		if(m_we /= 0) then	-- +0a u16 transfer length(byte)
			len <= m_dw(15 downto 0);
		end if;
	    when 3 =>
		if(m_we(3) = '1') then	-- +0c u8 bit0: dma start trigger
			vtrig := m_dw(24);
		end if;
	    when others => null;
	    end case;
	end if;
	if(vtrig = '1') then
		trig <= '1';
	elsif(rst = run) then
		trig <= '0';
	end if;
    end if;
  end process;

-- dmac 
  r_adr <= (srcpt(31 downto 2)&"00") + rcnt;	-- source address
  w_adr <= (dstpt + wcnt);			-- dest address
  bph <= srcpt(1 downto 0) - dstpt(1 downto 0);	-- src -> dst byte shift

  men <= '1' when m_we = 0 and m_re = '0' else '0';	-- dma usable cycle
  ren <= '1' when men = '1' and rst = run and wst /= run else '0';	-- dma read cycle
  wen <= '1' when men = '1' and wst = run	else '0';		-- dma write cycle
--  ren <= '1' when men = '1' and d_rdy = '1' and rst = run and wst /= run else '0';	-- dma read cycle
--  wen <= '1' when men = '1' and d_rdy = '1' and wst = run	else '0';		-- dma write cycle

  w_dat <= ddr(63 downto 32)	when bph = 0 else	-- dma write data
	   ddr(55 downto 24)	when bph = 1 else
	   ddr(47 downto 16)	when bph = 2 else
	   ddr(39 downto 8);--	when bph = 3
  ddr(31 downto 0) <= d_dr when ren1 = '1' else drh;	-- dma read buffer

  process
  variable modwc	: unsigned(1 downto 0);
  begin
  wait until clk'event and clk = '1';
    if(d_rdy = '1') then
    	ren1 <= ren;
    end if;
    if(ren = '1') then
	ddr(63 downto 32) <= ddr(31 downto 0);	-- push buffer
    end if;
    if(ren1 = '1') then
	drh <= d_dr;	-- read data hold
    end if;

    if(xreset = '0') then
	rst <= idle;
	wst <= idle;
    elsif(d_rdy = '1' and m_we = 0 and m_re = '0') then	-- dma sequencer
	case rst is
	when idle =>
		if(trig = '1') then
			rst <= run;
		end if;
		if(srcpt(1 downto 0) < dstpt(1 downto 0)) then
			rinc <= 0;
		else
			rinc <= 4;
		end if;
		rcnt <= (others => '0');
	when run =>
		if(wcnt + 4 >= len) then
			rst <= term;
		elsif(ren = '1') then
			rcnt <= rcnt + rinc;
			rinc <= 4;
		end if;
	when term =>
		if(wst = term) then
			rst <= idle;
			rcnt <= (others => '0');
		end if;
	when others => null;
	end case;
	case wst is
	when idle =>
		if(rst = run) then
			wst <= pre;
		end if;
		case dstpt(1 downto 0) is
		when "00"   => bwe <= "1111"; winc <= 4;
		when "01"   => bwe <= "0111"; winc <= 3;
		when "10"   => bwe <= "0011"; winc <= 2;
		when others => bwe <= "0001"; winc <= 1;
		end case;
		wcnt <= (others => '0');
	when pre =>
		wst <= run;
	when run =>
		wcnt <= wcnt + winc;
		winc <= 4;
		wst <= hold;
	when hold =>
		if(wcnt >= len) then
			wst <= term;
		else
			wst <= run;
		end if;
		modwc := len(1 downto 0) - wcnt(1 downto 0);
		if(len - wcnt < 4) then
			case modwc is
			when "00"   => bwe <= "0000";
			when "01"   => bwe <= "1000";
			when "10"   => bwe <= "1100";
			when others => bwe <= "1110";
			end case;
		else
			bwe <= "1111";
		end if;
	when term =>
		wst <= idle;
	end case;
    end if;
  end process;

end RTL;


