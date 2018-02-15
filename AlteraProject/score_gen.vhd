library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TIPOS.all;

entity score_gen is
	port(
		clk, reset:			in std_logic;
		pixel_x, pixel_y:	in std_logic_vector(9 downto 0);
		
		goal_tick:			in std_logic_vector(1 downto 0);
		
		stop_game:			out std_logic;
		
		obj_on:				out std_logic;
		obj_RGB:				out TYPE_COR
	);
end score_gen;

architecture arch of score_gen is
	constant GOALS_to_WIN: integer := 3;
	--Dimensoes dos Textos na tela
	constant SCORE_CHARS: integer := 5;
	constant scoreY_dim: integer := 32;
	constant scoreX_dim: integer := 16;
	constant score_Ymin: integer := 0;
	constant score_Ymax: integer := score_Ymin + scoreY_dim;
	constant score_Xmin: integer := 640/2      - (SCORE_CHARS*scoreX_dim)/2 - 4;
	constant score_Xmax: integer := score_Xmin + (SCORE_CHARS*scoreX_dim);
	type palavra2CHAR is array(0 to 1) of unsigned(3 downto 0);
	signal score_txt: palavra2CHAR := ("0000","0001");
	
	signal Blue_Win, Blue_Win_next: std_logic := '0';
	constant BlueCHARS: integer := 4;
	constant BlueY_dim: integer := 16*8;
	constant BlueX_dim: integer := 8*8;
	constant Blue_Ymin: integer := 240 		   - BlueY_dim;
	constant Blue_Ymax: integer := Blue_Ymin  + BlueY_dim;
	constant Blue_Xmin: integer := 166        - (BlueCHARS*BlueX_dim)/2;
	constant Blue_Xmax: integer := Blue_Xmin  + (BlueCHARS*BlueX_dim);
	type palavra4CHAR is array(0 to 3) of integer;
	constant Blue_txt: palavra4CHAR := (66,108,117,101);-- B l u e
	
	signal Green_Win, Green_Win_next: std_logic := '0';
	constant GreenCHARS: integer := 5;
	constant GreenY_dim: integer := 16*8;
	constant GreenX_dim: integer := 8*8;
	constant Green_Ymin: integer := 240        -  GreenY_dim;
	constant Green_Ymax: integer := Green_Ymin +  GreenY_dim;
	constant Green_Xmin: integer := 466        - (GreenCHARS*GreenX_dim)/2;
	constant Green_Xmax: integer := Green_Xmin + (GreenCHARS*GreenX_dim);
	type palavra5CHAR is array(0 to 4) of integer;
	constant Green_txt: palavra5CHAR := (71,114,101,101,110);-- G r e e n
	
	constant WINCHARS:  integer := 3;
	constant WINY_dim: integer := 16*8;
	constant WINX_dim: integer := 8*8;
	constant WIN_Ymin: integer := 432        - WINY_dim;
	constant WIN_Ymax: integer := WIN_Ymin   + WINY_dim;
	constant WIN_Xmin: integer := 320        - (WINCHARS*WINX_dim)/2;
	constant WIN_Xmax: integer := WIN_Xmin   + (WINCHARS*WINX_dim);
	type palavra3CHAR is array(0 to 2) of integer;
	constant WIN_txt: palavra3CHAR := (87,73,78);

	--Sinais Texto
	signal rom_addr:	std_logic_vector(10 downto 0) := (others => '0');
	signal data:		std_logic_vector( 7 downto 0) := (others => '0');
	signal char_addr: std_logic_vector( 6 downto 0) := (others => '0');
   signal row_addr:  std_logic_vector( 3 downto 0) := (others => '0');
   signal bit_addr:  std_logic_vector( 2 downto 0) := (others => '0');
   signal font_bit:  std_logic;
	
	signal pix_x: unsigned(9 downto 0) := unsigned( pixel_x );
	signal pix_y: unsigned(9 downto 0) := unsigned( pixel_y );
	
	begin
		texto_bitmap: entity work.font_rom
		port map(clk => clk, addr => rom_addr, data => data );
		contador0: entity work.m10_counter
		port map(clk => clk, reset => reset , d_inc => goal_tick(0), dig0 => score_txt(0) );
		contador1: entity work.m10_counter
		port map(clk => clk, reset => reset , d_inc => goal_tick(1), dig0 => score_txt(1) );
		
		stop_game <= '1' when Green_Win='1' else
						 '1' when Blue_Win='1' else
						 '0';
		
		pix_x 	<= unsigned( pixel_x );
		pix_y 	<= unsigned( pixel_y );
		
		process( clk		, reset		)
		begin
			if( reset = '1' ) then
				Blue_Win  <= '0';
				Green_Win <= '0';
			elsif( clk'event and clk='1' ) then
				Blue_Win  <= Blue_Win_next;
				Green_Win <= Green_Win_next;
			end if;
		end process;
		
		process( score_txt, goal_tick,
					Blue_Win	, Green_Win	)
		begin
			Blue_Win_next  <= Blue_Win;
			Green_Win_next <= Green_Win;
			
			if(    (score_txt(0) = to_unsigned( GOALS_to_WIN-1 , 3) ) and
				    (goal_tick(0) = '1') ) then
				 Blue_Win_next <= '1';
			elsif( (score_txt(1) = to_unsigned( GOALS_to_WIN-1 , 3) ) and
				    (goal_tick(1) = '1') ) then
				 Green_Win_next <= '1';
			end if;
			
		end process;
		
		process( pix_x		, pix_y		,
					score_txt, font_bit	,
					Blue_Win	, Green_Win	)
		begin
			obj_on 		<= '0';
			obj_RGB(0)  <= "00000000";
			obj_RGB(1)  <= "00000000";
			obj_RGB(2)	<= "00000000";
			
			char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
			row_addr  <= (others => '0');
			bit_addr  <= (others => '0');
			
			if( (score_Xmin <= pix_x) and (pix_x < score_Xmax) and
				 (score_Ymin <= pix_y) and (pix_y < score_Ymax) ) then
				 
				 row_addr <= std_logic_vector( pix_y(4 downto 1) );
				 --bit_addr <= std_logic_vector( to_unsigned( ((to_integer( pix_x ) - score_Xmin)*8*SCORE_CHARS)/(score_Xmax - score_Xmin)  , 3 ) );
				 bit_addr <= bit_addr_get(pix_x , score_Xmin, score_Xmax, SCORE_CHARS );
				 
				 
				 --Score no Modelo 5 caracteres com espaco entre eles: "0 x 0"
				 case switch_case( pix_x , score_Xmin, score_Xmax, SCORE_CHARS ) is
					when 0 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(score_txt(0))+48, 7 ) );
					when 2 => 	   char_addr <= std_logic_vector( to_unsigned( 16#78#      					  , 7 ) );
					when 4 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(score_txt(1))+48, 7 ) );
					when others => char_addr <= std_logic_vector( to_unsigned( 16#00#      					  , 7 ) );
				 end case;
				 
				 if( font_bit = '1' ) then
					obj_on <= '1';
					obj_RGB(0) <= "00000000";
					obj_RGB(1) <= "00000000";
					obj_RGB(2) <= "00000000";
				 end if;
				 
			end if;
			
			if( (Blue_Win = '1') or (Green_Win = '1') ) then
				if( Blue_Win = '1' ) then
					if( (Blue_Xmin <= pix_x) and (pix_x < Blue_Xmax) and
						 (Blue_Ymin <= pix_y) and (pix_y < Blue_Ymax) ) then
						 
						 row_addr  <= row_addr_get(pix_y , Blue_Ymin, Blue_Ymax );
						 bit_addr  <= bit_addr_get(pix_x , Blue_Xmin, Blue_Xmax, BLUECHARS );
						 --bit_addr <= std_logic_vector( to_unsigned( ((to_integer( pix_x ) - Blue_Xmin)*8*BLUECHARS)/(Blue_Xmax - Blue_Xmin)  , 3 ) );
						 --bit_addr  <= std_logic_vector( pix_x(8 downto 1) );
						 case switch_case( pix_x , Blue_Xmin, Blue_Xmax, BLUECHARS ) is
							when 0 => 	   char_addr <= std_logic_vector( to_unsigned( Blue_txt(0), 7 ) );
							when 1 => 	   char_addr <= std_logic_vector( to_unsigned( Blue_txt(1), 7 ) );
							when 2 => 	   char_addr <= std_logic_vector( to_unsigned( Blue_txt(2), 7 ) );
							when 3 => 	   char_addr <= std_logic_vector( to_unsigned( Blue_txt(3), 7 ) );
							when others => char_addr <= std_logic_vector( to_unsigned( 16#00#     , 7 ) );
						 end case;
						 
						 if( font_bit = '1' ) then
							obj_on <= '1';
							obj_RGB(0) <= "00000000";
							obj_RGB(1) <= "00000000";
							obj_RGB(2) <= "11111111";
						 end if;
					end if;
				end if;
				
				if( Green_Win = '1' ) then
					if( (Green_Xmin <= pix_x) and (pix_x < Green_Xmax) and
						 (Green_Ymin <= pix_y) and (pix_y < Green_Ymax) ) then
						 
						 row_addr  <= row_addr_get(pix_y , Green_Ymin, Green_Ymax );
						 bit_addr  <= bit_addr_get(pix_x , Green_Xmin, Green_Xmax, GREENCHARS );
						 --bit_addr <= std_logic_vector( to_unsigned( ((to_integer( pix_x ) - Green_Xmin)*8*GREENCHARS)/(Green_Xmax - Green_Xmin)  , 3 ) );
						 case switch_case( pix_x , Green_Xmin, Green_Xmax, GREENCHARS ) is
							when 0 => 	   char_addr <= std_logic_vector( to_unsigned( Green_txt(0), 7 ) );
							when 1 => 	   char_addr <= std_logic_vector( to_unsigned( Green_txt(1), 7 ) );
							when 2 => 	   char_addr <= std_logic_vector( to_unsigned( Green_txt(2), 7 ) );
							when 3 => 	   char_addr <= std_logic_vector( to_unsigned( Green_txt(3), 7 ) );
							when 4 => 	   char_addr <= std_logic_vector( to_unsigned( Green_txt(4), 7 ) );
							when others => char_addr <= std_logic_vector( to_unsigned( 16#00#      , 7 ) );
						 end case;
						 
						 if( font_bit = '1' ) then
							obj_on <= '1';
							obj_RGB(0) <= "00000000";
							obj_RGB(1) <= "11111111";
							obj_RGB(2) <= "00000000";
						 end if;
					end if;
				end if;
				
				if( (WIN_Xmin <= pix_x) and (pix_x < WIN_Xmax) and
					 (WIN_Ymin <= pix_y) and (pix_y < WIN_Ymax) ) then
					 
					 row_addr  <= row_addr_get(pix_y , WIN_Ymin, WIN_Ymax );
					 bit_addr  <= bit_addr_get(pix_x , WIN_Xmin, WIN_Xmax, WINCHARS );
					 --bit_addr <= std_logic_vector( to_unsigned( ((to_integer( pix_x ) - WIN_Xmin)*8*WINCHARS)/(WIN_Xmax - WIN_Xmin)  , 3 ) );
					 case switch_case( pix_x , WIN_Xmin, WIN_Xmax, WINCHARS ) is
						when 0 => 	   char_addr <= std_logic_vector( to_unsigned( WIN_txt(0), 7 ) );
						when 1 => 	   char_addr <= std_logic_vector( to_unsigned( WIN_txt(1), 7 ) );
						when 2 => 	   char_addr <= std_logic_vector( to_unsigned( WIN_txt(2), 7 ) );
						when others => char_addr <= std_logic_vector( to_unsigned( 16#00#    , 7 ) );
					 end case;
					 
					 if( font_bit = '1' ) then
						obj_on <= '1';
						if( Blue_Win = '1' ) then
							obj_RGB(0) <= "00000000";
							obj_RGB(1) <= "00000000";
							obj_RGB(2) <= "11111111";
						else
							obj_RGB(0) <= "00000000";
							obj_RGB(1) <= "11111111";
							obj_RGB(2) <= "00000000";
						end if;
					 end if;
				end if;
				
			end if;
			
		end process;
	rom_addr 	<= char_addr & row_addr;
	font_bit 	<= data(to_integer(unsigned(not bit_addr)));
end arch;