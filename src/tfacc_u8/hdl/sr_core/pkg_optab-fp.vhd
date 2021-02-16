-- sr-processor opcode table
--       (genarated by srsim/ophdlgen)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package pkg_optab is

type imm_code is (I_NA
        ,I_U4   ,I_S8   ,I_U8   ,I_U5   ,I_S5   ,I_D9   ,I_D10  ,I_V8);

type opr_code is (O_NA
        ,O_RJ   ,O_RI   ,O_RS1  ,O_RS2  ,O_R15  ,O_RP   ,O_RD
        ,O_IMM  ,O_UIMM ,O_PINC ,O_PDEC
        ,O_MDR  ,O_RWD  ,O_RRD1 ,O_WR);

type spf_code is (S_NA
        ,S_POPM ,S_PUSHM,S_INT  ,S_JMP  ,S_CALL ,S_BCC  ,S_ADDSP,S_RET
        ,S_RTI);

type alu_code is (A_NA
        ,A_AR1 ,A_AR2   ,A_ADD  ,A_LSL  ,A_ASR  ,A_LSR  ,A_SUB  ,A_CMP
        ,A_LAND ,A_OR   ,A_EOR  ,A_MUL  ,A_MULU ,A_MULH ,A_MULUH
        ,A_ADDC ,A_NEG  ,A_NOT  ,A_EXTB ,A_EXTH ,A_SXTB ,A_SXTH ,A_DIV
        ,A_DIVU ,A_MOD  ,A_MODU 
        ,A_ADDF ,A_SUBF ,A_MULF ,A_FLT  ,A_FLTU ,A_FIX  ,A_FIXU, A_SQRT, A_DIVF, A_CMPF);

type optab is record
        immcd   : imm_code;
        len     : unsigned(1 downto 0);
        ex      : unsigned(4 downto 0);
        spfunc  : spf_code;
        mode    : unsigned(2 downto 0);
        mar     : opr_code;
        ofs     : opr_code;
        mwe     : opr_code;
        rrd1    : opr_code;
        rrd2    : opr_code;
        rwa     : opr_code;
        rwd     : opr_code;
        alu     : alu_code;
        dl      : boolean;
end record;

function opcdec(ir : unsigned) return optab;

end pkg_optab;



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.pkg_optab.all;

package body pkg_optab is

