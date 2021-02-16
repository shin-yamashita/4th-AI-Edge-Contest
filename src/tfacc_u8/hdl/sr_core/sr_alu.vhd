--
-- 2013/6/20 extxx insn ccr <-> gcc extxx behavior dosen't match
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.pkg_optab.all;
use work.pkg_sr_pu.all;

entity sr_alu is
generic (
	fpu_en	: boolean := false
	);
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;
	rdy	: in  std_logic;
	ex	: in  unsigned(4 downto 0);
	alu	: in  alu_code;
	rrd1	: in  unsigned(31 downto 0);
	rrd2	: in  unsigned(31 downto 0);
	c	: in  std_logic;
	fcc	: out unsigned(3 downto 0);
	rwdat	: out unsigned(31 downto 0)
    );
end sr_alu;

architecture RTL of sr_alu is

-- Registers
signal R 	: unsigned(63 downto 0);
signal A, B 	: unsigned(31 downto 0);
signal sgn, msgn 	: std_logic;

-- wire
signal ccfpu	: unsigned(3 downto 0);
signal rwmul	: unsigned(31 downto 0);
signal rfpu	: unsigned(31 downto 0);

component sr_fpu 
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
	rdy     : in  std_logic;
        ex      : in  unsigned(4 downto 0);
        alu     : in  alu_code;
        rrd1    : in  unsigned(31 downto 0);
        rrd2    : in  unsigned(31 downto 0);
        ccfpu   : out unsigned(3 downto 0);
        rwdat   : out unsigned(31 downto 0)
    );
end component;

begin

  process(alu, rrd1, rrd2, c, sgn, A, msgn, B, rfpu, ccfpu)
  variable md : signed(62 downto 0);
  variable mdu : unsigned(63 downto 0);
  variable ccr : unsigned(3 downto 0);
  variable rs : unsigned(32 downto 0);
  begin
	ccr := "0000";
        case(alu) is
        when A_AR1  => rwdat <= rrd1;
        when A_AR2  => rwdat <= rrd2;
        when A_LSL  => rwdat <= shl(rrd2, rrd1(4 downto 0));
        when A_ASR  => rwdat <= unsigned(shr(signed(rrd2), rrd1(4 downto 0)));
        when A_LSR  => rwdat <= shr(rrd2, rrd1(4 downto 0));
        when A_SUB  => rwdat <= rrd2 - rrd1;
        when A_CMP  => rwdat <= (others => '0');
			rs := conv_unsigned(rrd2, 33) - conv_unsigned(rrd1, 33);
			ccr(3) := rs(31);		-- n
			ccr(2) := sel(rrd2 = rrd1, '1', '0');
			ccr(0) := rs(32);		-- c
			rs := conv_unsigned(signed(rrd2), 33) - conv_unsigned(signed(rrd1), 33);
			ccr(1) := rs(32) xor rs(31);	-- v

        when A_LAND => rwdat <= rrd2 and rrd1;
        when A_OR   => rwdat <= rrd2 or rrd1;
        when A_EOR  => rwdat <= rrd2 xor rrd1;

        when A_MUL  => rwdat <= rwmul;	-- ex:1
        when A_MULU => rwdat <= rwmul;
