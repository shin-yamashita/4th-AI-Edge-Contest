--
-- package for sr_pu

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.pkg_optab.all;

package pkg_sr_pu is

function sel(cond : boolean; s_true : unsigned; s_false : unsigned) return unsigned;
function sel(cond : boolean; s_true : integer; s_false : integer) return integer;
function sel(cond : boolean; s_true : std_logic; s_false : std_logic) return std_logic;
function sel(cond : boolean; s_true : opr_code; s_false : opr_code) return opr_code;
function "and" (L, R:unsigned) return unsigned;
function "or"  (L, R:unsigned) return unsigned;
function "xor" (L, R:unsigned) return unsigned;
function "not" (L:unsigned)    return unsigned;

end pkg_sr_pu;



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.pkg_optab.all;

package body pkg_sr_pu is

function sel(cond : boolean; s_true : unsigned; s_false : unsigned) return unsigned is
begin
  if(cond) then return s_true; else return s_false; end if;
end;
function sel(cond : boolean; s_true : integer; s_false : integer) return integer is
begin
  if(cond) then return s_true; else return s_false; end if;
end;
function sel(cond : boolean; s_true : std_logic; s_false : std_logic) return std_logic is
begin
  if(cond) then return s_true; else return s_false; end if;
end;
function sel(cond : boolean; s_true : opr_code; s_false : opr_code) return opr_code is
begin
  if(cond) then return s_true; else return s_false; end if;
end;

function "and" (L, R:unsigned) return unsigned is
variable rv : unsigned(L'range);
begin
        for i in 0 to L'length-1 loop
                rv(i) := L(i) and R(i);
        end loop;
        return rv;
end;
function "or" (L, R:unsigned) return unsigned is
variable rv : unsigned(L'range);
begin
        for i in 0 to L'length-1 loop
                rv(i) := L(i) or R(i);
        end loop;
        return rv;
end;
function "xor" (L, R:unsigned) return unsigned is
variable rv : unsigned(L'range);
begin
        for i in 0 to L'length-1 loop
                rv(i) := L(i) xor R(i);
        end loop;
        return rv;
end;
function "not" (L:unsigned) return unsigned is
variable rv : unsigned(L'range);
begin
        for i in 0 to L'length-1 loop
                rv(i) := not L(i);
        end loop;
        return rv;
end;

end pkg_sr_pu;

