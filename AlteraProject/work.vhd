library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TIPOS is
	
	type TYPE_COR is array(0 to 2) of unsigned(7 downto 0);
	
	function RGB_UNSIGNED(cor_int: integer) return unsigned;
	
	--- Funcoes para Facilitar texto bitmap
	function bit_addr_get(px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer)
	return std_logic_vector;
	
	function row_addr_get(px_Y: unsigned ; Ymin: integer ; Ymax: integer)
	return std_logic_vector;
	
	function switch_case( px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer )
	return integer;
	
	--Funcoes para img
	function img_row_index(px_Y: unsigned ; Ymin: integer ; Ymax: integer ; IMG_Linhas: integer)
	return integer;
	
	function img_color_index(px_X: unsigned ; Xmin: integer ; Xmax: integer ; IMG_Colunas: integer)
	return integer;
	
	--Funcao ajuste velocidade
	function ajuste_vel( puck_pos: integer ; pad_pos: integer ; pad_dim: integer )
	return integer;
end TIPOS;

package body TIPOS is
	
	function RGB_UNSIGNED(cor_int: integer) return unsigned is
	variable cor_unsigned : unsigned(7 downto 0);
	begin
		cor_unsigned := to_unsigned( cor_int , 8 );
		return cor_unsigned;
	end function;
	
	--- Funcoes para Facilitar texto bitmap
	function bit_addr_get(px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer)
		return std_logic_vector is
	begin
		return std_logic_vector( to_unsigned( (( (8*1000*Chars-1) / (Xmax - Xmin))*(to_integer( px_X ) - Xmin))/1000 , 3 ) );
	end bit_addr_get;
	
	function row_addr_get(px_Y: unsigned ; Ymin: integer ; Ymax: integer)
		return std_logic_vector is
	begin
		return std_logic_vector( to_unsigned( (( (16*1000) / (Ymax - Ymin))*(to_integer( px_Y ) - Ymin))/1000 , 4 ) );
	end row_addr_get;
	
	function switch_case( px_X: unsigned ; Xmin: integer ; Xmax: integer ; Chars: integer )
		return integer is
	begin
	return (( (Chars) *(to_integer( px_X ) - Xmin) )/(Xmax - Xmin ) );
	end switch_case;
	
	--Funcoes para img
	function img_row_index(px_Y: unsigned ; Ymin: integer ; Ymax: integer ; IMG_Linhas: integer)
		return integer is
		variable img_row : integer;
	begin
		img_row := ( ( IMG_Linhas * (to_integer( px_Y ) - Ymin) ) * 100 / (Ymax - Ymin) );
		return ( img_row / 100 );
	end img_row_index;
	
	function img_color_index(px_X: unsigned ; Xmin: integer ; Xmax: integer ; IMG_Colunas: integer)
		return integer is
		variable img_color : integer;
	begin
		img_color := ( ( IMG_Colunas * (to_integer( px_X ) - Xmin) ) * 100 / (Xmax - Xmin) );
		return ( img_color / 100 );
	end img_color_index;
	
	function ajuste_vel( puck_pos: integer ; pad_pos: integer ; pad_dim: integer )
		return integer is
		variable ajuste: integer;
	begin
		ajuste := 10*(puck_pos - (pad_pos + pad_dim/2));
		return (1 + ajuste/60);
	end ajuste_vel;
	
end package body;