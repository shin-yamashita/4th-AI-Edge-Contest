----------------------------------------------------------------------------------
-- sr cpu register file
-- 16 word 2-rw
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sr_regs is
    Port ( clk : in  STD_LOGIC;
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
end sr_regs;

architecture RTL of sr_regs is

type regfile_t is array (0 to 15) of unsigned (31 downto 0);
signal Regs : regfile_t;

signal rpreg, sp : unsigned(31 downto 0);
constant R_RP : integer := 16+1;
constant R_SP : integer := 15;

begin

	process
	begin
	wait until clk'event and clk = '1';
	  if(rdy = '1') then

	    if(we2 = '1' and wa2 < 16) then
		Regs(conv_integer(wa2(3 downto 0))) <= wd2;
	    end if;
	    if(we1 = '1' and wa1 < 16) then
		if(not(we2 = '1' and wa1 = wa2)) then
		  Regs(conv_integer(wa1(3 downto 0))) <= wd1;
		end if;
	    end if;

	    if(we2 = '1' and wa2 = R_RP) then
		rpreg <= wd2;
	    elsif(we1 = '1' and wa1 = R_RP) then
		rpreg <= wd1;
	    end if;

	  end if;
	end process;

	rd1 <= Regs(conv_integer(ra1));
	rd2 <= Regs(conv_integer(ra2));
	r15 <= Regs(15);
	rp <= rpreg;

end RTL;


