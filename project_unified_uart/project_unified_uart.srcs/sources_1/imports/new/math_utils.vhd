library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package math_utils is
  -- compute ceil(log2(x))
  function clog2(x: integer) return integer;
end package math_utils;

package body math_utils is
  function clog2(x: integer) return integer is
    variable v : integer := x - 1;
    variable b : integer := 0;
  begin
    if x<= 1 then
        return 1;
    end if;
    while v > 0 loop
      v := v / 2;
      b := b + 1;
    end loop;
    return b;
  end function;
end package body math_utils;
