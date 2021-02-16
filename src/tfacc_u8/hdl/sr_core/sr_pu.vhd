--
-- sr_pu   sr processer core
--
-- 2013/6/20 extxx insn ccr <-> gcc extxx behavior dosen't match
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.pkg_optab.all;
use work.pkg_sr_pu.all;
use work.pkg_sr_dbg.all;

entity sr_pu is
generic (
	debug	: boolean := true;
	fpu_en	: boolean := false
    );
port (
	clk	: in  std_logic;
	xreset	: in  std_logic;

-- Insn Bus
	i_adr	: out unsigned(31 downto 0);
	i_dr	: in  unsigned(31 downto 0);
	i_re	: out std_logic;
	i_rdy	: in  std_logic;
-- Data Bus
	d_adr	: out unsigned(31 downto 0);
	d_dw	: out unsigned(31 downto 0);
	d_dr	: in  unsigned(31 downto 0);
	d_we	: out std_logic_vector(3 downto 0);
	d_re	: out std_logic;
	d_rdy	: in  std_logic;
-- Interrupt
	irq	: in  unsigned(1 downto 0)	--mm8b
    );
end sr_pu;

architecture RTL of sr_pu is

-- Registers
signal xrst0, xrst1	: std_logic;
signal irh		: unsigned(15 downto 0);
signal f_ir		: unsigned(15 downto 0);
signal ir1		: unsigned(31 downto 0);
signal pc, pc1, pc2, rp	: unsigned(31 downto 0);
signal sr		: unsigned(31 downto 0);
signal pc_ofs		: unsigned(31 downto 0);
signal pc_abs		: std_logic;
signal mar		: unsigned(31 downto 0);
signal mar1		: unsigned(1 downto 0);
signal mdr, mdw		: unsigned(31 downto 0);
signal m_dw		: unsigned(31 downto 0);

signal rrd1, rrd2	: unsigned(31 downto 0);
signal mmd, mmd1	: unsigned(2 downto 0);
signal mwe		: opr_code;
signal rwa, rwa1, rwa2	: unsigned(4 downto 0);
signal rwd, rwd1, rwd2	: opr_code;
signal rwdat, rwdat1, rwdat2	: unsigned(31 downto 0);
signal rwd1ofs		: unsigned(31 downto 0);

signal ccr		: unsigned(3 downto 0);
signal f_ccr, ccr_h	: unsigned(3 downto 0);
signal ccr_we		: std_logic;
signal alu		: alu_code;
signal m_we		: unsigned(3 downto 0);

signal f_state		: unsigned(1 downto 0);
signal bra_stall	: std_logic;
signal ex_stall		: unsigned(4 downto 0);
signal d_stall		: std_logic;
signal dl_slot		: std_logic;
signal ir_hold		: std_logic;

signal irq0, irq1, irq2	: unsigned(1 downto 0);	--mm8b

-- wire
signal ir0		: unsigned(15 downto 0);

signal imm		: unsigned(31 downto 0);
signal ofs_imm		: unsigned(31 downto 0);
signal d9_imm		: unsigned(31 downto 0);
signal ofs		: signed(31 downto 0);
signal f_mdr		: unsigned(31 downto 0);
signal r15		: unsigned(31 downto 0);

signal wa1, wa2		: unsigned(4 downto 0);
signal ra1, ra2 	: unsigned(3 downto 0);
signal we1, we2		: std_logic;
signal wd1, wd2, rd1, rd2	: unsigned (31 downto 0);
signal rs1, rs2		: unsigned (31 downto 0);

signal iack		: unsigned (1 downto 0);
signal irqs, iack1	: std_logic;
signal stall		: std_logic;

signal rdy		: std_logic;

signal op 	: optab;

-- 
component sr_regs
port (
 	clk : in  STD_LOGIC;
	rdy : in  std_logic;
        wa1 : in  unsigned (4 downto 0);
        we1 : in  std_logic;
        wd1 : in  unsigned (31 downto 0);
        wa2 : in  unsigned (4 downto 0);
        we2 : in  std_logic;
        wd2 : in  unsigned (31 downto 0);
        ra1 : in  unsigned (3 downto 0);
        rd1 : out unsigned (31 downto 0);
        ra2 : in  unsigned (3 downto 0);
        rd2 : out unsigned (31 downto 0);
        rp  : out unsigned (31 downto 0);
        r15 : out unsigned (31 downto 0)
	);
