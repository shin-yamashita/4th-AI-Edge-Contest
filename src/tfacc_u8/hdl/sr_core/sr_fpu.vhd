--
-- sr_fpu.vhd
-- 2011/04
-- 2014/08/14 add divf
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.pkg_optab.all;
use work.pkg_sr_pu.all;

entity sr_fpu is
generic (
	divfen : boolean := true
    );
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;
	rdy	: in  std_logic;
	ex	: in  unsigned(4 downto 0);
	alu	: in  alu_code;
	rrd1	: in  unsigned(31 downto 0);
	rrd2	: in  unsigned(31 downto 0);
	ccfpu	: out unsigned(3 downto 0);
	rwdat	: out unsigned(31 downto 0)
    );
end sr_fpu;

architecture RTL of sr_fpu is

-- Registers
signal sgns	: std_logic;
signal exps	: unsigned(8 downto 0);
signal sigs	: unsigned(25 downto 0);
signal nan, inf, rfz	: boolean;

signal R, A, B	: unsigned(25 downto 0);	-- divf

-- wire

function is_nan(flt : unsigned) return boolean is
begin
	return (flt(30 downto 23) = 255) and (flt(22 downto 0) /= 0);
end;
function is_fzero(flt : unsigned) return boolean is
begin
	return (flt(30 downto 23) = 0) and (flt(22 downto 0) = 0);
end;
function is_inf(flt : unsigned) return boolean is
begin
	return (flt(30 downto 23) = 255) and (flt(22 downto 0) = 0);
end;

function leadingzero(ud : unsigned) return unsigned is
variable zr : unsigned(7 downto 0);
begin
	zr := (others => '0');
	for i in ud'high downto 0 loop
		if(ud(i) = '1') then
			return zr;
		else
			zr := zr + 1;
		end if;
	end loop;
	return zr;
end;

function sgned(rd : unsigned) return unsigned is
variable rv : unsigned(32 downto 0);
begin
	rv := rd(31)&rd;
	if(rd(30 downto 0) = 0) then
		rv := (others => '0');
	elsif(rd(31) = '1') then
		for i in 0 to 30 loop
			rv(i) := not rd(i);
		end loop;
	end if;
	return rv;
end;
signal nan1r, nan2r, inf1r, inf2r, fz1r, fz2r : boolean;

