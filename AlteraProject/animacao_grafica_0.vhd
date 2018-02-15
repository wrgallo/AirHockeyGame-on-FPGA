library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

entity animacao_grafica_0 is
	port(
		--Sinais VGA Referenciais
		clk      , reset:	 	 	 in std_logic;
      pixel_x  , pixel_y: 	 	 in std_logic_vector (9 downto 0);
		refresh_tick60Hz:			 in std_logic;
      VGA_R, VGA_G, VGA_B:		out std_logic_vector(9 downto 0);
		
		--Sinais de Controle (In/Out)
		SW:							 in std_logic_vector (1 downto 0);
		numero:		 				 in unsigned(1 downto 0);
		flag_KEY:					 in std_logic;
		clr_flag:					out std_logic;
		LEDR:						   out std_logic_vector(3  downto 0);
		
		--Sinais de Controle Texto
		rom_addr:					out std_logic_vector(10 downto 0);
		data:							 in std_logic_vector(7  downto 0)
	);
	
	function bit_addr_get(px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer)
		return std_logic_vector is
	begin
		return std_logic_vector( to_unsigned( (( (8e04*Chars-1) / (Xmax - Xmin))*(to_integer( px_X ) - Xmin))/1e04 , 3 ) );
	end bit_addr_get;
	
	function row_addr_get(px_Y: unsigned ; Ymin: integer ; Ymax: integer)
		return std_logic_vector is
	begin
		return std_logic_vector( to_unsigned( (( (15e04-1) / (Ymax - Ymin))*(to_integer( px_Y ) - Ymin))/1e04 , 4 ) );
	end row_addr_get;
	
	function switch_case( px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer )
		return integer is
	begin
		--y = Chars/(Xmax - Xmin) * (x-200)
		return (( (Chars*1e04) / (Xmax - Xmin))*(to_integer( px_X ) - Xmin))/1e04;
	end switch_case;
	
end animacao_grafica_0;

architecture arch of animacao_grafica_0 is
	--Sinais Fundamentais
	signal R_reg , G_reg , B_reg:  std_logic_vector(9 downto 0);
	signal R_next, G_next, B_next: std_logic_vector(9 downto 0);
	signal pix_x: unsigned(9 downto 0) := unsigned( pixel_x );
	signal pix_y: unsigned(9 downto 0) := unsigned( pixel_y );
	
	--Cenario
	signal cenario_on:       std_logic;
	constant centroX:		    integer := 320;
	constant centroY:		    integer := 240;
	constant cenario_Xmin:   integer := 192;
	constant cenario_Xmax: 	 integer := 447;
	constant cenario_Ymin:   integer := 112;
	constant cenario_Ymax:   integer := 367;
	constant preto_RGB:	    integer := 0;
	signal   cenarioT_RGB, cenarioT_RGB_next:	 integer;
	signal   cenarioB_RGB, cenarioB_RGB_next:	 integer;
	signal   cenarioL_RGB, cenarioL_RGB_next:	 integer;
	signal   cenarioR_RGB, cenarioR_RGB_next:	 integer;
	signal	cor_cenarioRGB: integer := preto_RGB;
	type 		estados is (idle , flashing);
	signal	estT_reg, estT_next: estados := idle; --Top 		= Topo
	signal	estB_reg, estB_next: estados := idle; --Bottom  = Chao
	signal	estL_reg, estL_next: estados := idle; --Left 	= Esquerda
	signal	estR_reg, estR_next: estados := idle; --Right 	= Direita
	
	
	--Fundo
	constant cor_fundoR: integer := 255;
	constant cor_fundoG: integer := 255;
	constant cor_fundoB: integer := 255;
	
   --Bola
	signal sq_ball_on, rd_ball_on: std_logic;
   constant BALL_SIZE: integer:=8; -- 8
   signal ball_x_l, ball_x_r:  unsigned(9 downto 0);-- ball boundary
   signal ball_y_t, ball_y_b:  unsigned(9 downto 0);
   signal ball_x_reg, ball_x_next:  unsigned(9 downto 0) := to_unsigned(centroX - 15,10);-- reg to track left, top boundary
   signal ball_y_reg, ball_y_next:  unsigned(9 downto 0) := to_unsigned(centroY     ,10);
   signal x_delta_reg, x_delta_next: unsigned(9 downto 0):= ("0000000100");-- reg to track ball speed
   signal y_delta_reg, y_delta_next: unsigned(9 downto 0):= ("0000000100");
   signal BALL_V_P: unsigned(9 downto 0);-- ball velocity can be pos or neg)
   signal BALL_V_N: unsigned(9 downto 0);
	type rom_type is array (0 to 7) of std_logic_vector(0 to 7);
   constant BALL_ROM: rom_type :=
   (
      "00111100", --   ****
      "01111110", --  ******
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "01111110", --  ******
      "00111100"  --   ****
   );
	signal clr_flag_reg, clr_flag_next: std_logic := '0';
	constant cor_bola_R: 	integer := 255; --orange
	constant cor_bola_G: 	integer := 128;
	constant cor_bola_B: 	integer := 0;
	
	
	--Sinais Texto
	signal char_addr: std_logic_vector(6 downto 0) := (others => '0');
   signal row_addr:  std_logic_vector(3 downto 0) := (others => '0');
   signal bit_addr:  std_logic_vector(2 downto 0) := (others => '0');
   signal font_bit:  std_logic;
	
