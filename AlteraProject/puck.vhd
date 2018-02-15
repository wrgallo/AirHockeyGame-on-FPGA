library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TIPOS.all;

entity puck is
	port(
		clk, reset:				 in std_logic;
		stop_game:				 in std_logic;
		speed_tick:				 in std_logic;
		pixel_x, pixel_y:		 in std_logic_vector(9 downto 0);
		
		pad0_on:					 in std_logic;
		pad0_X:					 in std_logic_vector(9 downto 0);
		pad0_Y:					 in std_logic_vector(9 downto 0);
		pad1_on:					 in std_logic;
		pad1_X:					 in std_logic_vector(9 downto 0);
		pad1_Y:					 in std_logic_vector(9 downto 0);
		
		goal_tick:				out std_logic_vector(1 downto 0);
		
		puck_on:				out std_logic;
		puck_RGB:			out TYPE_COR
	);
	
end puck;

architecture arch of puck is
	--Definicoes basicas da img
	constant LINHAS:  integer := 30;
   constant COLUNAS: integer := 30;
	constant N_CORES:	integer := 30;
	--Dimensoes da Imagem na tela
	signal puck_Ymin: integer := (480-LINHAS)/2;--(480-dimensao)/2;
	signal puck_Xmin: integer := (640-COLUNAS)/2;--(640-dimensao)/2;
	signal puck_Ymax: integer := puck_Ymin + LINHAS;
	signal puck_Xmax: integer := puck_Xmin + COLUNAS;
	
	constant frontier_Xmax: integer := 640 - 25 - COLUNAS;
	constant frontier_Xmin: integer := 25;
	constant frontier_Ymin: integer := 26  + 15;
	constant frontier_Ymax: integer := 454 - 15;
	constant goal_Ymin:		integer := 165 + 20;
	constant goal_Ymax:		integer := 290 + 8;
	constant goal_Xmin:		integer := 1;
	constant goal_Xmax:		integer := 609 + COLUNAS;
	constant pad_dim:			integer := 61;
	--Definindo a img
	type linha_bitmap is array(0 to COLUNAS -1) of integer range 0 to N_CORES;
	type  puck_bitmap is array(0 to LINHAS  -1) of linha_bitmap;
	
   constant puck_matriz: puck_bitmap :=
	(
		(0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 2, 3, 3, 4, 4, 4, 4, 3, 5, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0),
		(1, 6, 6, 6, 6, 6, 6, 7, 5, 4, 8, 9, 9, 9, 10, 10, 10, 11, 11, 10, 12, 2, 6, 6, 6, 6, 6, 6, 6, 1),
		(1, 6, 6, 6, 6, 6, 2, 4, 8, 8, 8, 13, 13, 13, 10, 10, 10, 11, 11, 11, 14, 14, 12, 7, 6, 6, 6, 6, 6, 1),
		(1, 6, 6, 6, 6, 3, 8, 8, 8, 8, 13, 13, 9, 10, 10, 10, 11, 11, 11, 11, 14, 15, 16, 17, 2, 6, 6, 6, 6, 1),
		(1, 6, 6, 6, 3, 8, 8, 8, 8, 13, 13, 13, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 16, 11, 2, 6, 6, 6, 1),
		(1, 6, 6, 3, 8, 8, 8, 8, 13, 13, 13, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 15, 16, 18, 19, 7, 6, 6, 1),
		(1, 6, 2, 8, 8, 8, 8, 13, 13, 13, 10, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 15, 20, 20, 20, 18, 17, 1, 6, 1),
		(1, 7, 4, 8, 8, 8, 13, 13, 13, 10, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 15, 20, 20, 20, 20, 20, 21, 5, 6, 1),
		(1, 5, 8, 8, 8, 13, 13, 13, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 15, 20, 20, 20, 20, 20, 22, 23, 19, 7, 1),
		(0, 4, 8, 8, 13, 13, 13, 9, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 24, 5, 1),
		(2, 8, 8, 13, 13, 13, 9, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 20, 22, 22, 22, 23, 25, 17, 1),
		(3, 8, 13, 13, 13, 9, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 24, 26, 0),
		(3, 9, 13, 13, 10, 10, 10, 10, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 22, 23, 23, 24, 22, 2),
		(4, 9, 13, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 5),
		(4, 9, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 20, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 27, 27, 24, 5),
		(4, 10, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 20, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 27, 27, 27, 25, 5),
		(4, 10, 10, 11, 11, 11, 11, 14, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 27, 27, 27, 25, 24, 5),
		(3, 11, 11, 11, 11, 14, 15, 15, 15, 15, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 24, 27, 27, 27, 25, 25, 23, 2),
		(3, 14, 11, 11, 14, 15, 15, 15, 15, 16, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 24, 27, 27, 27, 27, 25, 28, 26, 0),
		(2, 11, 11, 14, 15, 15, 15, 15, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 27, 27, 27, 27, 27, 25, 25, 28, 17, 1),
		(0, 13, 15, 15, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 27, 27, 27, 27, 25, 25, 25, 25, 28, 5, 1),
		(1, 5, 16, 15, 15, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 24, 27, 27, 27, 25, 25, 25, 25, 28, 26, 7, 1),
		(1, 7, 10, 16, 16, 20, 20, 20, 20, 22, 22, 22, 22, 23, 23, 23, 23, 24, 27, 27, 27, 25, 25, 25, 25, 25, 28, 12, 6, 1),
		(1, 6, 5, 20, 20, 20, 20, 22, 22, 22, 22, 22, 23, 23, 23, 27, 27, 27, 27, 27, 25, 25, 25, 25, 25, 28, 19, 1, 6, 1),
		(1, 6, 6, 12, 18, 20, 22, 22, 22, 22, 22, 23, 23, 23, 27, 27, 27, 27, 25, 25, 25, 25, 25, 25, 28, 26, 2, 6, 6, 1),
		(1, 6, 6, 1, 17, 21, 22, 22, 22, 22, 23, 23, 23, 24, 27, 27, 27, 25, 25, 25, 25, 25, 25, 28, 29, 2, 6, 6, 6, 1),
		(1, 6, 6, 6, 1, 12, 21, 23, 23, 23, 23, 23, 27, 27, 27, 27, 25, 25, 25, 25, 25, 25, 28, 26, 2, 6, 6, 6, 6, 1),
		(1, 6, 6, 6, 6, 6, 5, 19, 25, 24, 24, 23, 27, 27, 27, 27, 25, 25, 25, 25, 28, 28, 17, 7, 6, 6, 6, 6, 6, 1),
		(1, 6, 6, 6, 6, 6, 6, 7, 12, 19, 24, 28, 25, 25, 25, 25, 25, 28, 28, 29, 17, 5, 6, 6, 6, 6, 6, 6, 6, 1),
		(0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 5, 12, 10, 20, 22, 22, 20, 11, 12, 2, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0)
	);
	
	signal cor_indice : integer := 0;
	type cor_int is array(0 to 2) of integer range 0 to 255;
	type matriz_cores is array(0 to N_CORES-1) of cor_int;
	constant puck_cores: matriz_cores :=
	(
		(28, 192, 207),--0
		(14, 192, 208),--1
		(34, 169, 181),
		(70, 141, 148),
		(84, 112, 115),
		(36, 149, 159),
		(0, 189, 206),--6
		(15, 183, 198),--7
		(92, 90, 90),
		(83, 80, 80),
		(75, 75, 75),
		(67, 67, 67),
		(47, 119, 125),
		(83, 84, 84),
		(61, 60, 60),
		(57, 57, 57),
		(53, 50, 50),
		(40, 87, 92),
		(46, 37, 37),
		(39, 64, 66),
		(47, 47, 47),
		(42, 32, 32),
		(39, 39, 39),
		(32, 32, 32),
		(31, 27, 27),
		(23, 22, 22),
		(29, 46, 48),
		(27, 27, 27),
		(20, 12, 11),
		(25, 33, 34)
	);

	
	signal pix_x: unsigned(9 downto 0) := unsigned( pixel_x );
	signal pix_y: unsigned(9 downto 0) := unsigned( pixel_y );
	
	signal pad0X: unsigned(9 downto 0) := unsigned( pad0_X );
	signal pad0Y: unsigned(9 downto 0) := unsigned( pad0_Y );
	signal pad1X: unsigned(9 downto 0) := unsigned( pad1_X );
	signal pad1Y: unsigned(9 downto 0) := unsigned( pad1_Y );
	
	-- reg to track ball speed
	signal puck_Ymin_next: integer := puck_Ymin;
	signal puck_Xmin_next: integer := puck_Xmin;
   signal x_delta_reg, x_delta_next: unsigned(9 downto 0) := ("0000000000");
   signal y_delta_reg, y_delta_next: unsigned(9 downto 0) := ("0000000000");
	signal x_dir		, x_dir_next:	 std_logic := '1';--Direcao positiva '1' ou negativa '0'
	signal y_dir		, y_dir_next: 	 std_logic := '1';--Direcao positiva '1' ou negativa '0'
	signal puck_X_cent, puck_Y_cent:	integer;
	signal pad0x_cent , pad0y_cent:	integer;
	signal pad1x_cent , pad1y_cent:	integer;
	constant ajusteA: integer := 1;
	constant ajusteB: integer := 4;
	signal obj_on: std_logic;
	
	signal goal_tick_reg, goal_tick_next: std_logic_vector(1 downto 0);
	
	begin
		pix_x 	 	<= unsigned( pixel_x );
		pix_y 	 	<= unsigned( pixel_y );
		pad0X 	 	<= unsigned( pad0_X );
		pad0Y 	 	<= unsigned( pad0_Y );
		pad1X 	 	<= unsigned( pad1_X );
		pad1Y 	 	<= unsigned( pad1_Y );
		puck_X_cent <= puck_Xmin + 15;
		puck_Y_cent <= puck_Ymin + 15;
		pad0x_cent  <= to_integer( pad0X ) + (pad_dim)/2;
		pad0y_cent  <= to_integer( pad0Y ) + (pad_dim)/2;
		pad1x_cent  <= to_integer( pad1X ) + (pad_dim)/2;
		pad1y_cent  <= to_integer( pad1Y ) + (pad_dim)/2;
		puck_Ymax 	<= puck_Ymin + LINHAS;
		puck_Xmax 	<= puck_Xmin + COLUNAS;
		
		--Atualizador de Registradores
		process( clk				, reset				, 
					x_delta_next	, y_delta_next		,
					puck_Xmin_next	, puck_Ymin_next	,
					stop_game )
		begin
			if( reset = '1' or stop_game = '1' ) then
				puck_Ymin 		<= (480-LINHAS)/2;
				puck_Xmin 		<= (640-COLUNAS)/2;
				x_delta_reg 	<= ("0000000000");
				y_delta_reg 	<= ("0000000000");
				x_dir				<= '1';
				y_dir				<= '1';
				goal_tick_reg 	<= ( others => '0' );
			elsif( clk'event and clk='1' ) then
				x_delta_reg 	<= x_delta_next;
				y_delta_reg 	<= y_delta_next;
				puck_Ymin 		<= puck_Ymin_next;
				puck_Xmin 		<= puck_Xmin_next;
				x_dir				<= x_dir_next;
				y_dir				<= y_dir_next;
				goal_tick_reg 	<= goal_tick_next;
			end if;
		end process;
		
		
		
		--Atualizador Posicao
		process( pix_x			, pix_y			,
					pad0x			, pad0y			,
					pad1x			, pad1y			,
					x_delta_reg	, y_delta_reg	,
					x_delta_next, y_delta_next ,
					x_dir			, y_dir			,
					x_dir_next	, y_dir_next	,
					puck_Xmin	, puck_Ymin		,
					puck_Xmax	, puck_Ymax		,
					pad0_on		, pad1_on		,
					puck_X_cent	, puck_Y_cent	,
					pad0x_cent	, pad0y_cent	,
					pad1x_cent	, pad1y_cent	,
					obj_on		, speed_tick   ,
					goal_tick_reg	)
		begin
			x_delta_next 	<= x_delta_reg;
			y_delta_next 	<= y_delta_reg;
			puck_Xmin_next	<= puck_Xmin;
			puck_Ymin_next	<= puck_Ymin;
			goal_tick_next <= goal_tick_reg;
			x_dir_next		<= x_dir;
			y_dir_next		<= y_dir;
			
			--Velocidade em caso de colisao com paddle			
			if( obj_on = '1' ) then
				if( pad0_on = '1'  ) then
					if( puck_X_cent < pad0x_cent ) then
						x_dir_next <= '0';
						x_delta_next <= to_unsigned( 1 + ajusteA*(pad0x_cent - puck_X_cent )/ajusteB  , 10);
					else
						x_dir_next <= '1';
						x_delta_next <= to_unsigned( 1 + ajusteA*(puck_X_cent - pad0x_cent)/ajusteB  , 10);					
					end if;
					
					if( puck_Y_cent < pad0y_cent ) then 
						y_dir_next <= '0';
						y_delta_next <= to_unsigned( 1 + ajusteA*(pad0y_cent - puck_Y_cent )/ajusteB  , 10);
					else
						y_dir_next <= '1';
						y_delta_next <= to_unsigned( 1 + ajusteA*(puck_Y_cent - pad0y_cent)/ajusteB  , 10);
					end if;
					
				elsif( pad1_on = '1'  ) then
					
					if( puck_X_cent < pad1x_cent ) then
						x_dir_next <= '0';
						x_delta_next <= to_unsigned( 1 + ajusteA*(pad1x_cent - puck_X_cent )/ajusteB  , 10);
					else
						x_dir_next <= '1';
						x_delta_next <= to_unsigned( 1 + ajusteA*(puck_X_cent - pad1x_cent)/ajusteB  , 10);					
						
					end if;
					if( puck_Y_cent < pad1y_cent ) then 
						y_dir_next <= '0';
						y_delta_next <= to_unsigned( 1 + ajusteA*(pad1y_cent - puck_Y_cent )/ajusteB  , 10);
					else
						y_dir_next <= '1';
						y_delta_next <= to_unsigned( 1 + ajusteA*(puck_Y_cent - pad1y_cent)/ajusteB  , 10);
						
					end if;
					
				end if;
			end if;

			--Velocidade em caso de colisao com mesa E detector de gols
			if( (puck_Ymax <= goal_Ymax) and (puck_Ymin >= goal_Ymin) ) then
				goal_tick_next	 <= ( others => '0' );
				if(    puck_Xmin <= goal_Xmin ) then
					goal_tick_next <= "10";
					puck_Ymin_next	<= (480-LINHAS)/2;
					puck_Xmin_next	<= (640-COLUNAS)/2;
					x_delta_next 	<= ("0000000000");
					y_delta_next	<= ("0000000000");
				elsif( puck_Xmax >= goal_Xmax ) then
					goal_tick_next	<= "01";
					puck_Ymin_next	<= (480-LINHAS)/2;
					puck_Xmin_next	<= (640-COLUNAS)/2;
					x_delta_next 	<= ("0000000000");
					y_delta_next	<= ("0000000000");
				else
					goal_tick_next	<= ( others => '0' );
					
					if( (puck_Xmax <= frontier_Xmin ) or ( puck_Xmin >= frontier_Xmax ) ) then
						if(    puck_Ymin = goal_Ymin ) then y_dir_next  <= '1';
						elsif( puck_Ymax = goal_Ymax ) then y_dir_next  <= '0';
						end if;
					end if;
					
				end if;
			else
				if(    puck_Xmin <= frontier_Xmin ) then x_dir_next  <= '1';
				elsif( puck_Xmin >= frontier_Xmax ) then x_dir_next  <= '0';
				end if;
				
				if(    puck_Ymin <= frontier_Ymin ) then y_dir_next  <= '1';
				elsif( puck_Ymax >= frontier_Ymax ) then y_dir_next  <= '0';
				end if;
			end if;
			
			--Atualiza Proxima Posicao
			if( speed_tick = '1' ) then
				if( x_dir = '1' ) then puck_Xmin_next <= puck_Xmin + to_integer( x_delta_next );
				else						  puck_Xmin_next <= puck_Xmin - to_integer( x_delta_next );	
				end if;
				if( y_dir = '1' ) then puck_Ymin_next <= puck_Ymin + to_integer( y_delta_next );
				else						  puck_Ymin_next <= puck_Ymin - to_integer( y_delta_next );
				end if;
			end if;
		end process;
		
		
		
		--Verifica saída de video
		process( pix_x, pix_y, cor_indice,
					Puck_Xmin, Puck_Xmax, Puck_Ymin, Puck_Ymax )
		begin
			puck_on		<= '0';
			obj_on		<= '0';
			puck_RGB(0) <= "00000000";
			puck_RGB(1) <= "00000000";
			puck_RGB(2)	<= "00000000";
			cor_indice	<= 0;
			
			if( (Puck_Xmin <= pix_x) and (pix_x < Puck_Xmax) and
				 (Puck_Ymin <= pix_y) and (pix_y < Puck_Ymax) ) then
				
				cor_indice	<= puck_matriz( to_integer( pix_Y ) - Puck_Ymin )
												  ( to_integer( pix_X ) - Puck_Xmin );
				
				case cor_indice is
					when 0  =>
						puck_on  <= '0';
						obj_on	<= '0';
					when 1  =>
						puck_on <= '0';
						obj_on  <= '0';
					when 6  =>
						puck_on <= '0';
						obj_on  <= '0';
					when 7  => 
						puck_on <= '0';
						obj_on  <= '0';
					when others =>
						puck_on <= '1';
						obj_on  <= '1';
				end case;
				
				puck_RGB(0) <= RGB_UNSIGNED( puck_cores(cor_indice)(0) );
				puck_RGB(1) <= RGB_UNSIGNED( puck_cores(cor_indice)(1) );
				puck_RGB(2) <= RGB_UNSIGNED( puck_cores(cor_indice)(2) );
							
			end if;
			
		end process;
		
		goal_tick <= goal_tick_reg;
end arch;