begin

  process
  variable nan1, nan2, inf1, inf2, fz1, fz2 : boolean;
  variable sgn1, sgn2, vsgns, rb : std_logic;
  variable exp1, exp2	: unsigned(7 downto 0);
  variable d		: unsigned(7 downto 0);
  variable vexps 	: unsigned(8 downto 0);
  variable sig1, sig2 	: unsigned(25 downto 0);
  variable vsigs	: unsigned(25 downto 0);
  variable fsigs	: unsigned(31 downto 0);
  variable msigs	: unsigned(47 downto 0);
  variable rd		: unsigned(32 downto 0);
  variable ccr		: unsigned(3 downto 0);
  variable vR, vA, vB	: unsigned(25 downto 0);	-- divf
  begin
  wait until clk'event and clk = '1';
	sgn1 := rrd1(31);
	sgn2 := rrd2(31);
	exp1 := rrd1(30 downto 23);
	exp2 := rrd2(30 downto 23);
	sig1 := "001" & rrd1(22 downto 0);
	sig2 := "001" & rrd2(22 downto 0);
	nan1 := is_nan(rrd1);
	fz1 := is_fzero(rrd1);
	inf1 := is_inf(rrd1);
	nan2 := is_nan(rrd2);
	fz2 := is_fzero(rrd2);
	inf2 := is_inf(rrd2);
	ccr := (others => '0');
    if(rdy = '1') then
    	case (alu) is
	when A_ADDF|A_SUBF =>
	  if(ex = 2) then
		nan <= nan1 or nan2 or inf1 or inf2;
		inf <= inf1 or inf2;
		if(alu = A_SUBF) then
			sgn1 := not sgn1;
		end if;
		rb := '0';
		if(exp1 > exp2) then
			d := exp1 - exp2;
			vexps := '0' & exp1;
			if(fz2 or d > 24) then
				sig2 := (others => '0');
			else
				rb := sig2(conv_integer(d)-1);
				sig2 := shr(sig2, d);
			end if;
		else
			d := exp2 - exp1;
			vexps := '0' & exp2;
			if(fz1 or d > 24) then
				sig1 := (others => '0');
			else
				if(d > 0) then
					rb := sig1(conv_integer(d)-1);
				end if;
				sig1 := shr(sig1, d);
			end if;
		end if;
		if(sgn1 = '1') then
			sig1 := 0-sig1;
		end if;
		if(sgn2 = '1') then
			sig2 := 0-sig2;
		end if;
		vsigs := sig1 + sig2 + rb;	-- add/sub
		if(vsigs(25) = '1') then	-- sigs < 0
			vsigs := 0-vsigs;
			vsgns := '1';
		else
			vsgns := '0';
		end if;
		sgns <= vsgns;
		exps <= vexps;
		sigs <= vsigs;
	  elsif(ex = 1) then
	  ----
		vsgns := sgns;
		vexps := exps;
		vsigs := sigs;
		if(vsigs = 0) then
			vexps := (others => '0');
		elsif(vsigs(24) = '1') then	-- normalize
			vsigs := ('0' & vsigs(25 downto 1)) + vsigs(0);
			vexps := vexps + 1;
		else
			d := leadingzero(vsigs) - 2;
			vexps := vexps - d;
			vsigs := shl(vsigs, d);
			if(vexps(8) = '1') then	-- underflow
				vexps := (others => '0');
				vsigs := (others => '0');
			end if;
		end if;
		if(nan) then
			vexps := (others => '1');
		end if;
		if(inf) then
			vsigs(22 downto 0) := (others => '0');
		end if;
		rwdat(31) <= vsgns;
		rwdat(30 downto 23) <= vexps(7 downto 0);
		rwdat(22 downto 0) <= vsigs(22 downto 0);
	  end if;
	when A_FLT|A_FLTU =>
	  if(ex = 1) then
		fsigs := rrd1;
		vsgns := '0';
		if(alu = A_FLT) then
			if(rrd1(31) = '1') then
				fsigs := 0 - rrd1;
				vsgns := '1';
			end if;
		end if;
		d := leadingzero(fsigs);
		vexps := conv_unsigned(127+31, 9) - d;
		if(d < 9) then
			d := 8 - d;	
			fsigs := shr(fsigs, d);
		else
			d := d - 8;
			fsigs := shl(fsigs, d);
		end if;
		if(fz1) then
			vexps := (others => '0');
		end if;
		rwdat(31) <= vsgns;
		rwdat(30 downto 23) <= vexps(7 downto 0);
		rwdat(22 downto 0) <= fsigs(22 downto 0);
	  end if;
	when A_MULF =>
	  if(ex = 1) then
		msigs := sig1(23 downto 0) * sig2(23 downto 0);
		if(msigs(47) = '1') then
			vsigs(22 downto 0) := msigs(46 downto 24) + msigs(23);
			vexps := ('0' & exp1) + exp2 + 1;
		elsif(msigs(45 downto 22) = 16#ffffff#) then	-- bugfix 121018
			vsigs(22 downto 0) := (others => '0');
			vexps := ('0' & exp1) + exp2 + 1;
		else
			vsigs(22 downto 0) := msigs(45 downto 23) + msigs(22);
			vexps := ('0' & exp1) + exp2;
		end if;
		if(vexps < 128) then	-- underflow
			vexps := (others => '0');
		elsif(vexps > 254+127) then	-- overflow
			vexps := (others => '1');
		else
			vexps := vexps - 127;
		end if;
		vsgns := sgn1 xor sgn2;

		if(fz1 or fz2) then
			vexps := (others => '0');
			vsigs(22 downto 0) := (others => '0');
		end if;
		if(inf1 or inf2) then
			vsigs(22 downto 0) := (others => '0');
		end if;
		if(nan1 or nan2 or inf1 or inf2) then
			vexps := (others => '1');
		end if;
		rwdat(31) <= vsgns;
		rwdat(30 downto 23) <= vexps(7 downto 0);
		rwdat(22 downto 0) <= vsigs(22 downto 0);
	  end if;
	when A_DIVF =>	-- rrd2 / rrd1
	  if(divfen) then
	    vB := B;
	    vA := A;
	    vR := R;
	    if(ex = 17) then
                vR := sig1;
                vB := sig2;
                vA := (others => '0');
		exps <= conv_unsigned(254, 9) + exp2 - exp1;
		sgns <= sgn1 xor sgn2;
		nan1r <= nan1;
		nan2r <= nan2;
		inf1r <= inf1;
		inf2r <= inf2;
		fz1r <= fz1;
		fz2r <= fz2; 
	    elsif(ex > 3) then
	        for i in 0 to 1 loop
	                if(vB >= vR) then
	                        vB := vB - vR;
	                        vA := vA(24 downto 0) & '1';
	                else
	                        vA := vA(24 downto 0) & '0';
	                end if;
			vB := vB(24 downto 0) & '0';
	        end loop;
	    end if;
	    B <= vB;
	    A <= vA;	-- q
	    R <= vR;
	    if(ex = 1) then
		if(A(25) = '1') then	--// 2.0 > q >= 1.0
		    vsigs := conv_unsigned(A(25 downto 2), 26) + A(1);
		    vexps := exps;
		else			--// 1.0 > q >= 0.5
		    vsigs := conv_unsigned(A(25 downto 1), 26) + A(0);
		    vexps := exps - 1;
		end if;
		if(vexps < 128) then	-- underflow
			vexps := (others => '0');
			vsigs(22 downto 0) := (others => '0');
		elsif(vexps > 254+127) then	-- overflow
			vexps := (others => '1');
			vsigs(22 downto 0) := (others => '0');
		else
			vexps := vexps - 127;
		end if;

		-- exceptions
		if((fz2r and fz1r) or (inf1r and inf2r)) then
			vexps := (others => '1');	-- 0/0, inf/inf => nan
			vsigs(22 downto 0) := (22 => '1', others => '0');
		elsif(fz2r or inf1r) then
			vexps := (others => '0');	-- 0/x, x/inf => 0
			vsigs(22 downto 0) := (others => '0');
		elsif(fz1r or inf2r) then
			vexps := (others => '1');	-- x/0, inf/x => inf
			vsigs(22 downto 0) := (others => '0');
		end if;
		if(nan1r or nan2r) then
			vexps := (others => '1');
			vsigs(22 downto 0) := (22 => '1', others => '0');
		end if;
		rwdat(31) <= sgns;
		rwdat(30 downto 23) <= vexps(7 downto 0);
		rwdat(22 downto 0) <= vsigs(22 downto 0);
	    end if;
	  end if;
	when A_FIX|A_FIXU =>
	  if(ex = 1) then
		fsigs := conv_unsigned(sig1, fsigs'length);
		d := conv_unsigned(23 + 127, 8) - exp1;
		if(d(7) = '0') then	-- d >= 0
			fsigs := shr(fsigs, d);
		else
			fsigs := shl(fsigs, 0-d);
		end if;
		if(sgn1 = '1') then
			if(alu = A_FIX) then
				fsigs := 0 - fsigs;
			else
				fsigs := (others => '0');
			end if;
		end if;
		rwdat <= fsigs;
	  end if;
	when A_CMPF =>
	  if(ex = 1) then
		rd := sgned(rrd2) - sgned(rrd1);
		ccr(0) := '0';		-- c
		ccr(1) := rd(32);	-- v
		ccr(2) := sel(rd(31 downto 0) = 0, '1', '0');	-- z
		ccr(3) := '0';		-- n
		rwdat <= (others => '0');
	  end if;
	when others =>
			null;
    	end case;
	ccfpu <= ccr;
    end if;
  end process;

end RTL;