--	signal caractere_on: std_logic;
--	constant Ymin: integer := 240;
--	constant Ymax: integer := 360;
--	constant Xmin: integer := 300;
--	constant Xmax: integer := 400;
--	constant Nchars: integer := 2;
--	type palavra is array(0 to Nchars-1) of integer;
--	constant pal_teste: palavra := ( 16#33#, 16#34# );
	
	constant MAX_CHARS: integer := 2;
	type palavra is array(0 to MAX_CHARS-1) of unsigned(3 downto 0);
	-- *Marcadores
	constant MAX_NUMB: integer := 99;
	signal texto_esq: palavra := ("0000" , "0000");
	signal texto_dir: palavra := ("0000" , "0000");
	signal texto_cim: palavra := ("0000" , "0000");
	signal texto_bai: palavra := ("0000" , "0000");
	
	signal texto_esq_next: palavra := ("0000" , "0000");
	signal texto_dir_next: palavra := ("0000" , "0000");
	signal texto_cim_next: palavra := ("0000" , "0000");
	signal texto_bai_next: palavra := ("0000" , "0000");
	-- *Dimensoes e Posicoes
	constant txtY_dim: integer := 15;
	constant txtX_dim: integer := 25;
	constant pixel_shift: integer := 10;
	
	signal txt_inc:	std_logic_vector(3 downto 0);
	signal txt_on:		std_logic_vector(3 downto 0);
	signal txt0Ymin:  integer  := 300;
	signal txt0Xmin:  integer  := 300;
	signal txt0Ymax:  integer  := txt0Ymin + txtY_dim;
	signal txt0Xmax:  integer  := txt0Xmin + txtX_dim;
	signal txt1Ymin:  integer  := 300;
	signal txt1Xmin:  integer  := 300;
	signal txt1Ymax:  integer  := txt0Ymin + txtY_dim;
	signal txt1Xmax:  integer  := txt0Xmin + txtX_dim;
	signal txt2Ymin:  integer  := 300;
	signal txt2Xmin:  integer  := 300;
	signal txt2Ymax:  integer  := txt0Ymin + txtY_dim;
	signal txt2Xmax:  integer  := txt0Xmin + txtX_dim;
	signal txt3Ymin:  integer  := 300;
	signal txt3Xmin:  integer  := 300;
	signal txt3Ymax:  integer  := txt0Ymin + txtY_dim;
	signal txt3Xmax:  integer  := txt0Xmin + txtX_dim;
	
begin
	pix_x 	<= unsigned( pixel_x );
	pix_y 	<= unsigned( pixel_y );
	
	contador0: entity work.m100_counter
   port map(clk=>clk, reset=>reset, d_inc=>txt_inc(0), dig0 => texto_esq_next(1) , dig1 => texto_esq_next(0) );
	contador1: entity work.m100_counter
   port map(clk=>clk, reset=>reset, d_inc=>txt_inc(1), dig0 => texto_cim_next(1) , dig1 => texto_cim_next(0) );
	contador2: entity work.m100_counter
   port map(clk=>clk, reset=>reset, d_inc=>txt_inc(2), dig0 => texto_dir_next(1) , dig1 => texto_dir_next(0) );
	contador3: entity work.m100_counter
   port map(clk=>clk, reset=>reset, d_inc=>txt_inc(3), dig0 => texto_bai_next(1) , dig1 => texto_bai_next(0) );
	
	--txt0 = esquerda
	txt0Xmin <= to_integer(ball_x_l) - (txtX_dim + pixel_shift);
	txt0Ymin <= to_integer(ball_y_t) - 8;
	--txt1 = cima
	txt1Xmin <= to_integer(ball_x_l) - 4; 
	txt1Ymin <= to_integer(ball_y_t) - (txtY_dim + pixel_shift + 4 );
	--txt2 = direita
	txt2Xmin <= to_integer(ball_x_l) + (txtX_dim + pixel_shift - 4);
	txt2Ymin <= to_integer(ball_y_t) - 4;
	--txt3 = baixo
	txt3Xmin <= to_integer(ball_x_l) - 5; 					 
	txt3Ymin <= to_integer(ball_y_t) + (txtY_dim + pixel_shift );
	
	txt0Xmax	<= txt0Xmin + txtX_dim;
	txt0Ymax	<= txt0Ymin + txtY_dim;
	txt1Xmax	<= txt1Xmin + txtX_dim;
	txt1Ymax	<= txt1Ymin + txtY_dim;
	txt2Xmax	<= txt2Xmin + txtX_dim;
	txt2Ymax	<= txt2Ymin + txtY_dim;
	txt3Xmax	<= txt3Xmin + txtX_dim;
	txt3Ymax	<= txt3Ymin + txtY_dim;
	
	process( clk , reset, R_next, G_next, B_next )
	begin
		if( reset = '1' ) then
			R_reg <= std_logic_vector( to_unsigned(4* cor_fundoR , 10) );
			G_reg <= std_logic_vector( to_unsigned(4* cor_fundoG , 10) );
			B_reg <= std_logic_vector( to_unsigned(4* cor_fundoB , 10) );
			ball_x_reg <= to_unsigned(centroX-15,10);
			ball_y_reg <= to_unsigned(centroY   ,10);
			x_delta_reg <= ("0000000100");
         y_delta_reg <= ("0000000100");
			clr_flag_reg <= '0';
			estT_reg <= idle;
			estB_reg <= idle;
			estL_reg <= idle;
			estR_reg <= idle;
			cenarioT_RGB <= 0;
			cenarioB_RGB <= 0;
			cenarioL_RGB <= 0;
			cenarioR_RGB <= 0;
			texto_esq	 <= ("0000" , "0000");
			texto_dir	 <= ("0000" , "0000");
			texto_cim	 <= ("0000" , "0000");
			texto_bai	 <= ("0000" , "0000");
			
		elsif( clk'event and clk='1' ) then
			R_reg <= R_next;
			G_reg <= G_next;
			B_reg <= B_next;
			
			ball_x_reg 	 <= ball_x_next;
         ball_y_reg 	 <= ball_y_next;
         x_delta_reg  <= x_delta_next;
         y_delta_reg  <= y_delta_next;
			clr_flag_reg <= clr_flag_next;
			estT_reg 	 <= estT_next;
			estB_reg 	 <= estB_next;
			estL_reg 	 <= estL_next;
			estR_reg 	 <= estR_next;
			cenarioT_RGB <= cenarioT_RGB_next;
			cenarioB_RGB <= cenarioB_RGB_next;
			cenarioL_RGB <= cenarioL_RGB_next;
			cenarioR_RGB <= cenarioR_RGB_next;
			texto_esq	 <= texto_esq_next;
			texto_dir	 <= texto_dir_next;
			texto_cim	 <= texto_cim_next;
			texto_bai	 <= texto_bai_next;
			
		end if;
	end process;
	
	process(refresh_tick60Hz, SW      , 
			  x_delta_reg , y_delta_reg ,
			  ball_x_l    , ball_x_r    ,
           ball_y_t    , ball_y_b    ,
			  ball_x_reg  , ball_y_reg  ,
			  BALL_V_N	  , BALL_V_P    ,
			  flag_KEY    , numero      ,
			  estT_reg    , estB_reg    , estL_reg    , estR_reg   ,
			  estT_next   , estB_next   , estL_next   , estR_next  ,
			  cenarioT_RGB, cenarioB_RGB, cenarioL_RGB,cenarioR_RGB  )
   begin
      x_delta_next  	<= x_delta_reg;
      y_delta_next  	<= y_delta_reg;
		ball_x_next   	<= ball_x_reg;
		ball_y_next   	<= ball_y_reg;
		clr_flag_next 	<= '0';
		estT_next		<= estT_reg;
		estB_next		<= estB_reg;
		estL_next		<= estL_reg;
		estR_next		<= estR_reg;
		cenarioT_RGB_next <= cenarioT_RGB;
		cenarioB_RGB_next <= cenarioB_RGB;
		cenarioL_RGB_next <= cenarioL_RGB;
		cenarioR_RGB_next <= cenarioR_RGB;
		txt_inc <= (others => '0');
		
		if( refresh_tick60Hz = '1' ) then
			ball_x_next <= ball_x_reg + x_delta_reg;
			ball_y_next <= ball_y_reg + y_delta_reg;
			
			case( estT_next ) is
				when idle =>
					cenarioT_RGB_next <= 0;
					LEDR(0)           <= '0';
				when flashing =>
					LEDR(0)           <= '1';
					if( cenarioT_RGB  > 0 ) then cenarioT_RGB_next <= cenarioT_RGB - 1;
					end if;
					if( cenarioT_RGB <= 0 ) then estT_next <= idle;
					end if;
			end case;
			
			case( estB_next ) is
				when idle =>
					cenarioB_RGB_next <= 0;
					LEDR(1)           <= '0';
				when flashing =>
					LEDR(1)           <= '1';
					if( cenarioB_RGB  > 0 ) then cenarioB_RGB_next <= cenarioB_RGB - 1;
					end if;
					if( cenarioB_RGB  <= 0 ) then estB_next <= idle;
					end if;
			end case;
			
			case( estL_next ) is
				when idle =>
					cenarioL_RGB_next <= 0;
					LEDR(2)           <= '0';
				when flashing =>
					LEDR(2)           <= '1';
					if( cenarioL_RGB  > 0 ) then cenarioL_RGB_next <= cenarioL_RGB - 1;
					end if;
					if( cenarioL_RGB <= 0 ) then estL_next <= idle;
					end if;
			end case;
			
			case( estR_next ) is
				when idle =>
					cenarioR_RGB_next <= 0;
					LEDR(3)           <= '0';
				when flashing =>
					LEDR(3)           <= '1';
					if( cenarioR_RGB  > 0 ) then cenarioR_RGB_next <= cenarioR_RGB - 1;
					end if;
					if( cenarioR_RGB <= 0 ) then estR_next <= idle;
					end if;
			end case;
		end if;
		
		BALL_V_P <=             to_unsigned(1,10);-- ball velocity can be pos or neg)
		BALL_V_N <=     unsigned(to_signed(-1,10));
		if(    SW = "01" ) then
			BALL_V_P  <=         to_unsigned(3,10);
			BALL_V_N  <= unsigned(to_signed(-3,10));
		elsif( SW = "10" ) then
			BALL_V_P <=         to_unsigned(5,10);
			BALL_V_N <= unsigned(to_signed(-5,10));
		elsif( SW = "11" ) then
			BALL_V_P <=         to_unsigned(7,10);
			BALL_V_N <= unsigned(to_signed(-7,10));
		end if;
		
      if    ball_y_t <= cenario_Ymin     then  -- reach top
			y_delta_next <= BALL_V_P;
			cenarioT_RGB_next	<= 255;
			if( estT_reg = idle ) then
				estT_next <= flashing;
			end if;
			txt_inc(1) <= '1';
		
      elsif ball_y_b >= (cenario_Ymax-1) then  -- reach bottom
			y_delta_next <= BALL_V_N;
			cenarioB_RGB_next	<= 255;
			if( estB_reg = idle ) then
				estB_next <= flashing;
			end if;
			txt_inc(3) <= '1';
			
      elsif ball_x_l <= cenario_Xmin     then  -- reach left
			x_delta_next <= BALL_V_P;
			cenarioL_RGB_next	<= 255;
			if( estL_reg = idle ) then
				estL_next <= flashing;
			end if;
			txt_inc(0) <= '1';
			
		elsif ball_x_r >= cenario_Xmax     then  -- reach right
			x_delta_next <= BALL_V_N;
			cenarioR_RGB_next <= 255;
			if( estR_reg = idle ) then
				estR_next <= flashing;
			end if;
			txt_inc(2) <= '1';
		else
			if( flag_KEY = '1' ) then
				clr_flag_next <= '1';
				case to_integer( numero ) is
					when 0 =>
						y_delta_next <= BALL_V_P;
						x_delta_next <= BALL_V_P;
					when 1 =>
						y_delta_next <= BALL_V_P;
						x_delta_next <= BALL_V_N;
					when 2 =>
						y_delta_next <= BALL_V_N;
						x_delta_next <= BALL_V_P;
					when 3 =>
						y_delta_next <= BALL_V_N;
						x_delta_next <= BALL_V_N;
					when others =>
						x_delta_next  <= x_delta_reg;
						y_delta_next  <= y_delta_reg;
				end case;
			end if;
		end if;
   end process;
	
	process( pix_x, pix_y,
				cenarioL_RGB, cenarioR_RGB, cenarioT_RGB, cenarioB_RGB,
				ball_x_reg  , ball_y_reg,
				ball_x_l    , ball_y_t  , 
				ball_x_r    , ball_y_b  ,
				sq_ball_on  ,
				txt0Xmin    , txt0Xmax  , txt0Ymin , txt0Ymax , 
				txt1Xmin    , txt1Xmax  , txt1Ymin , txt1Ymax , 
				txt2Xmin    , txt2Xmax  , txt2Ymin , txt2Ymax , 
				txt3Xmin    , txt3Xmax  , txt3Ymin , txt3Ymax ,
				texto_esq   , texto_dir , texto_cim, texto_bai)
	begin		
	
		--Cenario
		cenario_on     <= '0';
		cor_cenarioRGB <= 0;
		if(      (pix_y >= cenario_Ymin  ) and (pix_y <= cenario_Ymax) ) then
			if(    pix_x  = cenario_Xmin  ) then
				cenario_on     <= '1';
				cor_cenarioRGB <= cenarioL_RGB;
			elsif( pix_x  = cenario_Xmax  ) then
				cenario_on     <= '1';
				cor_cenarioRGB <= cenarioR_RGB;
			end if;
		end if;
		
		if(       (pix_x >= cenario_Xmin) and (pix_x <= cenario_Xmax) ) then
			if(     pix_y  = cenario_Ymin) then
				cenario_on     <= '1';
				cor_cenarioRGB <= cenarioT_RGB;
			elsif(  pix_y  = cenario_Ymax) then
				cenario_on     <= '1';
				cor_cenarioRGB <= cenarioB_RGB;
			end if;
		end if;
		
		--Bola
		ball_x_l <= ball_x_reg;
		ball_y_t <= ball_y_reg;
		ball_x_r <= ball_x_l + BALL_SIZE - 1;
		ball_y_b <= ball_y_t + BALL_SIZE - 1;
		sq_ball_on <= '0';
		if( (ball_x_l<=pix_x) and (pix_x<=ball_x_r) and (ball_y_t<=pix_y) and (pix_y<=ball_y_b) ) then sq_ball_on <= '1';
		end if;
		rd_ball_on <= '0';
		if(( sq_ball_on='1' ) and BALL_ROM(to_integer(pix_x - ball_x_l))
						                      (to_integer(pix_y - ball_y_t)) = '1' ) then rd_ball_on <= '1';
		end if;
		
		-- **********************
		txt_on    <= (others => '0');
		char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
		row_addr  <= (others => '0');
		bit_addr  <= (others => '0');
		if( (txt0Ymin <= pix_y and pix_y <= txt0Ymax) and
			 (txt0Xmin <= pix_x and pix_x <= txt0Xmax)) then
			txt_on(0) <= '1';
			
			row_addr <= row_addr_get(pix_y , txt0Ymin, txt0Ymax );
			bit_addr <= bit_addr_get(pix_x , txt0Xmin, txt0Xmax, MAX_CHARS );
			
			case switch_case( pix_x , txt0Xmin, txt0Xmax, MAX_CHARS ) is
				when 0 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_esq(0))+48, 7 ) );
				when 1 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_esq(1))+48, 7 ) );
				when others => char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
			end case;
			
		elsif( (txt1Ymin <= pix_y and pix_y <= txt1Ymax) and
				 (txt1Xmin <= pix_x and pix_x <= txt1Xmax)) then
			txt_on(1) <= '1';
			
			row_addr <= row_addr_get(pix_y , txt1Ymin, txt1Ymax );
			bit_addr <= bit_addr_get(pix_x , txt1Xmin, txt1Xmax, MAX_CHARS );
			
			case switch_case( pix_x , txt1Xmin, txt1Xmax, MAX_CHARS ) is
				when 0 => 	   char_addr <= std_logic_vector( to_unsigned( 9-to_integer(texto_cim(0))+48, 7 ) );
				when 1 => 	   char_addr <= std_logic_vector( to_unsigned( 9-to_integer(texto_cim(1))+48, 7 ) );
				when others => char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
			end case;
			
		elsif( (txt2Ymin <= pix_y and pix_y <= txt2Ymax) and
				 (txt2Xmin <= pix_x and pix_x <= txt2Xmax)) then
			txt_on(2) <= '1';
			
			row_addr <= row_addr_get(pix_y , txt2Ymin, txt2Ymax );
			bit_addr <= bit_addr_get(pix_x , txt2Xmin, txt2Xmax, MAX_CHARS );
			
			case switch_case( pix_x , txt2Xmin, txt2Xmax, MAX_CHARS ) is
				when 0 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_dir(0))+48, 7 ) );
				when 1 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_dir(1))+48, 7 ) );
				when others => char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
			end case;
		
		elsif( (txt3Ymin <= pix_y and pix_y <= txt3Ymax) and
				 (txt3Xmin <= pix_x and pix_x <= txt3Xmax)) then
			txt_on(3) <= '1';
			
			row_addr <= row_addr_get(pix_y , txt3Ymin, txt3Ymax );
			bit_addr <= bit_addr_get(pix_x , txt3Xmin, txt3Xmax, MAX_CHARS );
			
			case switch_case( pix_x , txt3Xmin, txt3Xmax, MAX_CHARS ) is
				when 0 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_bai(0))+48, 7 ) );
				when 1 => 	   char_addr <= std_logic_vector( to_unsigned( to_integer(texto_bai(1))+48, 7 ) );
				when others => char_addr <= std_logic_vector( to_unsigned( 16#00#, 7 ) );
			end case;
		end if;
		
	end process;
	
	process( cenario_on , rd_ball_on, cor_cenarioRGB,
				txt_on, font_bit )
	begin
		R_next <= std_logic_vector( to_unsigned(4* cor_fundoR , 10) );
		G_next <= std_logic_vector( to_unsigned(4* cor_fundoG , 10) );
		B_next <= std_logic_vector( to_unsigned(4* cor_fundoB , 10) );
		
		if( ((txt_on(0) = '1')or(txt_on(1) = '1')or(txt_on(2) = '1')or(txt_on(3) = '1'))	and font_bit='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* cor_bola_R , 10) );
			G_next <= std_logic_vector( to_unsigned(4* cor_bola_G , 10) );
			B_next <= std_logic_vector( to_unsigned(4* cor_bola_B , 10) );
		elsif( cenario_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* cor_cenarioRGB , 10) );
			G_next <= std_logic_vector( to_unsigned(4* cor_cenarioRGB , 10) );
			B_next <= std_logic_vector( to_unsigned(4* cor_cenarioRGB , 10) );
		elsif( rd_ball_on='1' ) then
			R_next <= std_logic_vector( to_unsigned(4* cor_bola_R , 10) );
			G_next <= std_logic_vector( to_unsigned(4* cor_bola_G , 10) );
			B_next <= std_logic_vector( to_unsigned(4* cor_bola_B , 10) );
		end if;
	end process;
	
	VGA_R 	 	<= R_reg;
	VGA_G		 	<= G_reg;
	VGA_B 	 	<= B_reg;
	clr_flag		<= clr_flag_reg;
	
	rom_addr 	<= char_addr & row_addr;
	font_bit 	<= data(to_integer(unsigned(not bit_addr)));
end arch;
