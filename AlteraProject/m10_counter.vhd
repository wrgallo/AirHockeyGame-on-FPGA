-- Contador
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity m10_counter is
   port(
      clk, reset: in std_logic;
      d_inc: in std_logic;
      dig0: out unsigned (3 downto 0)
   );
end m10_counter;

architecture arch of m10_counter is
   signal dig0_reg: unsigned(3 downto 0);
   signal dig0_next: unsigned(3 downto 0);
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         dig0_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         dig0_reg <= dig0_next;
      end if;
   end process;
	
   -- next-state logic para o contador decimal
   process(d_inc,dig0_reg)
   begin
      dig0_next <= dig0_reg;
		
      if (d_inc='1') then
         if dig0_reg=9 then
            dig0_next <= (others=>'0');
         else
            dig0_next <= dig0_reg + 1;
         end if;
      end if;
   end process;
	
   dig0 <= dig0_reg;
end arch;
