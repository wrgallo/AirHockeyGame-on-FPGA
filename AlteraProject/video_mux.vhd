library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TIPOS.all;

entity video_mux is
	port(
		clk, reset:		in std_logic;
		
		--Video 0 = Maxima Prioridade
		vid0_on:				in std_logic;
		vid0_RGB:			in TYPE_COR;
		
		vid1_on:				in std_logic;
		vid1_RGB:			in TYPE_COR;
		
		vid2_on:				in std_logic;
		vid2_RGB:			in TYPE_COR;
		
		vid3_on:				in std_logic;
		vid3_RGB:			in TYPE_COR;
		
		vid4_on:				in std_logic;
		vid4_RGB:			in TYPE_COR;
		
		
		
		VGA_R, VGA_G, VGA_B:	out std_logic_vector(9 downto 0)
	);
end video_mux;

architecture arch of video_mux is
	signal R_reg , G_reg,  B_reg:  std_logic_vector(9 downto 0);
	signal R_next,	G_next, B_next: std_logic_vector(9 downto 0);
	
begin
	
	process( clk, reset )
	begin
		if( reset = '1' ) then
			R_reg <= (others => '1' );
			G_reg <= (others => '1' );
			B_reg <= (others => '1' );
		elsif( clk'event and clk='1' ) then
			R_reg <= R_next;
			G_reg <= G_next;
			B_reg <= B_next;
		end if;
	end process;	
	
	process( vid0_on, vid0_RGB,
				vid1_on, vid1_RGB,
				vid2_on, vid2_RGB,
				vid3_on, vid3_RGB,
				vid4_on, vid4_RGB )
	begin
		R_next <= ( others => '1' );
		G_next <= ( others => '1' );
		B_next <= ( others => '1' );
		if(    vid0_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* to_integer( vid0_RGB(0) ) , 10) );
			G_next <= std_logic_vector( to_unsigned(4* to_integer( vid0_RGB(1) ) , 10) );
			B_next <= std_logic_vector( to_unsigned(4* to_integer( vid0_RGB(2) ) , 10) );
		elsif( vid1_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* to_integer( vid1_RGB(0) ) , 10) );
			G_next <= std_logic_vector( to_unsigned(4* to_integer( vid1_RGB(1) ) , 10) );
			B_next <= std_logic_vector( to_unsigned(4* to_integer( vid1_RGB(2) ) , 10) );
		elsif( vid2_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* to_integer( vid2_RGB(0) ) , 10) );
			G_next <= std_logic_vector( to_unsigned(4* to_integer( vid2_RGB(1) ) , 10) );
			B_next <= std_logic_vector( to_unsigned(4* to_integer( vid2_RGB(2) ) , 10) );
		elsif( vid3_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* to_integer( vid3_RGB(0) ) , 10) );
			G_next <= std_logic_vector( to_unsigned(4* to_integer( vid3_RGB(1) ) , 10) );
			B_next <= std_logic_vector( to_unsigned(4* to_integer( vid3_RGB(2) ) , 10) );
		elsif( vid4_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* to_integer( vid4_RGB(0) ) , 10) );
			G_next <= std_logic_vector( to_unsigned(4* to_integer( vid4_RGB(1) ) , 10) );
			B_next <= std_logic_vector( to_unsigned(4* to_integer( vid4_RGB(2) ) , 10) );
		end if;
	end process;

	VGA_R <= R_reg;
	VGA_G <= G_reg;
	VGA_B <= B_reg;
	
end arch;