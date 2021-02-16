--
-- debug package for sr_dbg

library ieee, std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
Use ieee.std_logic_textio.all; 
use std.textio.all;
use work.pkg_optab.all;
--use work.pkg_sr_dbg.all;

package pkg_sr_dbg is

procedure putchar(c:in unsigned);

-- synopsys translate_off
procedure deb_print(
	count: in integer;
	pc:  in unsigned; ir  :in unsigned; 
	bra_stall: in std_logic; ex_stall:in unsigned; d_stall:in std_logic;
	mwe:in unsigned;  ofs:in signed; mar:in unsigned; mdr:in unsigned; mdw:in unsigned;
	rrd1:in unsigned; rrd2:in unsigned; alu:in alu_code; rwa:in unsigned; rwd:in opr_code;
	cc:  in unsigned; rwdat :in unsigned; r15:in unsigned; rp: in unsigned);

procedure deb_print_label;

file outfile : text is out "sr_dbg.out";
file putcfile : text is out "sr_putchar.out";
-- synopsys translate_on

end pkg_sr_dbg;



library ieee, std;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
Use ieee.std_logic_textio.all; 
use std.textio.all;
use work.pkg_optab.all;
--use work.pkg_sr_dbg.all;

package body pkg_sr_dbg is

procedure putchar(c:in unsigned) is
variable ostr : line;
begin
-- synopsys translate_off
	hwrite(ostr, std_logic_vector(c));
	writeline(putcfile, ostr);
-- synopsys translate_on
end;

-- synopsys translate_off
procedure deb_print(
	count: in integer;
	pc:  in unsigned; ir  :in unsigned; 
	bra_stall: in std_logic; ex_stall:in unsigned; d_stall:in std_logic;
	mwe:in unsigned;  ofs:in signed; mar:in unsigned;  mdr:in unsigned; mdw:in unsigned;
	rrd1:in unsigned; rrd2:in unsigned; alu:in alu_code; rwa:in unsigned; rwd:in opr_code;
	cc:  in unsigned; rwdat :in unsigned; r15:in unsigned; rp: in unsigned) is
variable ostr : line;
begin
--	write(ostr, count, right, 8);
	write(ostr, string'(" "));
	hwrite(ostr, std_logic_vector(pc), left, 9);
	write(ostr, string'(":"));
	hwrite(ostr, std_logic_vector(ir), left, 5);

	if(bra_stall = '1') then
		write(ostr, string'("-b- "));
	elsif(ex_stall /= 0) then
		write(ostr, string'("-x- "));
	elsif(d_stall = '1') then
		write(ostr, string'("-d- "));
	else
		write(ostr, string'("    "));
	end if;

	hwrite(ostr, std_logic_vector(mwe), left, 2);

	write(ostr, conv_integer(ofs), left, 5);

	hwrite(ostr, std_logic_vector(mar), left, 9);
	hwrite(ostr, std_logic_vector(mdr), left, 9);
	hwrite(ostr, std_logic_vector(mdw), left, 9);
	hwrite(ostr, std_logic_vector(rrd1), left, 9);
	hwrite(ostr, std_logic_vector(rrd2), left, 9);
	case(alu) is
	when A_NA   => write(ostr, string'("---- "));
	when A_AR1  => write(ostr, string'("ar1  "));
	when A_AR2  => write(ostr, string'("ar2  "));
	when A_ADD  => write(ostr, string'("add  "));
	when A_LSL  => write(ostr, string'("lsl  "));
	when A_ASR  => write(ostr, string'("asr  "));
	when A_LSR  => write(ostr, string'("lsr  "));
	when A_SUB  => write(ostr, string'("sub  "));
	when A_CMP  => write(ostr, string'("cmp  "));
	when A_LAND => write(ostr, string'("and  "));
	when A_OR   => write(ostr, string'("or   "));
	when A_EOR  => write(ostr, string'("eor  "));
	when A_MUL  => write(ostr, string'("mul  "));
	when A_MULU => write(ostr, string'("mulu "));
	when A_MULH => write(ostr, string'("mulh "));
	when A_MULUH=> write(ostr, string'("muluh"));
	when A_ADDC => write(ostr, string'("addc "));
	when A_NEG  => write(ostr, string'("neg  "));
	when A_NOT  => write(ostr, string'("not  "));
	when A_EXTB => write(ostr, string'("extb "));
	when A_EXTH => write(ostr, string'("exth "));
	when A_SXTB => write(ostr, string'("sxtb "));
	when A_SXTH => write(ostr, string'("sxth "));
	when A_DIV  => write(ostr, string'("div  "));
	when A_DIVU => write(ostr, string'("divu "));
	when A_MOD  => write(ostr, string'("mod  "));
	when A_MODU => write(ostr, string'("modu "));
	when A_ADDF => write(ostr, string'("addf "));
	when A_SUBF => write(ostr, string'("subf "));
	when A_MULF => write(ostr, string'("mulf "));
	when A_FLTU => write(ostr, string'("fltu "));
	when A_FLT  => write(ostr, string'("flt  "));
	when A_FIXU => write(ostr, string'("fixu "));
	when A_FIX  => write(ostr, string'("fix  "));
	when A_CMPF => write(ostr, string'("cmpf "));
	when others => write(ostr, string'("???? "));
	end case;
	write(ostr, conv_integer(rwa), left, 3);
	case(rwd) is
	when O_NA    => write(ostr, string'("--- "));
	when O_RJ    => write(ostr, string'("Rj  "));
	when O_RI    => write(ostr, string'("Ri  "));
	when O_RS1   => write(ostr, string'("Rs1 "));
	when O_RS2   => write(ostr, string'("Rs2 "));
	when O_R15   => write(ostr, string'("r15 "));
	when O_RP    => write(ostr, string'("rp  "));
	when O_RD    => write(ostr, string'("rd  "));
	when O_IMM   => write(ostr, string'("imm "));
	when O_UIMM  => write(ostr, string'("uimm"));
	when O_PINC  => write(ostr, string'("pinc"));
	when O_PDEC  => write(ostr, string'("pdec"));
	when O_MDR   => write(ostr, string'("mdr "));
	when O_RWD   => write(ostr, string'("rwd "));
	when O_RRD1  => write(ostr, string'("rd1 "));
	when O_WR    => write(ostr, string'("wr  "));
	when others  => write(ostr, string'("??? "));
	end case;
	hwrite(ostr, std_logic_vector(cc), left, 2);
	hwrite(ostr, std_logic_vector(rwdat), left, 9);
	hwrite(ostr, std_logic_vector(r15), left, 9);
	hwrite(ostr, std_logic_vector(rp), left, 9);
	writeline(outfile, ostr);
end;

procedure deb_print_label is
variable ostr : line;
begin
--	write(ostr, string'("         "));
	write(ostr, string'(" pc      :"));
	write(ostr, string'(" ir  "));
	write(ostr, string'("    "));
	write(ostr, string'("we"));
	write(ostr, string'(" ofs "));
	write(ostr, string'(" mar     "));
	write(ostr, string'(" mdr     "));
	write(ostr, string'(" mdw     "));
	write(ostr, string'(" rrd1    "));
	write(ostr, string'(" rrd2    "));
	write(ostr, string'("alu "));
	write(ostr, string'("rwa "));
	write(ostr, string'("rwd "));
	write(ostr, string'("cc "));
	write(ostr, string'("rwdat   "));
	write(ostr, string'(" r15     "));
	write(ostr, string'(" rp      "));
	writeline(outfile, ostr);
end;
-- synopsys translate_on
end pkg_sr_dbg;

