library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity refresh_pad is
	port(
		clk:					 in std_logic;
		tickA:	 			out std_logic;
		tickB:	 			out std_logic
	);
end refresh_pad;

architecture arch of refresh_pad is
	constant FreqA:			integer := 60;--Hz
	constant FreqB:			integer := 400;--Hz
	constant CiclesA:			integer := 50e06 / FreqA; --50MHz / FreqA
	constant CiclesB:			integer := 50e06 / FreqB; --50MHz / FreqB
	signal contA:				integer := 0;
	signal contB:				integer := 0;
begin
	process( clk )
	begin
		if( clk'event and clk='1' ) then
			if( contA >= CiclesA ) then
				contA <= 0;
				tickA <= '1';
			else
				contA <= contA + 1;
				tickA <= '0';
			end if;
			
			if( contB >= CiclesB ) then
				contB <= 0;
				tickB <= '1';
			else
				contB <= contB + 1;
				tickB <= '0';
			end if;
		end if;
	end process;
	
end arch;