--        when A_MUL  => rwdat <= conv_unsigned(signed(rrd2) * signed(rrd1), 32);
--        when A_MULU => rwdat <= conv_unsigned(rrd2 * rrd1, 32);

        when A_MULH => rwdat <= conv_unsigned(signed(rrd2(15 downto 0)) * signed(rrd1(15 downto 0)), 32);
        when A_MULUH => rwdat <= conv_unsigned(rrd2(15 downto 0) * rrd1(15 downto 0), 32);
        when A_ADD  =>	rs := conv_unsigned(signed(rrd2), 33) + conv_unsigned(signed(rrd1), 33);
			rwdat <= rs(31 downto 0);
			ccr(3) := rs(31);		-- n
			ccr(2) := sel(rs(31 downto 0) = 0, '1', '0');
			ccr(1) := rs(32) xor rs(31);	-- v
			ccr(0) := rs(32);		-- c

        when A_ADDC => 	rwdat <= rrd2 + rrd1 + c;
        when A_NEG  => 	rwdat <= 0 - rrd1;
        when A_NOT  => 	rwdat <= not rrd1;
        when A_EXTB => 	rwdat <= conv_unsigned(rrd2(7 downto 0), 32);
		--	ccr(3) := '0';
		--	ccr(2) := sel(rrd2(7 downto 0) = 0, '1', '0');
        when A_EXTH => 	rwdat <= conv_unsigned(rrd2(15 downto 0), 32);
		--	ccr(3) := '0';
		--	ccr(2) := sel(rrd2(15 downto 0) = 0, '1', '0');
        when A_SXTB => 	rwdat <= unsigned(conv_signed(signed(rrd2(7 downto 0)), 32));
		--	ccr(3) := rrd2(7);
		--	ccr(2) := sel(rrd2(7 downto 0) = 0, '1', '0');
        when A_SXTH => 	rwdat <= unsigned(conv_signed(signed(rrd2(15 downto 0)), 32));
		--	ccr(3) := rrd2(15);
		--	ccr(2) := sel(rrd2(15 downto 0) = 0, '1', '0');

	when A_DIV  => 	rwdat <= sel(sgn = '0', A, 0 - A);
	--	       	rwdat <= sel(rrd1 = 0, conv_unsigned(0, 32),
	--		conv_unsigned(conv_integer(signed(rrd2)) / conv_integer(signed(rrd1)), 32));
	when A_DIVU => 	rwdat <= A;
	--	       	rwdat <= sel(rrd1 = 0, conv_unsigned(0, 32),
	--		conv_unsigned(conv_integer(rrd2) / conv_integer(rrd1), 32));
	when A_MOD  => 	rwdat <= sel(msgn = '0', B, 0 - B);
	--	       	rwdat <= sel(rrd1 = 0, conv_unsigned(0, 32),
	--		conv_unsigned(conv_integer(signed(rrd2)) mod conv_integer(signed(rrd1)), 32));
	when A_MODU => 	rwdat <= B;
	--	       	rwdat <= sel(rrd1 = 0, conv_unsigned(0, 32),
	--		conv_unsigned(conv_integer(rrd2) mod conv_integer(rrd1), 32));

	when A_ADDF|A_SUBF|A_MULF|A_DIVF|A_FLT|A_FLTU|A_FIX|A_FIXU|A_CMPF =>
			ccr := ccfpu;
			rwdat <= rfpu;
        when others => rwdat <= (others => 'X');
        end case;
	fcc <= ccr;
  end process;

 u_fpu : if(fpu_en) generate
  u_sr_fpu: sr_fpu 
  port map(
        clk     => clk,
        xreset  => xreset,
	rdy	=> rdy,
        ex      => ex,
        alu     => alu,
        rrd1    => rrd1,
        rrd2    => rrd2,
        ccfpu   => ccfpu,
        rwdat   => rfpu
    );
  end generate;

  process
  begin
  wait until clk'event and clk = '1';
  if(rdy = '1') then
    case (alu) is
        when A_MUL  => rwmul <= conv_unsigned(signed(rrd2) * signed(rrd1), 32);
        when A_MULU => rwmul <= conv_unsigned(rrd2 * rrd1, 32);
        when others => null;
    end case;
  end if;
  end process;

  process
  variable vR : unsigned(63 downto 0);
  variable vA, vB : unsigned(31 downto 0);
  begin
  wait until clk'event and clk = '1';
  if(rdy = '1') then
    vB := B;
    vA := A;
    vR := R;
    if(ex = 17) then
    	case (alu) is
    	when A_DIV|A_MOD =>
		sgn <= rrd1(31) xor rrd2(31);
		msgn <= rrd2(31);
		vR(63 downto 32) := sel(rrd1(31) = '1', 0 - rrd1, rrd1);
		vR(31 downto 0) := (others => '0');
		vB := sel(rrd2(31) = '1', 0 - rrd2, rrd2);
		vA := (others => '0');
    	when A_DIVU|A_MODU =>
		sgn <= '0';
		msgn <= '0';
		vR(63 downto 32) := rrd1;
		vR(31 downto 0) := (others => '0');
		vB := rrd2;
		vA := (others => '0');
    	when others => null;
    	end case;
    elsif(ex > 0) then
	for i in 0 to 1 loop
		vR := '0' & vR(63 downto 1);
		if(vR(63 downto 32) = 0 and vB >= vR(31 downto 0)) then
			vB := vB - vR(31 downto 0);
			vA := vA(30 downto 0) & '1';
		else
			vA := vA(30 downto 0) & '0';
		end if;
	end loop;
    end if;
    B <= vB;
    A <= vA;
    R <= vR;
  end if;
  end process;


end RTL;