end component;

component sr_alu
generic (
	fpu_en	: boolean
	);
port (
        clk     : in  std_logic;
        xreset  : in  std_logic;
	rdy	: in  std_logic;
	ex	: in  unsigned(4 downto 0);
        alu     : in  alu_code;
        rrd1    : in  unsigned(31 downto 0);
        rrd2    : in  unsigned(31 downto 0);
	c       : in  std_logic;
        fcc     : out unsigned(3 downto 0);
        rwdat   : out unsigned(31 downto 0)
    );
end component;

function ixofs(x : unsigned; m : unsigned) return signed is
begin
  case m(2 downto 0) is
  when "001" => return signed(x);	-- QI
  when "010" => return conv_signed(x(x'high-1 downto 0)&'0', 32);	-- HI
  when "100" => return conv_signed(x(x'high-2 downto 0)&"00", 32);	-- SI
  when others => return signed(x);
  end case;
end;

function decrement(x : unsigned) return unsigned is
begin
  if(x > 0) then
	return x - 1;
  else
	return x;
  end if;
end;

constant R_NA : unsigned(4 downto 0) := "11111";
constant R_SR : unsigned(4 downto 0) := "10000";
constant R_RP : unsigned(4 downto 0) := "10001";

function regadr(ir : unsigned; rwa : opr_code) return unsigned is
begin
  case(rwa) is
  when O_RI 	=> return '0' & ir(3 downto 0);
  when O_RJ 	=> return '0' & ir(7 downto 4);
  when O_RS1 	=> return '1' & ir(7 downto 4);
  when O_RS2 	=> return '1' & ir(3 downto 0);
  when O_R15	=> return '0' & "1111";
  when O_RP 	=> return '1' & "0001";
  when others	=> return R_NA;
  end case;
end;

function ppofs(pp : opr_code) return unsigned is
begin
  case(pp) is
  when O_PINC => return conv_unsigned(4, 32);
  when O_PDEC => return conv_unsigned(-4, 32);
  when others => return conv_unsigned(0, 32);
  end case;
end;

-- ccr : n z v c
function branch_cond(ir : unsigned; ccr : unsigned) return boolean is
variable n,z,v,c : std_logic;
begin
  (n,z,v,c) := ccr;
  case(conv_integer(ir(11 downto 8))) is
  when 0 	=> return true;		-- bra
  when 1 	=> return z = '1';	-- beq
  when 2 	=> return z = '0';	-- bne
  when 3 	=> return c = '1';	-- bc
  when 4 	=> return c = '0';	-- bnc
  when 5 	=> return (n xor v) = '1';	-- blt
  when 6 	=> return (n xor v) = '0';	-- bge
  when 7 	=> return ((n xor v) or z) = '1';	-- ble
  when 8 	=> return ((n xor v) or z) = '0';	-- bgt
  when 9 	=> return (z or c) = '1';	-- bls
  when 10 	=> return (z or c) = '0';	-- bhi
  when others 	=> return false;
  end case;
end;

function Reg_rd(opr:opr_code; rd1:unsigned; rd2:unsigned;
	rs1: unsigned; rs2: unsigned;
	rp:unsigned; r15:unsigned; imm:unsigned) return unsigned is
begin
	case(opr) is
	when O_RI  => return rd2;
	when O_RJ  => return rd1;
	when O_RS1 => return rs1;
	when O_RS2 => return rs2;
	when O_RP  => return rp;
	when O_R15 => return r15;
	when O_IMM|O_UIMM
		   => return imm;
	when others =>return rd1;
	end case;
end;

----- 150925 vivado synth bug? --------------------------------------------------
function mdrsel(d_dr:unsigned; mmd1:unsigned; mar1:unsigned) return unsigned is
variable f_mdr:unsigned(31 downto 0);
begin
  if(mmd1 = 4) then
    f_mdr := d_dr;
  elsif(mmd1 = 2) then
    if(mar1(1) = '0') then
      f_mdr := conv_unsigned(d_dr(31 downto 16), 32);
    else
      f_mdr := conv_unsigned(d_dr(15 downto 0), 32);
    end if;
  elsif(mmd1 = 1) then
    case(mar1(1 downto 0)) is
    when "00" => f_mdr := conv_unsigned(d_dr(31 downto 24), 32);
    when "01" => f_mdr := conv_unsigned(d_dr(23 downto 16), 32);
    when "10" => f_mdr := conv_unsigned(d_dr(15 downto 8), 32);
    when "11" => f_mdr := conv_unsigned(d_dr(7 downto 0), 32);
    when others => f_mdr := (others => '0');
    end case;
  else
    f_mdr := (others => '0');
  end if;
  return f_mdr;
end;
----------------------------------------------------------------------------------

constant INT_1 : unsigned(15 downto 0) := conv_unsigned(16#ef01#, 16);
constant INT_2 : unsigned(15 downto 0) := conv_unsigned(16#ef02#, 16);
constant INT_3 : unsigned(15 downto 0) := conv_unsigned(16#ef03#, 16);

--constant debug : boolean := true;
--constant debug : boolean := false;
constant sim_limit : integer := 91700;

begin

-- synopsys translate_off
  process			-- debug print out
  variable count : integer := 0;
  begin
  wait until clk'event and clk = '1';
    if(xrst0 /= '1') then
	count := 0;
    else
      if(debug) then
--    	if(count mod 50 = 0) then
    	if(count = 0) then
		deb_print_label;
    	end if;
    	deb_print(count, pc1, f_ir, bra_stall, ex_stall, d_stall,
		m_we, ofs, mar, mdr, m_dw, rrd1, rrd2, alu, rwa2, rwd2,
		ccr, rwdat2, r15, rp);
      end if;
      count := count + 1;
--      assert count < sim_limit report "**** exceed sim_limit." severity error;
    end if;
  end process;
-- synopsys translate_on

 rdy <= i_rdy and d_rdy;
  
 u_sr_regs : sr_regs
    port map(
	clk  => clk,	rdy  => rdy,
	wa1  => wa1,	we1  => we1,	wd1  => wd1,
	wa2  => wa2,	we2  => we2,	wd2  => wd2,
	ra1  => ra1,	rd1  => rd1,
	ra2  => ra2,	rd2  => rd2,
	rp   => rp,	r15  => r15
	);

  ra1 <= f_ir(7 downto 4);	-- Rj/Rs1
  ra2 <= f_ir(3 downto 0);	-- Ri/Rs2
  rs1 <= sr	when ra1 = 0	else
	 rp	when ra1 = 1	else (others => '0');
  rs2 <= sr	when ra2 = 0	else
	 rp	when ra2 = 1	else (others => '0');

  i_re <= '1';
  i_adr <= pc;

  ir0 <= INT_1			when iack(0) = '1'	else
	 INT_2			when iack(1) = '1'      else
	i_dr(31 downto 16)	when pc1(1) = '0'	else i_dr(15 downto 0);

  f_ir <= (others => '0')	when xrst1 = '0'	else
		irh		when ir_hold = '1' 	else 
		ir0;

----- 150925 vivado synth bug? --------------------------------------------------
--  f_mdr <= d_dr	when mmd1 = 4	else	-- fwd mdr
--	   conv_unsigned(d_dr(31 downto 16), 32) when mmd1 = 2 and mar1(1) = '0' else
--	   conv_unsigned(d_dr(15 downto 0), 32)	 when mmd1 = 2 and mar1(1) = '1' else
--	   conv_unsigned(d_dr(31 downto 24), 32) when mmd1 = 1 and mar1(1 downto 0) = 0 else
--	   conv_unsigned(d_dr(23 downto 16), 32) when mmd1 = 1 and mar1(1 downto 0) = 1 else
--	   conv_unsigned(d_dr(15 downto 8), 32)  when mmd1 = 1 and mar1(1 downto 0) = 2 else
--	   conv_unsigned(d_dr(7 downto 0), 32)   when mmd1 = 1 and mar1(1 downto 0) = 3 else
--	   (others => '0');
  f_mdr <= mdrsel(d_dr, mmd1, mar1);

  ir1(15 downto 0) <= ir0;

  stall <= '1' when f_state > 0 or ex_stall > 0
			 or bra_stall = '1' or d_stall = '1' or dl_slot = '1' else '0';
  iack(0) <= '1' when stall = '0' and irq1(0) = '1' and irq2(0) = '0' else '0';
  iack(1) <= '1' when stall = '0' and irq1(1) = '1' and irq2(1) = '0' else '0';

  process
  begin
  wait until clk'event and clk = '1';
  irq0 <= irq;

  if(rdy = '1') then
	if(xreset = '0') then
		xrst0 <= '0';
		xrst1 <= '0';
	else
		xrst0 <= '1';
		xrst1 <= xrst0;
	end if;
	if(xrst1 = '0') then
		ir1(31 downto 16) <= (others => '0');
	elsif(f_state > 0) then
		ir1(31 downto 16) <= ir1(15 downto 0);	-- & ir0;
	end if;
	if(ir_hold = '0') then
		irh <= ir0;
	end if;

	if(xreset = '0') then
		pc1 <= (others => '0');	----110605
	elsif(xrst0 = '0') then
----110605		pc1 <= d_dr;
		pc1 <= i_dr;	----110605
	else
		pc1 <= pc;
	end if;
----	pc2 <= pc1;

	-- irq(0) higher priority
	if(xrst0 = '0') then
		irq1(0) <= '0';
		irq2(0) <= '0';
	elsif(irq2(0) = '1' and op.spfunc = S_RTI and ex_stall = 1) then
		irq1(0) <= irq0(0);
		irq2(0) <= '0';
	elsif(stall = '0') then
		irq1(0) <= irq0(0);
		if(irq1(0) = '1') then
			irq2(0) <= '1';
		end if;
	end if;

	if(xrst0 = '0') then
		irq1(1) <= '0';
		irq2(1) <= '0';
	elsif(irq2(0) = '0' and op.spfunc = S_RTI and ex_stall = 1) then
		irq1(1) <= irq0(1) and not irqs;
		irq2(1) <= '0';
	elsif(stall = '0') then
		irq1(1) <= irq0(1) and not irqs;
		if(irq1(1) = '1') then
			irq2(1) <= '1';
		end if;
	end if;

	iack1 <= iack(0) or iack(1);
  end if;
  end process;
  irqs <= irq0(0) or irq1(0) or irq2(0);

  op <= opcdec(f_ir);

  process
  variable nxt_pc : unsigned(pc'range);
  variable vpc_abs : std_logic;
  variable rsrc : unsigned(4 downto 0);
  variable mst, mld : boolean;
  variable vrwdat1, vrwdat2, vmdr : unsigned(31 downto 0);
  variable vrwd1ofs	: unsigned(31 downto 0);
  variable vrd1, vrd2, vmar : unsigned(31 downto 0);
  variable vstall : std_logic;
  variable vd_stall : std_logic;
  variable vex_stall : unsigned(4 downto 0);	-- 080221
  variable vdl_slot : std_logic;
  begin
  wait until clk'event and clk = '1';
  if(rdy = '1') then
	mst := false;
	mld := false;
	vstall := '0';
	vd_stall := '0';
	vdl_slot := '0';
	vrd1 := (others => '0');
	vrd2 := (others => '0');
	nxt_pc := conv_unsigned(2, pc'length);
	vpc_abs := '0';
	vmdr := f_mdr;
--	vrwdat1 := rwdat;
	vrwd1ofs := conv_unsigned(0, 32);
	vrwdat2 := rwdat1 + rwd1ofs;
	vex_stall := ex_stall;

	rwa1 <= rwa;
	rwa2 <= rwa1;
	rwd1 <= rwd;
	rwd2 <= rwd1;

	if(xrst0 = '0') then
		nxt_pc := conv_unsigned(0, pc'length);
		bra_stall <= '0';
		vd_stall := '0';
		f_state <= (others => '0');
--		ex_stall <= (others => '0');
		vex_stall := (others => '0');
		mar <= (others => '0');
		ccr_we <= '0';
		we2 <= '0';
	elsif(bra_stall = '1') then
		bra_stall <= '0';
		ccr_we <= '0';
		we2 <= '0';
	else
	    if(ex_stall = 0 and op.ex > 0) then
--		ex_stall <= op.ex;
		vex_stall := op.ex;	-- 080221
		vstall := '1';
		nxt_pc := conv_unsigned(0, pc'length);
	    elsif(ex_stall > 0) then
		if(op.spfunc = S_POPM) then
			mld := true;
		elsif(op.spfunc = S_PUSHM) then
			mst := true;
		elsif(ex_stall > 1) then
			nxt_pc := conv_unsigned(0, pc'length);
		end if;
--		ex_stall <= decrement(ex_stall);
		vex_stall := decrement(ex_stall);	-- 080221
		if(ex_stall > 1) then
			vstall := '1';
		end if;
	    end if;

	    if(f_state = 0 and op.len > 1) then
		f_state <= op.len - 1;
		rwa <= R_NA;
		mwe <= O_NA;
		ccr_we <= '0';
		vstall := '1';
		we2 <= '0';
	    elsif(f_state = 2) then
		f_state <= decrement(f_state);
		rwa <= R_NA;
		mwe <= O_NA;
		ccr_we <= '0';
		vstall := '1';
		we2 <= '0';
	    else
		f_state <= decrement(f_state);

-- mar
		rsrc := regadr(f_ir, op.mar);
		if(rsrc = R_NA) then
			vmar := (others => '0');
		elsif(op.spfunc = S_INT and ex_stall > 0) then
			vmar := conv_unsigned(f_ir(7 downto 0) & "00", 32);
		elsif(op.spfunc = S_RTI and ex_stall > 0) then
			vmar := (others => '0');
		elsif(rsrc = rwa) then
			if(rwd = O_MDR) then
				vd_stall := '1';
				nxt_pc := conv_unsigned(0, pc'length);
			else
				vmar := rwdat;	-- + unsigned(ofs);
			--	vrwdat1 := rwdat + ppofs(op.ofs);
				vrwd1ofs := ppofs(op.ofs);
			end if;
		elsif(rsrc = rwa1) then
			vmar := sel(rwd1 = O_MDR, f_mdr, rwdat1 + rwd1ofs);
			if(rwd1 = O_MDR) then
				vmdr := f_mdr + ppofs(op.ofs);
			else
				vrwdat2 := rwdat1 + ppofs(op.ofs) + rwd1ofs;
			end if;
		elsif(rsrc = rwa2) then
			vmar := sel(rwd2 = O_MDR, mdr, rwdat2);
		elsif(rsrc = wa2 and we2 = '1') then
			vmar := wd2;
		else
			vmar := Reg_rd(op.mar, rd1, rd2, rs1, rs2, rp, r15, imm);	-- + unsigned(ofs);
		end if;
		mar <= vmar + unsigned(ofs);

		if(d_stall = '1') then	-- 080221
			we2 <= '0';
		elsif(op.spfunc = S_CALL) then	-- Reg_write port2
			wa2 <= R_RP;
			we2 <= '1';
			wd2 <= pc + sel(op.dl, 2, 0);
		elsif(op.spfunc = S_INT and ex_stall > 0) then
			if(ex_stall = 3) then
				wa2 <= R_RP;
				wd2 <= sel(iack1 = '0', pc, pc1);
				we2 <= '1';
			else
				we2 <= '0';
			end if;
		elsif(op.spfunc = S_RTI and ex_stall > 0) then
			wa2 <= R_RP;
			wd2 <= d_dr;
			if(ex_stall = 1) then
				we2 <= '1';
			else
				we2 <= '0';
			end if;
		elsif(rsrc = R_NA or ppofs(op.ofs) = 0) then
			we2 <= '0';
		else
			wa2 <= rsrc;
			we2 <= '1';
			wd2 <= vmar + ppofs(op.ofs);
		end if;

-- mdw
		rsrc := regadr(f_ir, sel(mst, O_RI, op.mwe));
		if(rsrc = R_NA) then
			mdw <= (others => '0');
		elsif(rsrc = rwa) then
			if(rwd = O_MDR) then
				vd_stall := '1';
				nxt_pc := conv_unsigned(0, pc'length);
			else
				mdw <= rwdat;
			end if;
		elsif(rsrc = rwa1) then
			mdw <= sel(rwd1 = O_MDR, f_mdr, rwdat1 + rwd1ofs);
		elsif(rsrc = rwa2) then
			mdw <= sel(rwd2 = O_MDR, mdr, rwdat2);
		elsif(rsrc = wa2 and we2 = '1') then
			mdw <= wd2;
		else
			mdw <= Reg_rd(sel(mst, O_RI, op.mwe), rd1, rd2, rs1, rs2, rp, r15, imm);
		end if;

-- rrd1
		rsrc := regadr(f_ir, op.rrd1);
		if(rsrc = R_NA) then
			vrd1 := Reg_rd(op.rrd1, rd1, rd2, rs1, rs2, rp, r15, imm);
		elsif(rsrc = rwa) then
			if(rwd = O_MDR) then
				vd_stall := '1';
				nxt_pc := conv_unsigned(0, pc'length);
			else
				vrd1 := rwdat;
			end if;
		elsif(rsrc = rwa1) then
			vrd1 := sel(rwd1 = O_MDR, f_mdr, rwdat1 + rwd1ofs);
		elsif(rsrc = rwa2) then
			vrd1 := sel(rwd2 = O_MDR, mdr, rwdat2);
		elsif(rsrc = wa2 and we2 = '1') then
			vrd1 := wd2;
		else
			vrd1 := Reg_rd(op.rrd1, rd1, rd2, rs1, rs2, rp, r15, imm);
		end if;

-- rrd2
		rsrc := regadr(f_ir, op.rrd2);
		if(rsrc = R_NA) then
			vrd2 := Reg_rd(op.rrd2, rd1, rd2, rs1, rs2, rp, r15, imm);
		elsif(rsrc = rwa) then
			if(rwd = O_MDR) then
				vd_stall := '1';
				nxt_pc := conv_unsigned(0, pc'length);
			else
				vrd2 := rwdat;
			end if;
		elsif(rsrc = rwa1) then
			vrd2 := sel(rwd1 = O_MDR, f_mdr, rwdat1 + rwd1ofs);
		elsif(rsrc = rwa2) then
			vrd2 := sel(rwd2 = O_MDR, mdr, rwdat2);
		elsif(rsrc = wa2 and we2 = '1') then
			vrd2 := wd2;
		else
			vrd2 := Reg_rd(op.rrd2, rd1, rd2, rs1, rs2, rp, r15, imm);
		end if;

		if(vd_stall = '0') then
		case(op.spfunc) is
		when S_CALL | S_JMP =>
				if(op.rrd1 = O_IMM) then
					if(op.len = 3) then
						nxt_pc := ir1;
						vpc_abs := '1';
					else
						nxt_pc := (conv_unsigned(signed(ir1(15 downto 0)), 31) & '0') - 2;
					end if;
				else
					nxt_pc := vrd2;
					vpc_abs := '1';
				end if;
				bra_stall <= sel(op.dl, '0', '1');
				vdl_slot := '1';
		when S_RTI =>
			if(ex_stall = 1) then
				nxt_pc := rp;
				vpc_abs := '1';
				bra_stall <= '1';
				vdl_slot := '1';
			end if;
		when S_RET =>	nxt_pc := vrd2;
				vpc_abs := '1';
				bra_stall <= sel(op.dl, '0', '1');
				vdl_slot := '1';
		when S_BCC =>	if(branch_cond(f_ir, ccr)) then
					nxt_pc := d9_imm;
					bra_stall <= sel(op.dl, '0', '1');
					vdl_slot := '1';
				end if;
		when S_POPM | S_PUSHM =>	
				if(ex_stall = 0) then
					nxt_pc := conv_unsigned(0, pc'length);
				end if;
		when S_INT =>
			if(ex_stall = 1) then
				vpc_abs := '1';
				nxt_pc := d_dr;
				bra_stall <= '1';
				vdl_slot := '1';
			else
				nxt_pc := conv_unsigned(0, pc'length);
			end if;
			if(imm = 9) then
				-- synopsys translate_off
				assert false report "***** int 9" severity error;
				-- synopsys translate_on
			end if;

		when others =>	null;
		end case;
		end if;

-- rwa
		rwa <= sel((ex_stall > 1) or (vd_stall = '1') or (op.spfunc = S_RTI and ex_stall = 1), 
						R_NA, regadr(f_ir, sel(mld, O_RI, op.rwa)));
		if(vd_stall = '1') then
			mwe <= O_NA;
		elsif((op.spfunc = S_INT or op.spfunc = S_RTI) and ex_stall > 0) then
			if(ex_stall = 3) then
				mwe <= O_RD;
			else
				mwe <= O_NA;
			end if;
		elsif(not (ex_stall > 1) or mld or mst) then
-- mwe
			mwe <= sel(op.mwe = O_RD, O_RD, sel(op.mwe = O_NA, O_NA, O_WR));
		else
			mwe <= O_NA;
		end if;

	    end if;	-- 0422

-- mmd
	    mmd <= op.mode;
	    if((op.spfunc = S_INT or op.spfunc = S_RTI) and ex_stall > 0) then
		rwd <= O_NA;
		alu <= A_NA;
	    elsif(not (ex_stall > 1) or mld or mst) then
-- rwd
		rwd <= op.rwd;
-- alu
		alu <= op.alu;
		case(op.alu) is
	----	when A_CMP|A_ADD|A_EXTB|A_EXTH|A_SXTB|A_SXTH|A_CMPF =>
		when A_CMP|A_ADD|A_CMPF =>
			ccr_we <= '1';
		when others => 
			null;
			ccr_we <= '0';
		end case;
	    else
		rwd <= O_NA;
--fpu		alu <= A_NA;
		alu <= op.alu;	--fpu
		ccr_we <= '0';
	    end if;

	end if;

	if(d_stall = '1') then
		vd_stall := '0';
	end if;
	d_stall <= vd_stall;
	if(vd_stall = '0') then
		ex_stall <= vex_stall;	-- 080221
	end if;
	ir_hold <= vstall or vd_stall;
	dl_slot <= vdl_slot;


	mar1 <= mar(1 downto 0);	-- pipe for data_ram access
	mmd1 <= mmd;

      	mdr <= vmdr;
--     	rwdat1 <= vrwdat1;
      	rwdat1 <= rwdat;
      	rwdat2 <= vrwdat2;
	rwd1ofs <= vrwd1ofs;

	rrd1 <= vrd1;
	rrd2 <= vrd2;
	pc_ofs <= nxt_pc;
	pc_abs <= vpc_abs;

	if(ccr_we = '1') then
		ccr_h <= f_ccr;
	elsif(we1 = '1' and wa1 = R_SR) then
		ccr_h <= wd1(3 downto 0);
	end if;
  end if;
  end process;

  pc <= pc1		when iack /= 0		else
	pc1 + pc_ofs	when pc_abs = '0'	else pc_ofs;

  ccr <= f_ccr when ccr_we = '1' else ccr_h;
  sr <= conv_unsigned(ccr, 32);

-- exec
  d_adr <= mar;
  d_dw <= m_dw;
  m_we <= "0000"	when mwe = O_RD or mwe = O_NA	else
	  "1111"	when mmd = 4	else
	  "1100"	when mmd = 2 and mar(1) = '0'	else
	  "0011"	when mmd = 2 and mar(1) = '1'	else
	  "1000"	when mmd = 1 and mar(1 downto 0) = 0	else
	  "0100"	when mmd = 1 and mar(1 downto 0) = 1	else
	  "0010"	when mmd = 1 and mar(1 downto 0) = 2	else
	  "0001"	when mmd = 1 and mar(1 downto 0) = 3	else
	  "0000";
  m_dw <= (others => '0') 			when mwe = O_RD or mwe = O_NA	else
	mdw					when mmd = 4	else
	mdw(15 downto 0)&"0000000000000000"	when mmd = 2 and mar(1) = '0'	else
	"0000000000000000"&mdw(15 downto 0)	when mmd = 2 and mar(1) = '1'	else
	mdw(7 downto 0)&"000000000000000000000000" when mmd = 1 and mar(1 downto 0) = 0	else
	"00000000"&mdw(7 downto 0)&"0000000000000000" when mmd = 1 and mar(1 downto 0) = 1 else
	"0000000000000000"&mdw(7 downto 0)&"00000000" when mmd = 1 and mar(1 downto 0) = 2 else
	"000000000000000000000000"&mdw(7 downto 0) when mmd = 1 and mar(1 downto 0) = 3 else
	(others => '0');

  d_we <= std_logic_vector(m_we);
  d_re <= '1' when mwe = O_RD or xrst0 = '0' 	else '0';

 u_sr_alu : sr_alu
 generic map(
	fpu_en	=> fpu_en
	)
 port map(
        clk     => clk,
        xreset  => xrst0,
	rdy	=> rdy,
	ex	=> ex_stall,
        alu     => alu,
        rrd1    => rrd1,
        rrd2    => rrd2,
	c       => ccr(0),
        fcc     => f_ccr,
        rwdat   => rwdat
    );

-- memory-access

-- write back

  process(rwd2, rwa2, we1, wd1, rwdat2, mdr)	-- Reg_write port1
  begin
	wa1 <= rwa2;
	if(rwa2 /= R_NA and 
		(rwd2 = O_RWD or rwd2 = O_RRD1 or rwd2 = O_MDR)) then
			we1 <= '1';
			wd1 <= sel(rwd2 = O_MDR, mdr, rwdat2);
	else
		we1 <= '0';
		wd1 <= rwdat2;
	end if;
  end process;

  process(op, f_ir, ir1, imm, ofs_imm, ex_stall, d_stall)
  begin
   if(op.len = 2) then
	if(op.rrd1 = O_UIMM) then
	  imm <= conv_unsigned(ir1(15 downto 0), 32);
	else
	  imm <= unsigned(conv_signed(signed(ir1(15 downto 0)), 32));
	end if;
   elsif(op.len = 3) then
 	imm <= ir1;
   else
     case op.immcd is
--     when I_U4 => imm <= conv_unsigned(f_ir(11 downto 8), 32);
     when I_S8 => imm <= conv_unsigned(signed(f_ir(11 downto 4)), 32);
     when I_U8 => imm <= conv_unsigned(f_ir(11 downto 4), 32);
     when I_U5 => imm <= conv_unsigned(f_ir(8 downto 4), 32);
     when I_S5 => imm <= conv_unsigned(signed(f_ir(8 downto 4)), 32);

--     when I_D9 => imm <= conv_unsigned(signed(f_ir(7 downto 0) & '0'), 32);	-- bcc
     when I_D10 => imm <= conv_unsigned(signed(f_ir(7 downto 0) & "00"), 32);	-- addsp
--     when I_V8 => imm <= conv_unsigned(f_ir(7 downto 0), 32);			-- int vect

     when others => imm <= (others => '0');
     end case;
   end if;

   d9_imm <= conv_unsigned(signed(f_ir(7 downto 0) & '0'), 32);	-- for bcc

   if(op.len = 2) then
	ofs_imm <= unsigned(conv_signed(signed(ir1(15 downto 0)), 32));	-- s16
   else
	ofs_imm <= conv_unsigned(signed(f_ir(11 downto 4)), 32);	-- s8
   end if;

   case op.ofs is
--   when O_IMM =>  ofs <= ixofs(imm, op.mode);	-- s16|s8
--   when O_UIMM => ofs <= ixofs(conv_unsigned(imm(3 downto 0), 32), op.mode);	-- u4
   when O_IMM =>  ofs <= ixofs(ofs_imm, op.mode);	-- s16|s8
   when O_UIMM => ofs <= ixofs(conv_unsigned(f_ir(11 downto 8), 32), op.mode);
   when O_PINC => ofs <= conv_signed(0, 32);
--   when O_PDEC => if(op.spfunc = S_INT and ex_stall > 0) then
   when O_PDEC => if(d_stall = '1' or (op.spfunc = S_INT and ex_stall > 0)) then	-- 080221
			ofs <= conv_signed(0, 32);
		  else
			ofs <= conv_signed(-4, 32);
		  end if;
   when others =>  ofs <= conv_signed(0, 32);
   end case;
  end process;


end RTL;


