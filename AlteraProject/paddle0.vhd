library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.TIPOS.all;

entity paddle0 is
	port(
		--Essential
		clk, reset:				 in std_logic;
		pixel_x, pixel_y:		 in std_logic_vector(9 downto 0);
		stop_game:				 in std_logic;
		
		--Reset Position with Score
		goal_tick:				 in std_logic_vector(1 downto 0);
		
		--Joystick
		refresh_tick_pad:		 in std_logic;
		pad0_Ry_EN:				 in std_logic;
		pad0_Ry:					 in std_logic;
		pad0_Rx_EN:				 in std_logic;
		pad0_Rx:					 in std_logic;
		--Pad Position
		pad_X:					out std_logic_vector(9 downto 0);
		pad_Y:					out std_logic_vector(9 downto 0);
		--Pad Color
		obj_on:				out std_logic;
		obj_RGB:				out TYPE_COR
	);
	
end paddle0;

architecture arch of paddle0 is
	signal forced_rst: std_logic := '0';
	--Definicoes basicas da img
	constant LINHAS:  integer := 61;
   constant COLUNAS: integer := 61;
	constant N_CORES:	integer := 30;
	
	--Dimensoes da Imagem na tela
	signal obj_Ymin: integer := (480-LINHAS)/2;
	signal obj_Xmin: integer := 50;
	signal obj_Ymax: integer := obj_Ymin + LINHAS;
	signal obj_Xmax: integer := obj_Xmin + COLUNAS;
	
	signal obj_Ymin_next: integer := obj_Ymin;
	signal obj_Xmin_next: integer := obj_Xmin;
	
	constant frontier_Xmax: integer := 322 - COLUNAS;
	constant frontier_Xmin: integer := 25;
	constant frontier_Ymin: integer := 26  + 15;
	constant frontier_Ymax: integer := 454 - 13 - LINHAS;
	
	--Definindo a img
	type linha_bitmap is array(0 to COLUNAS -1) of integer range 0 to N_CORES;
	type   obj_bitmap is array(0 to LINHAS  -1) of linha_bitmap;
	
   constant obj_matriz: obj_bitmap :=
	(
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 4, 4, 4, 4, 4, 3, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 6, 7, 8, 2, 2, 2, 2, 2, 2, 2, 2, 8, 5, 6, 6, 7, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 6, 5, 7, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 5, 6, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 5, 2, 2, 2, 2, 9, 3, 10, 10, 4, 4, 4, 4, 10, 4, 4, 4, 3, 8, 2, 2, 2, 2, 7, 6, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 6, 5, 2, 2, 2, 9, 11, 12, 10, 12, 13, 13, 13, 10, 10, 10, 12, 10, 10, 14, 14, 14, 4, 3, 8, 2, 2, 2, 5, 15, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 5, 8, 2, 2, 3, 12, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 16, 16, 14, 14, 14, 10, 3, 2, 2, 8, 6, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 15, 5, 2, 2, 3, 10, 12, 13, 10, 13, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 13, 13, 12, 14, 14, 3, 2, 2, 8, 15, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 15, 8, 2, 8, 11, 14, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 16, 10, 10, 10, 8, 2, 8, 17, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 8, 2, 3, 10, 12, 13, 10, 13, 10, 10, 13, 10, 10, 13, 10, 10, 10, 10, 10, 10, 10, 16, 10, 16, 10, 10, 10, 10, 10, 10, 10, 16, 16, 14, 10, 3, 2, 8, 15, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 5, 6, 8, 8, 3, 10, 10, 10, 10, 10, 10, 10, 13, 10, 10, 10, 16, 10, 10, 10, 12, 10, 13, 10, 14, 14, 14, 16, 12, 13, 10, 10, 10, 10, 10, 10, 10, 11, 10, 3, 2, 8, 6, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 7, 6, 8, 8, 3, 4, 10, 10, 10, 10, 10, 10, 10, 10, 12, 12, 10, 18, 18, 18, 18, 18, 18, 18, 18, 4, 18, 18, 4, 19, 13, 10, 14, 10, 10, 16, 16, 10, 10, 10, 10, 3, 8, 8, 6, 7, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 1, 17, 3, 8, 3, 4, 10, 10, 10, 10, 10, 16, 16, 10, 10, 4, 18, 18, 18, 18, 18, 18, 18, 18, 4, 4, 18, 18, 18, 18, 18, 18, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 18, 3, 8, 3, 15, 1, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 15, 3, 8, 3, 4, 11, 10, 10, 10, 10, 16, 10, 10, 4, 18, 18, 18, 18, 14, 4, 4, 4, 3, 3, 10, 4, 4, 4, 4, 4, 18, 18, 18, 18, 4, 10, 10, 10, 10, 10, 10, 10, 14, 4, 3, 8, 3, 15, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 15, 6, 8, 3, 4, 11, 10, 10, 10, 10, 10, 10, 4, 18, 18, 18, 18, 4, 4, 4, 3, 8, 8, 2, 2, 2, 2, 8, 8, 3, 10, 10, 4, 4, 18, 18, 4, 19, 10, 10, 10, 10, 13, 14, 10, 20, 3, 8, 6, 17, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 7, 15, 8, 3, 10, 11, 13, 10, 10, 10, 10, 10, 4, 18, 18, 4, 4, 4, 4, 3, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 3, 4, 4, 14, 18, 18, 18, 4, 10, 10, 16, 16, 16, 10, 4, 4, 8, 3, 15, 5, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 15, 3, 8, 10, 10, 10, 10, 10, 10, 10, 10, 11, 21, 18, 4, 10, 4, 4, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 10, 14, 4, 18, 18, 18, 4, 13, 16, 16, 10, 16, 14, 10, 10, 3, 3, 15, 0, 0, 0, 0, 0),
		(0, 0, 0, 5, 15, 3, 3, 12, 16, 10, 10, 10, 10, 13, 10, 18, 18, 4, 4, 14, 10, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 4, 4, 4, 18, 18, 18, 10, 13, 13, 10, 16, 16, 14, 4, 3, 3, 6, 7, 0, 0, 0, 0),
		(0, 0, 0, 6, 10, 3, 10, 16, 10, 10, 10, 10, 10, 11, 18, 18, 18, 14, 14, 4, 8, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 8, 4, 4, 4, 18, 18, 18, 10, 14, 10, 10, 16, 10, 11, 10, 3, 3, 6, 1, 0, 0, 0),
		(0, 0, 7, 6, 3, 3, 13, 10, 10, 16, 10, 10, 12, 18, 18, 18, 4, 14, 4, 3, 2, 2, 2, 2, 2, 8, 8, 3, 3, 3, 3, 3, 3, 8, 8, 2, 2, 2, 2, 2, 3, 4, 4, 4, 18, 18, 4, 13, 10, 10, 10, 10, 10, 10, 3, 3, 4, 7, 0, 0, 0),
		(0, 0, 17, 4, 3, 10, 10, 10, 10, 10, 10, 10, 4, 18, 18, 18, 10, 4, 10, 8, 2, 2, 2, 8, 8, 3, 10, 10, 10, 10, 10, 10, 10, 10, 3, 8, 8, 2, 2, 2, 8, 4, 4, 20, 4, 18, 18, 4, 10, 13, 10, 10, 10, 11, 10, 3, 4, 15, 0, 0, 0),
		(0, 1, 17, 10, 3, 13, 10, 10, 10, 10, 10, 11, 18, 18, 18, 4, 4, 4, 3, 2, 2, 8, 8, 3, 3, 10, 10, 14, 14, 14, 14, 14, 10, 10, 10, 3, 3, 8, 8, 2, 2, 3, 4, 4, 4, 18, 21, 18, 13, 12, 10, 10, 10, 13, 11, 3, 10, 15, 1, 0, 0),
		(0, 5, 18, 3, 10, 10, 10, 10, 10, 10, 10, 18, 18, 18, 4, 4, 14, 10, 8, 2, 8, 3, 3, 3, 10, 10, 10, 10, 10, 14, 14, 10, 4, 10, 10, 10, 10, 3, 8, 8, 2, 8, 10, 4, 4, 18, 18, 21, 4, 13, 13, 10, 10, 10, 12, 10, 3, 4, 5, 0, 0),
		(0, 17, 4, 3, 13, 10, 10, 10, 10, 10, 4, 18, 21, 18, 4, 4, 14, 3, 8, 8, 3, 3, 10, 10, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 14, 10, 10, 3, 3, 8, 8, 3, 4, 4, 18, 18, 21, 18, 4, 10, 10, 10, 10, 10, 13, 10, 4, 15, 0, 0),
		(0, 15, 10, 10, 13, 10, 10, 10, 10, 10, 18, 21, 18, 18, 4, 14, 14, 3, 8, 8, 3, 10, 10, 14, 10, 10, 10, 14, 14, 10, 4, 4, 10, 10, 10, 10, 10, 10, 10, 3, 8, 8, 3, 4, 4, 4, 18, 18, 18, 4, 10, 10, 16, 10, 10, 10, 10, 14, 15, 0, 0),
		(1, 15, 10, 13, 16, 10, 10, 10, 10, 4, 18, 21, 18, 18, 4, 14, 14, 3, 8, 3, 10, 10, 10, 10, 10, 10, 10, 14, 14, 10, 10, 4, 10, 10, 10, 10, 10, 10, 4, 3, 3, 3, 3, 4, 4, 4, 18, 18, 18, 18, 4, 10, 14, 16, 10, 10, 10, 14, 6, 1, 0),
		(3, 4, 14, 14, 16, 10, 10, 10, 10, 4, 21, 21, 18, 4, 4, 4, 10, 3, 3, 3, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 3, 3, 3, 10, 10, 4, 18, 18, 21, 21, 4, 10, 14, 16, 10, 10, 10, 10, 4, 5, 0),
		(4, 4, 10, 14, 14, 10, 10, 10, 10, 4, 21, 21, 18, 4, 4, 4, 4, 10, 3, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 3, 10, 10, 10, 4, 18, 18, 21, 21, 4, 10, 10, 14, 10, 10, 10, 10, 4, 5, 0),
		(18, 4, 10, 14, 16, 10, 10, 10, 10, 18, 21, 21, 18, 4, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 18, 18, 21, 21, 18, 10, 10, 10, 10, 10, 10, 10, 4, 15, 0),
		(21, 18, 10, 14, 14, 10, 10, 10, 4, 18, 21, 21, 18, 4, 4, 4, 4, 22, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 10, 10, 10, 10, 4, 18, 18, 21, 21, 18, 4, 10, 10, 10, 10, 10, 10, 4, 17, 0),
		(21, 18, 10, 14, 10, 10, 10, 14, 4, 18, 21, 21, 18, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 10, 10, 10, 10, 4, 18, 18, 21, 21, 18, 4, 10, 10, 10, 10, 10, 10, 4, 17, 0),
		(21, 18, 10, 14, 10, 10, 10, 10, 4, 18, 21, 21, 18, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 14, 10, 4, 18, 18, 21, 21, 18, 4, 10, 10, 10, 10, 10, 10, 4, 17, 0),
		(18, 4, 22, 14, 10, 10, 13, 10, 4, 18, 21, 21, 18, 18, 4, 4, 10, 10, 10, 10, 10, 10, 14, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 14, 14, 4, 4, 18, 18, 21, 21, 18, 4, 10, 10, 10, 10, 10, 10, 4, 17, 0),
		(18, 4, 10, 14, 10, 10, 10, 10, 10, 18, 21, 21, 18, 18, 4, 4, 10, 10, 10, 10, 10, 14, 14, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 14, 14, 4, 4, 18, 18, 21, 21, 18, 4, 11, 10, 10, 10, 10, 10, 4, 17, 0),
		(18, 18, 10, 14, 13, 13, 10, 16, 4, 18, 21, 21, 21, 18, 4, 14, 14, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 13, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 18, 18, 21, 21, 18, 4, 10, 16, 16, 10, 16, 14, 4, 17, 0),
		(23, 18, 10, 14, 10, 10, 10, 16, 4, 18, 21, 21, 21, 18, 4, 14, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 18, 18, 18, 21, 21, 18, 4, 10, 10, 10, 10, 16, 10, 18, 5, 0),
		(8, 18, 4, 14, 13, 10, 10, 10, 10, 18, 21, 21, 21, 18, 18, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 4, 18, 18, 21, 24, 21, 18, 4, 10, 16, 10, 10, 10, 4, 21, 7, 0),
		(1, 17, 4, 10, 14, 10, 10, 10, 10, 18, 21, 21, 21, 21, 18, 18, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 4, 18, 18, 21, 21, 24, 21, 18, 10, 16, 10, 10, 10, 10, 4, 17, 1, 0),
		(0, 17, 18, 10, 14, 10, 10, 10, 10, 18, 21, 24, 21, 21, 18, 18, 4, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 4, 4, 18, 18, 21, 21, 24, 21, 18, 10, 16, 10, 10, 10, 10, 18, 17, 0, 0),
		(0, 5, 18, 10, 10, 13, 10, 10, 16, 4, 18, 21, 24, 21, 21, 18, 18, 18, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 19, 18, 18, 21, 21, 24, 21, 18, 4, 10, 16, 10, 10, 10, 10, 18, 5, 0, 0),
		(0, 7, 18, 4, 10, 13, 10, 10, 16, 10, 18, 21, 24, 21, 21, 21, 18, 18, 18, 4, 4, 10, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 18, 18, 18, 21, 24, 24, 21, 18, 4, 10, 16, 10, 10, 10, 10, 21, 1, 0, 0),
		(0, 1, 15, 18, 10, 10, 10, 10, 10, 10, 25, 21, 24, 24, 21, 21, 18, 18, 18, 4, 4, 10, 14, 14, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 18, 18, 21, 21, 24, 24, 21, 18, 10, 16, 10, 10, 10, 4, 4, 17, 1, 0, 0),
		(0, 0, 17, 21, 14, 14, 10, 10, 10, 10, 4, 18, 21, 24, 24, 21, 21, 18, 18, 4, 4, 4, 4, 18, 10, 10, 10, 10, 10, 10, 10, 10, 14, 10, 10, 4, 4, 4, 18, 18, 4, 18, 21, 21, 21, 24, 24, 24, 4, 11, 10, 10, 16, 10, 10, 4, 18, 5, 0, 0, 0),
		(0, 0, 1, 17, 4, 14, 16, 10, 10, 10, 12, 18, 21, 24, 24, 24, 21, 21, 18, 18, 18, 18, 4, 4, 4, 4, 4, 10, 10, 10, 10, 10, 10, 10, 10, 4, 4, 4, 18, 18, 18, 21, 21, 21, 24, 24, 24, 21, 4, 10, 10, 10, 10, 10, 4, 4, 17, 1, 0, 0, 0),
		(0, 0, 0, 17, 18, 4, 10, 10, 10, 10, 10, 4, 18, 21, 24, 24, 24, 21, 21, 21, 18, 18, 18, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 18, 18, 18, 18, 21, 21, 21, 24, 24, 24, 21, 25, 11, 10, 10, 10, 16, 10, 4, 18, 17, 0, 0, 0, 0),
		(0, 0, 0, 1, 26, 18, 10, 10, 10, 10, 10, 13, 4, 18, 24, 24, 24, 24, 21, 21, 21, 21, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 21, 21, 21, 21, 24, 24, 24, 24, 18, 11, 12, 10, 10, 16, 10, 10, 4, 17, 1, 0, 0, 0, 0),
		(0, 0, 0, 0, 17, 17, 11, 10, 10, 10, 10, 16, 10, 18, 21, 24, 24, 24, 24, 24, 21, 21, 21, 21, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 21, 21, 21, 21, 21, 24, 24, 24, 24, 21, 4, 10, 13, 13, 10, 16, 10, 4, 21, 15, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 17, 27, 12, 10, 10, 10, 16, 10, 4, 18, 21, 24, 24, 24, 24, 24, 21, 21, 21, 21, 21, 21, 21, 18, 18, 18, 18, 21, 21, 21, 21, 21, 21, 21, 21, 24, 24, 24, 24, 21, 18, 11, 10, 10, 10, 10, 10, 4, 21, 17, 1, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 5, 17, 25, 4, 10, 10, 10, 10, 10, 4, 4, 21, 21, 24, 24, 24, 24, 24, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 24, 24, 24, 24, 24, 24, 24, 21, 18, 4, 12, 10, 10, 10, 10, 10, 18, 17, 5, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 17, 15, 4, 4, 11, 13, 10, 10, 14, 14, 18, 21, 24, 24, 24, 24, 24, 24, 24, 24, 21, 21, 21, 21, 21, 21, 21, 21, 24, 24, 24, 24, 24, 24, 24, 24, 21, 4, 4, 10, 13, 10, 13, 10, 14, 4, 17, 17, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 26, 17, 18, 4, 10, 10, 10, 13, 12, 11, 11, 18, 21, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 21, 18, 4, 4, 11, 13, 10, 10, 16, 10, 4, 21, 17, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 28, 17, 21, 18, 4, 14, 16, 10, 13, 10, 12, 11, 25, 18, 21, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 21, 21, 18, 4, 4, 10, 10, 16, 10, 10, 10, 18, 21, 17, 1, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 21, 18, 14, 14, 10, 10, 10, 10, 10, 10, 4, 18, 21, 21, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 21, 21, 18, 18, 18, 4, 11, 10, 10, 16, 16, 14, 14, 4, 21, 17, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 17, 17, 18, 4, 14, 14, 16, 16, 10, 16, 10, 4, 4, 4, 18, 18, 21, 21, 21, 21, 21, 21, 21, 18, 18, 18, 18, 4, 11, 11, 10, 10, 16, 16, 16, 10, 10, 4, 24, 17, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 17, 21, 4, 14, 10, 10, 16, 16, 16, 14, 10, 10, 11, 11, 11, 11, 4, 4, 4, 4, 4, 4, 4, 4, 10, 10, 10, 13, 10, 10, 10, 10, 10, 18, 18, 17, 5, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 17, 21, 18, 4, 4, 10, 10, 10, 10, 13, 10, 16, 16, 16, 16, 16, 16, 16, 16, 10, 10, 10, 10, 10, 10, 10, 10, 10, 12, 10, 4, 18, 24, 17, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 17, 26, 18, 18, 18, 11, 10, 10, 10, 10, 16, 13, 10, 13, 10, 10, 13, 10, 10, 10, 10, 10, 10, 10, 10, 11, 10, 4, 18, 21, 17, 17, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 17, 17, 18, 18, 4, 11, 10, 10, 10, 10, 13, 12, 13, 13, 13, 10, 10, 10, 10, 10, 10, 10, 4, 4, 18, 18, 17, 17, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 26, 26, 21, 29, 18, 18, 4, 4, 14, 14, 14, 14, 16, 16, 16, 14, 10, 4, 18, 18, 21, 21, 26, 17, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 17, 26, 24, 21, 21, 21, 18, 18, 18, 18, 18, 25, 18, 21, 21, 21, 21, 17, 17, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 5, 17, 17, 26, 24, 24, 24, 24, 24, 24, 26, 17, 17, 5, 5, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
		(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 23, 23, 23, 23, 23, 23, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
	);
	
	signal cor_indice : integer := 0;
	type cor_int is array(0 to 2) of integer range 0 to 255;
	type matriz_cores is array(0 to N_CORES-1) of cor_int;
	constant obj_cores: matriz_cores :=
	(
		(0, 187, 204), --0
		(27, 191, 208),
		(175, 202, 223),
		(53, 121, 173),
		(24, 100, 156),
		(47, 145, 170),
		(20, 116, 165),
		(52, 179, 203),
		(90, 149, 192),
		(85, 146, 190),
		(24, 105, 168),
		(24, 101, 159),
		(24, 103, 163),
		(24, 105, 167),
		(18, 105, 169),
		(18, 104, 150),
		(22, 105, 168),
		(19, 95, 131),
		(21, 89, 140),
		(23, 99, 156),
		(24, 100, 155),
		(23, 77, 117),
		(24, 106, 168),
		(92, 115, 133),
		(14, 57, 90),
		(21, 90, 142),
		(12, 74, 105),
		(23, 80, 122),
		(0, 187, 203),--28
		(23, 77, 118)
	);

	
	signal pix_x: unsigned(9 downto 0) := unsigned( pixel_x );
	signal pix_y: unsigned(9 downto 0) := unsigned( pixel_y );
	
	begin
		
		pix_x 	<= unsigned( pixel_x );
		pix_y 	<= unsigned( pixel_y );
		
		obj_Ymax <= obj_Ymin + LINHAS;
		obj_Xmax <= obj_Xmin + COLUNAS;
		
		forced_rst <= '1' when goal_tick = "10" else
						  '1'	when goal_tick = "01" else
						  '0';
		
		-- Atualizador de Registradores
		process( clk, reset, forced_rst, stop_game )
		begin
			if( reset = '1' or forced_rst = '1' or stop_game = '1' ) then
				obj_Ymin <= (480-LINHAS)/2;
				obj_Xmin <= 50;
				
			elsif( clk'event and clk='1' ) then
				obj_Ymin <= obj_Ymin_next;
				obj_Xmin <= obj_Xmin_next;
			end if;
		end process;
		
		process( pad0_Rx_EN , pad0_Rx, pad0_Ry_EN, pad0_Ry,
					obj_Ymin, obj_Xmin, refresh_tick_pad )
		begin
			obj_Ymin_next <= obj_Ymin;
			obj_Xmin_next <= obj_Xmin;
			
			if( refresh_tick_pad = '1' ) then
				if( pad0_Rx_EN = '1' ) then
					if(     pad0_Rx = '0' ) then
						if( obj_Xmin < frontier_Xmax ) then obj_Xmin_next <= obj_Xmin + 1;
						else											obj_Xmin_next <= frontier_Xmax;
						end if;
					else
						if( obj_Xmin > frontier_Xmin ) then obj_Xmin_next <= obj_Xmin - 1;
						else											obj_Xmin_next <= frontier_Xmin;
						end if;
					end if;
				end if;
			
				if( pad0_Ry_EN = '1' ) then
					if(     pad0_Ry = '1' ) then
						if( obj_Ymin < frontier_Ymax ) then obj_Ymin_next <= obj_Ymin + 1;
						else											obj_Ymin_next <= frontier_Ymax;
						end if;
					else
						if( obj_Ymin > frontier_Ymin ) then obj_Ymin_next <= obj_Ymin - 1;
						else											obj_Ymin_next <= frontier_Ymin;
						end if;
					end if;
				end if;
			end if;
			
		end process;

		--Verifica saída de video
		process( pix_x, pix_y, cor_indice ,
					obj_Xmin, obj_Xmax, obj_Ymin, obj_Ymax )
		begin
			obj_on		<= '0';
			obj_RGB(0)  <= "00000000";
			obj_RGB(1)  <= "00000000";
			obj_RGB(2)	<= "00000000";
			cor_indice	<= 0;
			
			if( (obj_Xmin <= pix_x) and (pix_x < obj_Xmax) and
				 (obj_Ymin <= pix_y) and (pix_y < obj_Ymax) ) then
				 
				cor_indice	<= obj_matriz( to_integer( pix_Y ) - obj_Ymin )
												 ( to_integer( pix_X ) - obj_Xmin );
													 
				case cor_indice is
					when 0  		=> obj_on <= '0';
					when 28 		=> obj_on <= '0';
					when others => obj_on <= '1';
				end case;
				
				obj_RGB(0) <= RGB_UNSIGNED( obj_cores(cor_indice)(0) );
				obj_RGB(1) <= RGB_UNSIGNED( obj_cores(cor_indice)(1) );
				obj_RGB(2) <= RGB_UNSIGNED( obj_cores(cor_indice)(2) );
				
			end if;
			
		end process;
		
		pad_Y <= std_logic_vector( to_unsigned( obj_Ymin , 10) );
		pad_X <= std_logic_vector( to_unsigned( obj_Xmin , 10) );
end arch;