function opcdec(ir : unsigned) return optab is
variable op : optab;
begin
  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.immcd := I_U4;
  when 16#3# => op.immcd := I_U4;
  when 16#4# => op.immcd := I_S8;
  when 16#5# => op.immcd := I_S8;
  when 16#6# => op.immcd := I_S8;
  when 16#7# => op.immcd := I_S8;
  when 16#8# => op.immcd := I_S8;
  when 16#9# => op.immcd := I_S8;
  when 16#a# => op.immcd := I_U8;
  when 16#b# => op.immcd := I_S8;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.immcd := I_U5;
    when 16#61# => op.immcd := I_U5;
    when 16#62# => op.immcd := I_U5;
    when 16#63# => op.immcd := I_U5;
    when 16#64# => op.immcd := I_S5;
    when 16#65# => op.immcd := I_S5;
    when 16#66# => op.immcd := I_S5;
    when 16#67# => op.immcd := I_S5;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#e0# => op.immcd := I_D9;
      when 16#e1# => op.immcd := I_D9;
      when 16#e2# => op.immcd := I_D9;
      when 16#e3# => op.immcd := I_D9;
      when 16#e4# => op.immcd := I_D9;
      when 16#e5# => op.immcd := I_D9;
      when 16#e6# => op.immcd := I_D9;
      when 16#e7# => op.immcd := I_D9;
      when 16#e8# => op.immcd := I_D9;
      when 16#e9# => op.immcd := I_D9;
      when 16#ea# => op.immcd := I_D9;
      when 16#eb# => op.immcd := I_D10;
      when 16#ef# => op.immcd := I_V8;
      when 16#f0# => op.immcd := I_D9;
      when 16#f1# => op.immcd := I_D9;
      when 16#f2# => op.immcd := I_D9;
      when 16#f3# => op.immcd := I_D9;
      when 16#f4# => op.immcd := I_D9;
      when 16#f5# => op.immcd := I_D9;
      when 16#f6# => op.immcd := I_D9;
      when 16#f7# => op.immcd := I_D9;
      when 16#f8# => op.immcd := I_D9;
      when 16#f9# => op.immcd := I_D9;
      when 16#fa# => op.immcd := I_D9;
      when others =>
		op.immcd := I_NA;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 8))) is
  when 16#8# => op.len := "10";
  when 16#1# => op.len := "10";
  when 16#2# => op.len := "10";
  when 16#18# => op.len := "10";
  when 16#11# => op.len := "10";
  when 16#12# => op.len := "10";
  when others =>
    case(conv_integer(ir(15 downto 4))) is
    when 16#fe0# => op.len := "10";
    when 16#fe1# => op.len := "10";
    when 16#fe2# => op.len := "10";
    when 16#fe3# => op.len := "10";
    when 16#fe5# => op.len := "10";
    when 16#fe6# => op.len := "10";
    when 16#fe7# => op.len := "10";
    when 16#fe8# => op.len := "11";
    when 16#fe9# => op.len := "10";
    when 16#fef# => op.len := "11";
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#feb0# => op.len := "11";
      when 16#fec0# => op.len := "11";
      when 16#fed0# => op.len := "11";
      when 16#fee0# => op.len := "11";
      when others =>
		op.len := "01";
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 8))) is
  when 16#3# => op.ex := "00001";
  when 16#13# => op.ex := "00001";
  when 16#d1# => op.ex := "00001";
  when 16#d3# => op.ex := "00001";
  when 16#ec# => op.ex := "10001";
  when 16#ed# => op.ex := "10001";
  when 16#ef# => op.ex := "00011";
  when 16#fc# => op.ex := "10001";
  when 16#fd# => op.ex := "10001";
  when 16#5# => op.ex := "00010";
  when 16#6# => op.ex := "00010";
  when 16#c# => op.ex := "00001";
  when 16#10# => op.ex := "00001";
  when 16#15# => op.ex := "00001";
  when 16#16# => op.ex := "00001";
  when 16#1c# => op.ex := "00001";
  when 16#1f# => op.ex := "10001";
  when 16#ee# => op.ex := "10001";
  when 16#fb# => op.ex := "00001";
  when others =>
    case(conv_integer(ir(15 downto 0))) is
    when 16#fff4# => op.ex := "00010";
    when others =>
		op.ex := "00000";
    end case;
  end case;

  case(conv_integer(ir(15 downto 8))) is
  when 16#3# => op.spfunc := S_POPM;
  when 16#13# => op.spfunc := S_PUSHM;
  when 16#e0# => op.spfunc := S_BCC;
  when 16#e1# => op.spfunc := S_BCC;
  when 16#e2# => op.spfunc := S_BCC;
  when 16#e3# => op.spfunc := S_BCC;
  when 16#e4# => op.spfunc := S_BCC;
  when 16#e5# => op.spfunc := S_BCC;
  when 16#e6# => op.spfunc := S_BCC;
  when 16#e7# => op.spfunc := S_BCC;
  when 16#e8# => op.spfunc := S_BCC;
  when 16#e9# => op.spfunc := S_BCC;
  when 16#ea# => op.spfunc := S_BCC;
  when 16#eb# => op.spfunc := S_ADDSP;
  when 16#ef# => op.spfunc := S_INT;
  when 16#f0# => op.spfunc := S_BCC;
  when 16#f1# => op.spfunc := S_BCC;
  when 16#f2# => op.spfunc := S_BCC;
  when 16#f3# => op.spfunc := S_BCC;
  when 16#f4# => op.spfunc := S_BCC;
  when 16#f5# => op.spfunc := S_BCC;
  when 16#f6# => op.spfunc := S_BCC;
  when 16#f7# => op.spfunc := S_BCC;
  when 16#f8# => op.spfunc := S_BCC;
  when 16#f9# => op.spfunc := S_BCC;
  when 16#fa# => op.spfunc := S_BCC;
  when others =>
    case(conv_integer(ir(15 downto 4))) is
    when 16#fe5# => op.spfunc := S_JMP;
    when 16#fe6# => op.spfunc := S_JMP;
    when 16#ffb# => op.spfunc := S_CALL;
    when 16#ffc# => op.spfunc := S_CALL;
    when 16#ffd# => op.spfunc := S_JMP;
    when 16#ffe# => op.spfunc := S_JMP;
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#feb0# => op.spfunc := S_CALL;
      when 16#fec0# => op.spfunc := S_CALL;
      when 16#fed0# => op.spfunc := S_JMP;
      when 16#fee0# => op.spfunc := S_JMP;
      when 16#fff2# => op.spfunc := S_RET;
      when 16#fff3# => op.spfunc := S_RET;
      when 16#fff4# => op.spfunc := S_RTI;
      when others =>
		op.spfunc := S_NA;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.mode := "100";
  when 16#3# => op.mode := "100";
  when 16#4# => op.mode := "100";
  when 16#5# => op.mode := "100";
  when 16#6# => op.mode := "010";
  when 16#7# => op.mode := "010";
  when 16#8# => op.mode := "001";
  when 16#9# => op.mode := "001";
  when 16#a# => op.mode := "100";
  when 16#b# => op.mode := "100";
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.mode := "100";
    when 16#61# => op.mode := "100";
    when 16#62# => op.mode := "100";
    when 16#63# => op.mode := "100";
    when 16#64# => op.mode := "100";
    when 16#65# => op.mode := "100";
    when 16#66# => op.mode := "100";
    when 16#67# => op.mode := "100";
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#8# => op.mode := "100";
      when 16#1# => op.mode := "010";
      when 16#2# => op.mode := "001";
      when 16#3# => op.mode := "100";
      when 16#4# => op.mode := "100";
      when 16#7# => op.mode := "100";
      when 16#9# => op.mode := "010";
      when 16#a# => op.mode := "001";
      when 16#b# => op.mode := "100";
      when 16#d# => op.mode := "100";
      when 16#e# => op.mode := "100";
      when 16#f# => op.mode := "100";
      when 16#18# => op.mode := "100";
      when 16#11# => op.mode := "010";
      when 16#12# => op.mode := "001";
      when 16#13# => op.mode := "100";
      when 16#14# => op.mode := "100";
      when 16#17# => op.mode := "100";
      when 16#19# => op.mode := "010";
      when 16#1a# => op.mode := "001";
      when 16#1b# => op.mode := "100";
      when 16#d0# => op.mode := "100";
      when 16#d1# => op.mode := "100";
      when 16#d2# => op.mode := "100";
      when 16#d3# => op.mode := "100";
      when 16#d4# => op.mode := "100";
      when 16#d5# => op.mode := "100";
      when 16#d6# => op.mode := "100";
      when 16#d7# => op.mode := "010";
      when 16#d8# => op.mode := "100";
      when 16#d9# => op.mode := "100";
      when 16#da# => op.mode := "100";
      when 16#db# => op.mode := "100";
      when 16#dc# => op.mode := "100";
      when 16#dd# => op.mode := "100";
      when 16#de# => op.mode := "100";
      when 16#df# => op.mode := "100";
      when 16#eb# => op.mode := "100";
      when 16#ec# => op.mode := "100";
      when 16#ed# => op.mode := "100";
      when 16#ef# => op.mode := "100";
      when 16#fc# => op.mode := "100";
      when 16#fd# => op.mode := "100";
      when 16#5# => op.mode := "100";
      when 16#6# => op.mode := "100";
      when 16#c# => op.mode := "100";
      when 16#10# => op.mode := "100";
      when 16#15# => op.mode := "100";
      when 16#16# => op.mode := "100";
      when 16#1c# => op.mode := "100";
      when 16#1f# => op.mode := "100";
      when 16#ee# => op.mode := "100";
      when 16#fb# => op.mode := "100";
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe0# => op.mode := "100";
        when 16#fe1# => op.mode := "100";
        when 16#fe2# => op.mode := "100";
        when 16#fe3# => op.mode := "100";
        when 16#fe7# => op.mode := "100";
        when 16#fe8# => op.mode := "100";
        when 16#fe9# => op.mode := "100";
        when 16#fef# => op.mode := "100";
        when 16#ff0# => op.mode := "100";
        when 16#ff1# => op.mode := "100";
        when 16#ff2# => op.mode := "100";
        when 16#ff3# => op.mode := "100";
        when others =>
          case(conv_integer(ir(15 downto 0))) is
          when 16#fff4# => op.mode := "100";
          when others =>
		op.mode := "000";
          end case;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.mar := O_RJ;
  when 16#3# => op.mar := O_RJ;
  when 16#4# => op.mar := O_R15;
  when 16#5# => op.mar := O_R15;
  when 16#6# => op.mar := O_R15;
  when 16#7# => op.mar := O_R15;
  when 16#8# => op.mar := O_R15;
  when 16#9# => op.mar := O_R15;
  when others =>
    case(conv_integer(ir(15 downto 8))) is
    when 16#8# => op.mar := O_RJ;
    when 16#1# => op.mar := O_RJ;
    when 16#2# => op.mar := O_RJ;
    when 16#3# => op.mar := O_R15;
    when 16#4# => op.mar := O_RJ;
    when 16#7# => op.mar := O_RJ;
    when 16#9# => op.mar := O_RJ;
    when 16#a# => op.mar := O_RJ;
    when 16#b# => op.mar := O_RJ;
    when 16#18# => op.mar := O_RJ;
    when 16#11# => op.mar := O_RJ;
    when 16#12# => op.mar := O_RJ;
    when 16#13# => op.mar := O_R15;
    when 16#14# => op.mar := O_RJ;
    when 16#17# => op.mar := O_RJ;
    when 16#19# => op.mar := O_RJ;
    when 16#1a# => op.mar := O_RJ;
    when 16#1b# => op.mar := O_RJ;
    when 16#ef# => op.mar := O_R15;
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#fff4# => op.mar := O_R15;
      when others =>
		op.mar := O_NA;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.ofs := O_UIMM;
  when 16#3# => op.ofs := O_UIMM;
  when 16#4# => op.ofs := O_IMM;
  when 16#5# => op.ofs := O_IMM;
  when 16#6# => op.ofs := O_IMM;
  when 16#7# => op.ofs := O_IMM;
  when 16#8# => op.ofs := O_IMM;
  when 16#9# => op.ofs := O_IMM;
  when others =>
    case(conv_integer(ir(15 downto 8))) is
    when 16#8# => op.ofs := O_IMM;
    when 16#1# => op.ofs := O_IMM;
    when 16#2# => op.ofs := O_IMM;
    when 16#3# => op.ofs := O_PINC;
    when 16#4# => op.ofs := O_PINC;
    when 16#7# => op.ofs := O_PINC;
    when 16#18# => op.ofs := O_IMM;
    when 16#11# => op.ofs := O_IMM;
    when 16#12# => op.ofs := O_IMM;
    when 16#13# => op.ofs := O_PDEC;
    when 16#14# => op.ofs := O_PDEC;
    when 16#17# => op.ofs := O_PDEC;
    when 16#ef# => op.ofs := O_PDEC;
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#fff4# => op.ofs := O_PINC;
      when others =>
		op.ofs := O_NA;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.mwe := O_RD;
  when 16#3# => op.mwe := O_RI;
  when 16#4# => op.mwe := O_RD;
  when 16#5# => op.mwe := O_RI;
  when 16#6# => op.mwe := O_RD;
  when 16#7# => op.mwe := O_RI;
  when 16#8# => op.mwe := O_RD;
  when 16#9# => op.mwe := O_RI;
  when others =>
    case(conv_integer(ir(15 downto 8))) is
    when 16#8# => op.mwe := O_RD;
    when 16#1# => op.mwe := O_RD;
    when 16#2# => op.mwe := O_RD;
    when 16#3# => op.mwe := O_RD;
    when 16#4# => op.mwe := O_RD;
    when 16#7# => op.mwe := O_RD;
    when 16#9# => op.mwe := O_RD;
    when 16#a# => op.mwe := O_RD;
    when 16#b# => op.mwe := O_RD;
    when 16#18# => op.mwe := O_RI;
    when 16#11# => op.mwe := O_RI;
    when 16#12# => op.mwe := O_RI;
    when 16#13# => op.mwe := O_RJ;
    when 16#14# => op.mwe := O_RI;
    when 16#17# => op.mwe := O_RS2;
    when 16#19# => op.mwe := O_RI;
    when 16#1a# => op.mwe := O_RI;
    when 16#1b# => op.mwe := O_RS2;
    when 16#ef# => op.mwe := O_RP;
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#fff4# => op.mwe := O_RD;
      when others =>
		op.mwe := O_NA;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#a# => op.rrd1 := O_UIMM;
  when 16#b# => op.rrd1 := O_IMM;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.rrd1 := O_UIMM;
    when 16#61# => op.rrd1 := O_UIMM;
    when 16#62# => op.rrd1 := O_UIMM;
    when 16#63# => op.rrd1 := O_UIMM;
    when 16#64# => op.rrd1 := O_IMM;
    when 16#65# => op.rrd1 := O_IMM;
    when 16#66# => op.rrd1 := O_IMM;
    when 16#67# => op.rrd1 := O_IMM;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#d# => op.rrd1 := O_RJ;
      when 16#e# => op.rrd1 := O_RS1;
      when 16#f# => op.rrd1 := O_RJ;
      when 16#d0# => op.rrd1 := O_RJ;
      when 16#d1# => op.rrd1 := O_RJ;
      when 16#d2# => op.rrd1 := O_RJ;
      when 16#d3# => op.rrd1 := O_RJ;
      when 16#d4# => op.rrd1 := O_RJ;
      when 16#d5# => op.rrd1 := O_RJ;
      when 16#d6# => op.rrd1 := O_RJ;
      when 16#d7# => op.rrd1 := O_RJ;
      when 16#d8# => op.rrd1 := O_RJ;
      when 16#d9# => op.rrd1 := O_RJ;
      when 16#da# => op.rrd1 := O_RJ;
      when 16#db# => op.rrd1 := O_RJ;
      when 16#dc# => op.rrd1 := O_RJ;
      when 16#dd# => op.rrd1 := O_RJ;
      when 16#de# => op.rrd1 := O_RJ;
      when 16#df# => op.rrd1 := O_RJ;
      when 16#e0# => op.rrd1 := O_IMM;
      when 16#e1# => op.rrd1 := O_IMM;
      when 16#e2# => op.rrd1 := O_IMM;
      when 16#e3# => op.rrd1 := O_IMM;
      when 16#e4# => op.rrd1 := O_IMM;
      when 16#e5# => op.rrd1 := O_IMM;
      when 16#e6# => op.rrd1 := O_IMM;
      when 16#e7# => op.rrd1 := O_IMM;
      when 16#e8# => op.rrd1 := O_IMM;
      when 16#e9# => op.rrd1 := O_IMM;
      when 16#ea# => op.rrd1 := O_IMM;
      when 16#eb# => op.rrd1 := O_IMM;
      when 16#ec# => op.rrd1 := O_RJ;
      when 16#ed# => op.rrd1 := O_RJ;
      when 16#ef# => op.rrd1 := O_UIMM;
      when 16#f0# => op.rrd1 := O_IMM;
      when 16#f1# => op.rrd1 := O_IMM;
      when 16#f2# => op.rrd1 := O_IMM;
      when 16#f3# => op.rrd1 := O_IMM;
      when 16#f4# => op.rrd1 := O_IMM;
      when 16#f5# => op.rrd1 := O_IMM;
      when 16#f6# => op.rrd1 := O_IMM;
      when 16#f7# => op.rrd1 := O_IMM;
      when 16#f8# => op.rrd1 := O_IMM;
      when 16#f9# => op.rrd1 := O_IMM;
      when 16#fa# => op.rrd1 := O_IMM;
      when 16#fc# => op.rrd1 := O_RJ;
      when 16#fd# => op.rrd1 := O_RJ;
      when 16#5# => op.rrd1 := O_RJ;
      when 16#6# => op.rrd1 := O_RJ;
      when 16#c# => op.rrd1 := O_RJ;
      when 16#10# => op.rrd1 := O_RJ;
      when 16#15# => op.rrd1 := O_RJ;
      when 16#16# => op.rrd1 := O_RJ;
      when 16#1c# => op.rrd1 := O_RJ;
      when 16#1f# => op.rrd1 := O_RJ;
      when 16#ee# => op.rrd1 := O_RJ;
      when 16#fb# => op.rrd1 := O_RJ;
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe0# => op.rrd1 := O_IMM;
        when 16#fe1# => op.rrd1 := O_IMM;
        when 16#fe2# => op.rrd1 := O_IMM;
        when 16#fe3# => op.rrd1 := O_IMM;
        when 16#fe5# => op.rrd1 := O_IMM;
        when 16#fe6# => op.rrd1 := O_IMM;
        when 16#fe7# => op.rrd1 := O_IMM;
        when 16#fe8# => op.rrd1 := O_IMM;
        when 16#fe9# => op.rrd1 := O_UIMM;
        when 16#fef# => op.rrd1 := O_IMM;
        when others =>
          case(conv_integer(ir(15 downto 0))) is
          when 16#feb0# => op.rrd1 := O_IMM;
          when 16#fec0# => op.rrd1 := O_IMM;
          when 16#fed0# => op.rrd1 := O_IMM;
          when 16#fee0# => op.rrd1 := O_IMM;
          when others =>
		op.rrd1 := O_NA;
          end case;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#b# => op.rrd2 := O_RI;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.rrd2 := O_RI;
    when 16#61# => op.rrd2 := O_RI;
    when 16#62# => op.rrd2 := O_RI;
    when 16#63# => op.rrd2 := O_RI;
    when 16#64# => op.rrd2 := O_RI;
    when 16#65# => op.rrd2 := O_RI;
    when 16#66# => op.rrd2 := O_RI;
    when 16#67# => op.rrd2 := O_RI;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#d0# => op.rrd2 := O_RI;
      when 16#d1# => op.rrd2 := O_RI;
      when 16#d2# => op.rrd2 := O_RI;
      when 16#d3# => op.rrd2 := O_RI;
      when 16#d4# => op.rrd2 := O_RI;
      when 16#d5# => op.rrd2 := O_RI;
      when 16#d6# => op.rrd2 := O_RI;
      when 16#d7# => op.rrd2 := O_RI;
      when 16#d8# => op.rrd2 := O_RI;
      when 16#d9# => op.rrd2 := O_RI;
      when 16#da# => op.rrd2 := O_RI;
      when 16#db# => op.rrd2 := O_RI;
      when 16#dc# => op.rrd2 := O_RI;
      when 16#dd# => op.rrd2 := O_RI;
      when 16#de# => op.rrd2 := O_RI;
      when 16#df# => op.rrd2 := O_RI;
      when 16#eb# => op.rrd2 := O_R15;
      when 16#ec# => op.rrd2 := O_RI;
      when 16#ed# => op.rrd2 := O_RI;
      when 16#fc# => op.rrd2 := O_RI;
      when 16#fd# => op.rrd2 := O_RI;
      when 16#5# => op.rrd2 := O_RI;
      when 16#6# => op.rrd2 := O_RI;
      when 16#c# => op.rrd2 := O_RI;
      when 16#10# => op.rrd2 := O_RI;
      when 16#15# => op.rrd2 := O_RI;
      when 16#16# => op.rrd2 := O_RI;
      when 16#1c# => op.rrd2 := O_RI;
      when 16#1f# => op.rrd2 := O_RI;
      when 16#ee# => op.rrd2 := O_RI;
      when 16#fb# => op.rrd2 := O_RI;
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe0# => op.rrd2 := O_RI;
        when 16#fe1# => op.rrd2 := O_RI;
        when 16#fe2# => op.rrd2 := O_RI;
        when 16#fe3# => op.rrd2 := O_RI;
        when 16#fe7# => op.rrd2 := O_RI;
        when 16#fe8# => op.rrd2 := O_RI;
        when 16#fe9# => op.rrd2 := O_RI;
        when 16#fef# => op.rrd2 := O_RI;
        when 16#ff0# => op.rrd2 := O_RI;
        when 16#ff1# => op.rrd2 := O_RI;
        when 16#ff2# => op.rrd2 := O_RI;
        when 16#ff3# => op.rrd2 := O_RI;
        when 16#ffb# => op.rrd2 := O_RI;
        when 16#ffc# => op.rrd2 := O_RI;
        when 16#ffd# => op.rrd2 := O_RI;
        when 16#ffe# => op.rrd2 := O_RI;
        when others =>
          case(conv_integer(ir(15 downto 0))) is
          when 16#fff2# => op.rrd2 := O_RP;
          when 16#fff3# => op.rrd2 := O_RP;
          when others =>
		op.rrd2 := O_NA;
          end case;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.rwa := O_RI;
  when 16#4# => op.rwa := O_RI;
  when 16#6# => op.rwa := O_RI;
  when 16#8# => op.rwa := O_RI;
  when 16#a# => op.rwa := O_RI;
  when 16#b# => op.rwa := O_RI;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.rwa := O_RI;
    when 16#61# => op.rwa := O_RI;
    when 16#62# => op.rwa := O_RI;
    when 16#63# => op.rwa := O_RI;
    when 16#65# => op.rwa := O_RI;
    when 16#66# => op.rwa := O_RI;
    when 16#67# => op.rwa := O_RI;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#8# => op.rwa := O_RI;
      when 16#1# => op.rwa := O_RI;
      when 16#2# => op.rwa := O_RI;
      when 16#3# => op.rwa := O_RJ;
      when 16#4# => op.rwa := O_RI;
      when 16#7# => op.rwa := O_RS2;
      when 16#9# => op.rwa := O_RI;
      when 16#a# => op.rwa := O_RI;
      when 16#b# => op.rwa := O_RS2;
      when 16#d# => op.rwa := O_RI;
      when 16#e# => op.rwa := O_RI;
      when 16#f# => op.rwa := O_RS2;
      when 16#d0# => op.rwa := O_RI;
      when 16#d1# => op.rwa := O_RI;
      when 16#d2# => op.rwa := O_RI;
      when 16#d3# => op.rwa := O_RI;
      when 16#d4# => op.rwa := O_RI;
      when 16#d5# => op.rwa := O_RI;
      when 16#d6# => op.rwa := O_RI;
      when 16#d7# => op.rwa := O_RI;
      when 16#d9# => op.rwa := O_RI;
      when 16#da# => op.rwa := O_RI;
      when 16#db# => op.rwa := O_RI;
      when 16#dc# => op.rwa := O_RI;
      when 16#dd# => op.rwa := O_RI;
      when 16#de# => op.rwa := O_RI;
      when 16#df# => op.rwa := O_RI;
      when 16#eb# => op.rwa := O_R15;
      when 16#ec# => op.rwa := O_RI;
      when 16#ed# => op.rwa := O_RI;
      when 16#fc# => op.rwa := O_RI;
      when 16#fd# => op.rwa := O_RI;
      when 16#5# => op.rwa := O_RI;
      when 16#6# => op.rwa := O_RI;
      when 16#c# => op.rwa := O_RI;
      when 16#10# => op.rwa := O_RI;
      when 16#15# => op.rwa := O_RI;
      when 16#16# => op.rwa := O_RI;
      when 16#1c# => op.rwa := O_RI;
      when 16#1f# => op.rwa := O_RI;
      when 16#ee# => op.rwa := O_RI;
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe1# => op.rwa := O_RI;
        when 16#fe2# => op.rwa := O_RI;
        when 16#fe3# => op.rwa := O_RI;
        when 16#fe7# => op.rwa := O_RI;
        when 16#fe8# => op.rwa := O_RI;
        when 16#fe9# => op.rwa := O_RI;
        when 16#fef# => op.rwa := O_RI;
        when 16#ff0# => op.rwa := O_RI;
        when 16#ff1# => op.rwa := O_RI;
        when 16#ff2# => op.rwa := O_RI;
        when 16#ff3# => op.rwa := O_RI;
        when others =>
          case(conv_integer(ir(15 downto 0))) is
          when 16#fff4# => op.rwa := O_RP;
          when others =>
		op.rwa := O_NA;
          end case;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#2# => op.rwd := O_MDR;
  when 16#4# => op.rwd := O_MDR;
  when 16#6# => op.rwd := O_MDR;
  when 16#8# => op.rwd := O_MDR;
  when 16#a# => op.rwd := O_RWD;
  when 16#b# => op.rwd := O_RWD;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.rwd := O_RWD;
    when 16#61# => op.rwd := O_RWD;
    when 16#62# => op.rwd := O_RWD;
    when 16#63# => op.rwd := O_RWD;
    when 16#65# => op.rwd := O_RWD;
    when 16#66# => op.rwd := O_RWD;
    when 16#67# => op.rwd := O_RWD;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#8# => op.rwd := O_MDR;
      when 16#1# => op.rwd := O_MDR;
      when 16#2# => op.rwd := O_MDR;
      when 16#3# => op.rwd := O_MDR;
      when 16#4# => op.rwd := O_MDR;
      when 16#7# => op.rwd := O_MDR;
      when 16#9# => op.rwd := O_MDR;
      when 16#a# => op.rwd := O_MDR;
      when 16#b# => op.rwd := O_MDR;
      when 16#d# => op.rwd := O_RWD;
      when 16#e# => op.rwd := O_RWD;
      when 16#f# => op.rwd := O_RWD;
      when 16#d0# => op.rwd := O_RWD;
      when 16#d1# => op.rwd := O_RWD;
      when 16#d2# => op.rwd := O_RWD;
      when 16#d3# => op.rwd := O_RWD;
      when 16#d4# => op.rwd := O_RWD;
      when 16#d5# => op.rwd := O_RWD;
      when 16#d6# => op.rwd := O_RWD;
      when 16#d7# => op.rwd := O_RWD;
      when 16#d9# => op.rwd := O_RWD;
      when 16#da# => op.rwd := O_RWD;
      when 16#db# => op.rwd := O_RWD;
      when 16#dc# => op.rwd := O_RWD;
      when 16#dd# => op.rwd := O_RWD;
      when 16#de# => op.rwd := O_RWD;
      when 16#df# => op.rwd := O_RWD;
      when 16#eb# => op.rwd := O_RWD;
      when 16#ec# => op.rwd := O_RWD;
      when 16#ed# => op.rwd := O_RWD;
      when 16#fc# => op.rwd := O_RWD;
      when 16#fd# => op.rwd := O_RWD;
      when 16#5# => op.rwd := O_RWD;
      when 16#6# => op.rwd := O_RWD;
      when 16#c# => op.rwd := O_RWD;
      when 16#10# => op.rwd := O_RWD;
      when 16#15# => op.rwd := O_RWD;
      when 16#16# => op.rwd := O_RWD;
      when 16#1c# => op.rwd := O_RWD;
      when 16#1f# => op.rwd := O_RWD;
      when 16#ee# => op.rwd := O_RWD;
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe1# => op.rwd := O_RWD;
        when 16#fe2# => op.rwd := O_RWD;
        when 16#fe3# => op.rwd := O_RWD;
        when 16#fe7# => op.rwd := O_RWD;
        when 16#fe8# => op.rwd := O_RRD1;
        when 16#fe9# => op.rwd := O_RRD1;
        when 16#fef# => op.rwd := O_RWD;
        when 16#ff0# => op.rwd := O_RWD;
        when 16#ff1# => op.rwd := O_RWD;
        when 16#ff2# => op.rwd := O_RWD;
        when 16#ff3# => op.rwd := O_RWD;
        when others =>
          case(conv_integer(ir(15 downto 0))) is
          when 16#fff4# => op.rwd := O_MDR;
          when others =>
		op.rwd := O_NA;
          end case;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 12))) is
  when 16#a# => op.alu := A_AR1;
  when 16#b# => op.alu := A_ADD;
  when others =>
    case(conv_integer(ir(15 downto 9))) is
    when 16#60# => op.alu := A_LSL;
    when 16#61# => op.alu := A_ASR;
    when 16#62# => op.alu := A_LSR;
    when 16#63# => op.alu := A_SUB;
    when 16#64# => op.alu := A_CMP;
    when 16#65# => op.alu := A_LAND;
    when 16#66# => op.alu := A_OR;
    when 16#67# => op.alu := A_EOR;
    when others =>
      case(conv_integer(ir(15 downto 8))) is
      when 16#d# => op.alu := A_AR1;
      when 16#e# => op.alu := A_AR1;
      when 16#f# => op.alu := A_AR1;
      when 16#d0# => op.alu := A_LSL;
      when 16#d1# => op.alu := A_MUL;
      when 16#d2# => op.alu := A_ASR;
      when 16#d3# => op.alu := A_MULU;
      when 16#d4# => op.alu := A_LSR;
      when 16#d5# => op.alu := A_MULH;
      when 16#d6# => op.alu := A_SUB;
      when 16#d7# => op.alu := A_MULUH;
      when 16#d8# => op.alu := A_CMP;
      when 16#d9# => op.alu := A_ADD;
      when 16#da# => op.alu := A_LAND;
      when 16#db# => op.alu := A_ADDC;
      when 16#dc# => op.alu := A_OR;
      when 16#dd# => op.alu := A_NEG;
      when 16#de# => op.alu := A_EOR;
      when 16#df# => op.alu := A_NOT;
      when 16#eb# => op.alu := A_ADD;
      when 16#ec# => op.alu := A_DIV;
      when 16#ed# => op.alu := A_DIVU;
      when 16#fc# => op.alu := A_MOD;
      when 16#fd# => op.alu := A_MODU;
      when 16#5# => op.alu := A_ADDF;
      when 16#6# => op.alu := A_SUBF;
      when 16#c# => op.alu := A_MULF;
      when 16#10# => op.alu := A_FLT;
      when 16#15# => op.alu := A_FLTU;
      when 16#16# => op.alu := A_FIX;
      when 16#1c# => op.alu := A_FIXU;
      when 16#1f# => op.alu := A_SQRT;
      when 16#ee# => op.alu := A_DIVF;
      when 16#fb# => op.alu := A_CMPF;
      when others =>
        case(conv_integer(ir(15 downto 4))) is
        when 16#fe0# => op.alu := A_CMP;
        when 16#fe1# => op.alu := A_LAND;
        when 16#fe2# => op.alu := A_OR;
        when 16#fe3# => op.alu := A_EOR;
        when 16#fe7# => op.alu := A_ADD;
        when 16#fe8# => op.alu := A_AR1;
        when 16#fe9# => op.alu := A_AR1;
        when 16#fef# => op.alu := A_ADD;
        when 16#ff0# => op.alu := A_EXTB;
        when 16#ff1# => op.alu := A_EXTH;
        when 16#ff2# => op.alu := A_SXTB;
        when 16#ff3# => op.alu := A_SXTH;
        when others =>
		op.alu := A_NA;
        end case;
      end case;
    end case;
  end case;

  case(conv_integer(ir(15 downto 8))) is
  when 16#f0# => op.dl := true;
  when 16#f1# => op.dl := true;
  when 16#f2# => op.dl := true;
  when 16#f3# => op.dl := true;
  when 16#f4# => op.dl := true;
  when 16#f5# => op.dl := true;
  when 16#f6# => op.dl := true;
  when 16#f7# => op.dl := true;
  when 16#f8# => op.dl := true;
  when 16#f9# => op.dl := true;
  when 16#fa# => op.dl := true;
  when others =>
    case(conv_integer(ir(15 downto 4))) is
    when 16#fe6# => op.dl := true;
    when 16#ffc# => op.dl := true;
    when 16#ffe# => op.dl := true;
    when others =>
      case(conv_integer(ir(15 downto 0))) is
      when 16#fec0# => op.dl := true;
      when 16#fee0# => op.dl := true;
      when 16#fff3# => op.dl := true;
      when others =>
		op.dl := false;
      end case;
    end case;
  end case;

  return op;
end;

end pkg_optab;

