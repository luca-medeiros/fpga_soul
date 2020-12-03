library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project is
	Port ( FPGA_RSTB : in STD_LOGIC;
		CLK : in STD_LOGIC;
		LCD_A : out STD_LOGIC_VECTOR (1 downto 0);
		LCD_EN : out STD_LOGIC;
		LCD_D : out STD_LOGIC_VECTOR (7 downto 0);
      DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
		SEG_A : out  STD_LOGIC;
      SEG_B : out  STD_LOGIC;
	   SEG_C : out  STD_LOGIC;
      SEG_D : out  STD_LOGIC;
      SEG_E : out  STD_LOGIC;
      SEG_F : out  STD_LOGIC;
      SEG_G : out  STD_LOGIC;
      SEG_DP : out  STD_LOGIC;
		left_1 : in STD_LOGIC;
		right_1 : in STD_LOGIC;
		updown_1 : in STD_LOGIC;
		left_2 : in STD_LOGIC;
		right_2 : in STD_LOGIC;
		updown_2 : in STD_LOGIC);
end project;

architecture Behavioral of project is
	component LCD_test
		port ( FPGA_RSTB : in std_logic;
			CLK : in std_logic;
			LCD_A : out std_logic_vector (1 downto 0);
			LCD_EN : out std_logic;
			LCD_D : out std_logic_vector (7 downto 0);
			data_out : in std_logic;
			addr : in std_logic_vector(4 downto 0);
			data : in std_logic_vector(7 downto 0);
			w_enable : out std_logic;
			stage: in std_logic_vector(1 downto 0));
	End component;

	component data_gen
		Port ( FPGA_RSTB : in STD_LOGIC;
			CLK : in STD_LOGIC;
			w_enable : in STD_LOGIC;
			data_out : out STD_LOGIC;
			addr : out STD_LOGIC_VECTOR (4 downto 0);
			data: out STD_LOGIC_VECTOR (7 downto 0);
			left_1: in std_logic;
			right_1: in std_logic;
			updown_1 : in std_logic;
			left_2 : in std_logic;
			right_2 : in std_logic;
			updown_2 : in std_logic;
			attack_1: out std_logic;
			attack_2: out std_logic;
			stage: out std_logic_vector(1 downto 0);
			reattack_1 : in std_logic;
			reattack_2 : in std_logic);
	end component;
	
	component digital_clock
		Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  attack_1:in std_logic;
			  attack_2:in std_logic;
           DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
           SEG_A : out  STD_LOGIC;
           SEG_B : out  STD_LOGIC;
           SEG_C : out  STD_LOGIC;
           SEG_D : out  STD_LOGIC;
           SEG_E : out  STD_LOGIC;
           SEG_F : out  STD_LOGIC;
           SEG_G : out  STD_LOGIC;
           SEG_DP : out  STD_LOGIC;
		   reattack_1 : inout std_logic;
			reattack_2 : inout std_logic);
	end component;
-- 내부신호 정의	
signal data_out_reg, w_enable_reg : std_logic; 
signal addr_reg : std_logic_vector(4 downto 0); 
signal data_reg : std_logic_vector(7 downto 0);
signal stage : std_logic_vector(1 downto 0);
signal reattack_1 , reattack_2 : std_logic;
signal attack_1 , attack_2 : std_logic;

	Begin
		lcd : LCD_test port map(FPGA_RSTB, CLK, LCD_A, LCD_EN, LCD_D,
				data_out_reg, addr_reg, data_reg, w_enable_reg,stage);
		data : data_gen port map(FPGA_RSTB, CLK, w_enable_reg, data_out_reg,
				addr_reg, data_reg,left_1,right_1,updown_1,left_2,right_2,updown_2,attack_1,attack_2,stage,reattack_1,reattack_2);
		clock : digital_clock port map(FPGA_RSTB,CLK,attack_1,attack_2,DIGIT,SEG_A,SEG_B,SEG_C,
				SEG_D,SEG_E,SEG_F,SEG_G,SEG_DP,reattack_1,reattack_2);
end Behavioral;

library IEEE; --LED 설정 및 초기화 부분
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LCD_test is
	port ( FPGA_RSTB : in std_logic;
		CLK : in std_logic;
		LCD_A : out std_logic_vector (1 downto 0);
		LCD_EN : out std_logic;
		LCD_D : out std_logic_vector (7 downto 0);
		data_out : in std_logic;
		addr : in std_logic_vector(4 downto 0);
		data : in std_logic_vector(7 downto 0);
		w_enable : out std_logic;
		attack_1 : in std_logic;
		attack_2 : in std_logic;
		stage: in std_logic_vector(1 downto 0));
end LCD_test;

architecture Behavioral of LCD_test is
--내부신호 정의
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 ); -- 2D array
signal reg_file : reg;
signal w_enable_reg : std_logic;
signal lcd_cnt : std_logic_vector (8 downto 0);
signal lcd_state : std_logic_vector (7 downto 0); --lcd_db를 받고, clock에 따라 이동
signal lcd_nstate : std_logic_vector (7 downto 0);-- lcd_state next state
signal lcd_db : std_logic_vector (7 downto 0);-- output을 전달하는 내부신호
signal stage_cnt: std_logic_vector(1 downto 0);
begin
	process(FPGA_RSTB, CLK) 
	--clock의 상승엣지에 따라 lcd_State가 다음상태로 넘아감
		Begin
			if FPGA_RSTB = '0' then
				lcd_state <= (others =>'0');
			elsif rising_edge (CLK) then
				lcd_state <= lcd_nstate;
			end if;
	end process;
--LCD 초기화 할시 enable_reg는 0, LCD에 출력하는지의 여부 판단
w_enable_reg <= '0' when lcd_state <= X"4E" else '1';

	process(FPGA_RSTB, CLK)
		Begin
			if FPGA_RSTB = '0' then -- reset = '0' 일??
				for i in 0 to 31 loop
					reg_file(i) <= X"20"; -- LED 초기화,X"20" 은 빈 공간 의미
				end loop;
			elsif CLK'event and CLK='1' then
			-- LED에 data 값에 따라 값이 표현
				if w_enable_reg ='1' and data_out ='1' then--LCD에 출력을 할때
					reg_file(conv_integer(addr)) <= data;--reg_file에 전달
				end if;
			end if;
	end process;
	
	process(FPGA_RSTB, lcd_state, stage) -- lcd_state (X00~X26)
		Begin
			if FPGA_RSTB='0' then
				lcd_nstate <= X"00";
				stage_cnt <= "00"; --stage 초기화
			else
				case lcd_state is
					when X"00" => lcd_db <= "00111000" ; -- Function set
						lcd_nstate <= X"01" ;
					when X"01" => lcd_db <= "00001000" ; -- Display OFF
						lcd_nstate <= X"02" ;
					when X"02" => lcd_db <= "00000001" ; -- Display clear
						lcd_nstate <= X"03" ;
					when X"03" => lcd_db <= "00000110" ; -- Entry mode set
						lcd_nstate <= X"04" ;
					when X"04" => lcd_db <= "00001100" ; -- Display ON
						lcd_nstate <= X"05" ;
					when X"05" => lcd_db <= "00000011" ; -- Return Home
						lcd_nstate <= X"06" ;
					when X"06" => lcd_db <= "01000000" ; --set CGRAM(X"00") player1
						lcd_nstate <= X"07";
						stage_cnt<= stage;--state 변화 감지
					when X"07" => lcd_db <= "00001110" ; --0***0
						lcd_nstate <= X"08";
					when X"08" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"09";
					when X"09" => lcd_db <= "00001110" ; --0***0
						lcd_nstate <= X"0A";
					when X"0A" => lcd_db <= "00010100" ; --*0*00
						lcd_nstate <= X"0B";
					when X"0B" => lcd_db <= "00011110" ; --****0
						lcd_nstate <= X"0C";
					when X"0C" => lcd_db <= "00011010" ; --**0*0
						lcd_nstate <= X"0D";
					when X"0D" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"0E";
					when X"0E" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"0F";
					when X"0F" => lcd_db <= "01001000" ; --set CGRAM(X"01") player2
						lcd_nstate <= X"10";
					when X"10" => lcd_db <= "00001110" ; --0***0
						lcd_nstate <= X"11";
					when X"11" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"12";
					when X"12" => lcd_db <= "00001110" ; --0***0
						lcd_nstate <= X"13";
					when X"13" => lcd_db <= "00000101" ; --00*0*
						lcd_nstate <= X"14";
					when X"14" => lcd_db <= "00001111" ; --0****
						lcd_nstate <= X"15";
					when X"15" => lcd_db <= "00001011" ; --0*0**
						lcd_nstate <= X"16";
					when X"16" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"17";
					when X"17" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"18";
					when X"18" => lcd_db <= "01010000" ;--set CGRAM(X"02") player1&2
						lcd_nstate <= X"19";
					when X"19" => lcd_db <= "00000100" ; --00*00
						lcd_nstate <= X"1A";
					when X"1A" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"1B";
					when X"1B" => lcd_db <= "00010101" ; --*0*0*
						lcd_nstate <= X"1C";
					when X"1C" => lcd_db <= "00010101" ; --*0*0*
						lcd_nstate <= X"1D";
					when X"1D" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"1E";
					when X"1E" => lcd_db <= "00000100" ; --00*00
						lcd_nstate <= X"1F";
					when X"1F" => lcd_db <= "00001010" ; --0*0*0
						lcd_nstate <= X"20";
					when X"20" => lcd_db <= "00010001" ; --*000*
						lcd_nstate <= X"21";
					when X"21" => lcd_db <= "01011000" ; --set CGRAM(X"03") monster stage=00,01,10> monster_1,2,3
						lcd_nstate <= X"22";
					when X"22" => lcd_nstate <= X"23";
						if (stage = "01")then
							lcd_db <= "00000000" ; --00000
						elsif(stage = "10")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "11")then
							lcd_db <= "00001110";--0***0
						end if;
					when X"23" => lcd_nstate <= X"24";
						if (stage = "01")then
							lcd_db <= "00001110" ; --0***0
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "11")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"24" => lcd_nstate <= X"25";
						if (stage = "01")then
							lcd_db <= "00001010" ; --0*0*0
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "11")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"25" => lcd_nstate <= X"26";
						if (stage = "01")then
							lcd_db <= "00001110" ; --0***0
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "11")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"26" => lcd_nstate <= X"27";
						if (stage = "01")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "10")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "11")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"27" => lcd_nstate <= X"28";
						if (stage = "01")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "10")then
							lcd_db <= "00001010"; --0*0*0
						elsif(stage = "11")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"28" => lcd_nstate <= X"29";
						if (stage = "01")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "10")then
							lcd_db <= "00001010"; --0*0*0
						elsif(stage = "11")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"29" => lcd_nstate <= X"2A";
						if (stage = "01")then
							lcd_db <= "00011111" ; --*****
						elsif(stage = "10")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "11")then
							lcd_db <= "00001010"; --0*0*0
						end if;
					when X"2A" => lcd_db <= "01100000" ; --set CGRAM(X"04") full 
						lcd_nstate <= X"2B";
					when X"2B" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"2C";
					when X"2C" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"2D";
					when X"2D" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"2E";
					when X"2E" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"2F";
					when X"2F" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"30";
					when X"30" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"31";
					when X"31" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"32";
					when X"32" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"33";
					when X"33" => lcd_db <= "01101000" ; --set CGRAM(X"05") 3/4
						lcd_nstate <= X"34";
					when X"34" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"35";
					when X"35" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"36";
					when X"36" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"37";
					when X"37" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"38";
					when X"38" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"39";
					when X"39" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"3A";
					when X"3A" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"3B";
					when X"3B" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"3C";
					when X"3C" => lcd_db <= "01110000" ; --set CGRAM(X"06")2/4
						lcd_nstate <= X"3D";
					when X"3D" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"3E";
					when X"3E" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"3F";
					when X"3F" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"40";
					when X"40" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"41";
					when X"41" => lcd_db <= "00001111" ; --*****
						lcd_nstate <= X"42";
					when X"42" => lcd_db <= "00001111" ; --*****
						lcd_nstate <= X"43";
					when X"43" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"44";
					when X"44" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"45";
					when X"45" => lcd_db <= "01111000" ; --set CGRAM(X"07") 1/4
						lcd_nstate <= X"46";
					when X"46" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"47";
					when X"47" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"48";
					when X"48" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"49";
					when X"49" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"4A";
					when X"4A" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"4B";
					when X"4B" => lcd_db <= "00000000" ; --00000
						lcd_nstate <= X"4C";
					when X"4C" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"4D";
					when X"4D" => lcd_db <= "00011111" ; --*****
						lcd_nstate <= X"4E";
					when X"4E" => lcd_db <= "00000011" ;--return home
						lcd_nstate <= X"4F" ;
					when X"4F" => lcd_db <= reg_file(0) ;
						lcd_nstate <= X"50" ;
					when X"50" => lcd_db <= reg_file(1) ;
						lcd_nstate <= X"51" ;
					when X"51" => lcd_db <= reg_file(2) ;
						lcd_nstate <= X"52" ;
					when X"52" => lcd_db <= reg_file(3) ;
						lcd_nstate <= X"53" ;
					when X"53" => lcd_db <= reg_file(4) ;
						lcd_nstate <= X"54" ;
					when X"54" => lcd_db <= reg_file(5) ;
						lcd_nstate <= X"55" ;
					when X"55" => lcd_db <= reg_file(6) ;
						lcd_nstate <= X"56" ;
					when X"56" => lcd_db <= reg_file(7) ;
						lcd_nstate <= X"57" ;
					when X"57" => lcd_db <= reg_file(8) ;
						lcd_nstate <= X"58" ;
					when X"58" => lcd_db <= reg_file(9) ;
						lcd_nstate <= X"59" ;	
					when X"59" => lcd_db <= reg_file(10) ;
						lcd_nstate <= X"5A" ;
					when X"5A" => lcd_db <= reg_file(11) ;
						lcd_nstate <= X"5B" ;
					when X"5B" => lcd_db <= reg_file(12) ;
						lcd_nstate <= X"5C" ;
					when X"5C" => lcd_db <= reg_file(13) ;
						lcd_nstate <= X"5D" ;
					when X"5D" => lcd_db <= reg_file(14) ;
						lcd_nstate <= X"5E" ;
					when X"5E" => lcd_db <= reg_file(15) ; 
						lcd_nstate <= X"5F" ;
					when X"5F" => lcd_db <= X"C0" ;-- Change Line
						Lcd_nstate <= X"60" ;
					when X"60" => lcd_db <= reg_file(16) ;
						lcd_nstate <= X"61" ;
					when X"61" => lcd_db <= reg_file(17) ;
						lcd_nstate <= X"62" ;
					when X"62" => lcd_db <= reg_file(18) ;
						lcd_nstate <= X"63" ;
					when X"63" => lcd_db <= reg_file(19) ;
						lcd_nstate <= X"64" ;
					when X"64" => lcd_db <= reg_file(20) ;
						lcd_nstate <= X"65" ;
					when X"65" => lcd_db <= reg_file(21) ;
						lcd_nstate <= X"66" ;
					when X"66" => lcd_db <= reg_file(22) ;
						lcd_nstate <= X"67" ;
					when X"67" => lcd_db <= reg_file(23) ;
						lcd_nstate <= X"68" ;
					when X"68" => lcd_db <= reg_file(24) ;
						lcd_nstate <= X"69" ;
					when X"69" => lcd_db <= reg_file(25) ;
						lcd_nstate <= X"6A" ;
					when X"6A" => lcd_db <= reg_file(26) ;
						lcd_nstate <= X"6B" ;
					when X"6B" => lcd_db <= reg_file(27) ;
						lcd_nstate <= X"6C" ;
					when X"6C" => lcd_db <= reg_file(28) ;
						lcd_nstate <= X"6D" ;
					when X"6D" => lcd_db <= reg_file(29) ;
						lcd_nstate <= X"6E" ;
					when X"6E" => lcd_db <= reg_file(30) ;
						lcd_nstate <=X"6F" ;
					when X"6F" => lcd_db <= reg_file(31);
						if (stage_cnt = stage) then 
							lcd_nstate <=X"4E"; --Return home(Stage가 같을때)
						else
							lcd_nstate <= X"06"; --Cgram set(stage가 변할때)
						end if;
					when others => lcd_db <= (others => '0') ;
				end case;
			end if;
	end process;
	
LCD_A(1) <= '1' when (X"07"<=lcd_state and lcd_state<=X"0E")or
		 (X"10"<=lcd_state and lcd_state<=X"17")or
		 (X"19"<=lcd_state and lcd_state<=X"20")or
		 (X"22"<=lcd_state and lcd_state<=X"29")or
		 (X"2B"<=lcd_state and lcd_state<=X"32")or
		 (X"34"<=lcd_state and lcd_state<=X"3B")or
		 (X"3D"<=lcd_state and lcd_state<=X"44")or
		 (X"46"<=lcd_state and lcd_state<=X"4D")
		 else '0';
LCD_A(0) <= '0' when lcd_state=X"5F" or lcd_state = X"4E" or lcd_state <= X"06" 
		or lcd_state=X"0F" or lcd_state=X"18" or lcd_state=X"21" or lcd_state=X"2A"
		or lcd_state=X"33" or lcd_state=X"3C" or lcd_state=X"45" or 
		(X"07"<=lcd_state and lcd_state<=X"0E")or
		 (X"10"<=lcd_state and lcd_state<=X"17")or
		 (X"19"<=lcd_state and lcd_state<=X"20")or
		 (X"22"<=lcd_state and lcd_state<=X"29")or
		 (X"2B"<=lcd_state and lcd_state<=X"32")or
		 (X"34"<=lcd_state and lcd_state<=X"3B")or
		 (X"3D"<=lcd_state and lcd_state<=X"44")or
		 (X"46"<=lcd_state and lcd_state<=X"4D")
		else '1';
		 
-- LCD_state 따른 LCD_A 구분
					
LCD_EN <= CLK; --LCD_EN <= '0' when w_enable_reg='0' else clk_100;
LCD_D <= lcd_db; -- LCD display data
w_enable <= w_enable_reg;
end Behavioral;



library IEEE; -- 입력값 생성 및 연산 부분
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity data_gen is
  		Port ( FPGA_RSTB : in STD_LOGIC;
			CLK : in STD_LOGIC;
			w_enable : in STD_LOGIC;
			data_out : out STD_LOGIC;
			addr : out STD_LOGIC_VECTOR (4 downto 0);
			data: out STD_LOGIC_VECTOR (7 downto 0);
			left_1: in std_logic;
			right_1: in std_logic;
			updown_1 : in std_logic;
			left_2 : in std_logic;
			right_2 : in std_logic;
			updown_2 : in std_logic;
			attack_1: out std_logic;
			attack_2: out std_logic;
		   stage: out std_logic_vector(1 downto 0);
		   reattack_1 : in std_logic;
			reattack_2 : in std_logic);
end data_gen;
architecture Behavioral of data_gen is
--내부신호 정의
	signal patern_clk : std_logic;
	signal random_count : std_logic_vector (6 downto 0);
	signal stage_data : std_logic_vector (1 downto 0);
	signal stage_data_saved : std_logic_vector (1 downto 0);
	signal pattern_num : std_logic_vector (1 downto 0);
	signal pattern_count : std_logic_vector (4 downto 0);
	signal cnt : std_logic_vector(4 downto 0);

	type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 ); -- 2D array
	signal reg_file : reg;
	signal clear_reg : reg;
	
	type pixel_data is array( 0 to 31 ) of std_logic; -- 2D array
	signal arrow_pixel : pixel_data;
	signal first_warning : pixel_data;
	signal second_warning : pixel_data;
	signal pixel_explosion : pixel_data;
	signal hit_on : pixel_data;

	signal Mhp : integer range 100 downto 0;
	signal Uhp : integer range 2 downto 0;
	
	signal p1_curSt : integer range 31 downto 0;
	signal p2_curSt : integer range 31 downto 0;
	signal p1_preSt : integer range 31 downto 0;
	signal p2_preSt : integer range 31 downto 0;
	signal action : std_logic;
	signal special : std_logic;
	
	signal game_over : std_logic;

	
begin
	--4HZ의 patern_clock구현, 0.25초에 해당
	process(FPGA_RSTB,clk)
	--4HZ를 구현하기위한 clk 변수 count_clk 선언
		variable patern_clk_cnt : integer range 0 to 500000;
	begin
		if(FPGA_RSTB = '0')then
			patern_clk <= '1';
			patern_clk_cnt := 0;
		elsif(clk'event and clk='1')then
		--0.125초 주기로 clk 값 변화, 500000 세고 0>1,1>0으로 바꿈
			if(patern_clk_cnt = 500000)then
				patern_clk_cnt := 0;
				patern_clk <= not patern_clk;
			else
			--500000보다 작으면 1씩 증가
				patern_clk_cnt := patern_clk_cnt +1;
			end if;
		end if;
	end process;	

	--game 내 player 이동 설정
	process(FPGA_RSTB, clk)
	begin
		-- 초기화
		if(FPGA_RSTB = '0') then	
			p1_curSt <= 0;
			p2_curSt <= 16;
			p1_preSt <= 1;
			p2_preSt <= 17;
			special <= '0';
		--player 이동 설정
		elsif(clk'event and clk = '1' and action = '1') then
			--player1 왼쪽 이동
			if (left_1 = '0') then
				--이동범위 넘어가면 이동 안함
				if( p1_curSt = 1 or p1_curSt = 16 ) then
					p1_curSt <= p1_curSt;
					p1_preSt <= p1_preSt;
				else 
					p1_preSt <= p1_curSt;
					p1_curSt <= p1_curSt - 1;
				end if;
			--player1 오른쪽 이동
			elsif (right_1 = '0') then
				--이동범위 넘어가면 이동 안함
				if( p1_curSt = 12 or p1_curSt = 29) then
					p1_curSt <= p1_curSt;
					p1_preSt <= p1_preSt;
				else
					p1_preSt <= p1_curSt;
					p1_curSt <= p1_curSt + 1;
				end if;	
			--player1 위아래 이동 (줄바꿈)
			elsif (updown_1 = '0') then
				if( p1_curSt = 29) then
					p1_curSt <= p1_curSt;
					p1_preSt <= p1_preSt;
				else
					if(p1_curSt >= 0 and p1_curSt <= 12) then
						p1_preSt <= p1_curSt;
						p1_curSt <= p1_curSt + 16;
					elsif(p1_curSt >= 16 and p1_curSt <= 28) then
						p1_preSt <= p1_curSt;
						p1_curSt <= p1_curSt - 16;
					end if;
				end if;
			end if;
			
			--player2 왼쪽 이동
			if (left_2 = '0') then
				--이동범위 넘어가면 이동 안함
				if( p2_curSt = 1 or p2_curSt = 16 ) then
					p2_curSt <= p2_curSt;
					p2_preSt <= p2_preSt;
				else 
					p2_preSt <= p2_curSt;
					p2_curSt <= p2_curSt - 1;
				end if;
			--player2 오른쪽 이동
			elsif (right_2 = '0') then
				--이동범위 넘어가면 이동 안함
				if( p2_curSt = 12 or p2_curSt = 29) then
					p2_curSt <= p2_curSt;
					p2_preSt <= p2_preSt;
				else
					p2_preSt <= p2_curSt;
					p2_curSt <= p2_curSt + 1;
				end if;	 
			
			--player2 위아래 이동 (줄바꿈)
			elsif (updown_2 = '0') then
				if( p2_curSt = 29) then
					p2_curSt <= p2_curSt;
					p2_preSt <= p2_preSt;
				else
					if(p2_curSt >= 0 and p2_curSt <= 12) then
						p2_preSt <= p2_curSt;
						p2_curSt <= p2_curSt + 16;
					elsif(p2_curSt >= 16 and p2_curSt <= 28) then
						p2_preSt <= p2_curSt;
						p2_curSt <= p2_curSt - 16;
					end if;
				end if;
			end if;
			
			--player1 위치와 player2 위치가 겹칠 경우
			if (p1_curSt = p2_curSt) then
				reg_file(p1_curSt) <= X"02";
				if (p1_curSt >= 10 and p1_curSt < 13) or (p1_curSt >= 26 and p1_curSt <= 29) then
					special <= '1';
				else
					special <= '0';
				end if;
			--player1 이전 위치보다 player2 현재 위치가 더 우위
			elsif (p2_curSt = p1_preSt) then
				special <= '0';
				reg_file(p2_curSt) <= X"01";
			--player2 이전 위치보다 player1 현재 위치가 더 우위
			elsif (p1_curSt = p2_preSt) then
				reg_file(p1_curSt) <= X"00";
				special <= '0';
			--player 위치 이동
			else
				special <= '0';
				reg_file(p1_curSt) <= X"00";
				reg_file(p2_curSt) <= X"01";
				reg_file(p1_preSt) <= X"20";
				reg_file(p2_preSt) <= X"20";
			end if;
		end if;
	end process;		
	
	
	--player 공격 및 피격
	process(FPGA_RSTB, clk)
	begin
		--초기화 시 player hp 2로 초기화
		if(FPGA_RSTB = '0') then
			Uhp <= 2;
		elsif (clk = '1' and clk'event and action = '1') then
			--둘이 합쳐서 공격할 때 유효한 경우
			if (special = '1') then
				if (right_1 = '0' or right_2 = '0') then
					Mhp <= Mhp - 1;
				end if;
			--나머지 경우 공격
			else
				if (reattack_1 = '1') then
					if (p1_curSt = 12) then
						if (right_1 = '0') then
							Mhp <= Mhp - 1;
						end if;
					elsif (p1_curSt = 29) then
						if (updown_1 = '0') then
							Mhp <= Mhp - 1;
						end if;
					end if;
				elsif (reattack_2 = '1') then
					if (p2_curSt = 12) then
						if (right_2 = '0') then
							Mhp <= Mhp - 1;
						end if;
					elsif (p2_curSt = 29) then
						if (updown_2 = '0') then
							Mhp <= Mhp - 1;
						end if;
					end if;
				end if;
			end if;
			
			--player가 공격을 맞았을 때
			if (hit_on(p1_curSt) = '1') or (hit_on(p2_curSt) = '1') then
				if (Uhp = 0) then
					game_over <= '1';
				else
					Uhp <= Uhp - 1;
				end if;
			end if;
			
		end if;
	end process;


	--매 pattern clock(0.25초)마다 action을 정의
	process(FPGA_RSTB,patern_clk)
		variable pattern_select : std_logic_vector (1 downto 0);
		variable random_fixed : std_logic;
	begin
		if(FPGA_RSTB = '0')then
			for i in 0 to 31 loop
				arrow_pixel(i) <= '0';
				pixel_explosion(i) <= '0';
				second_warning(i) <= '0';
				first_warning(i) <= '0';
			end loop;
			pattern_num <= "00";
			pattern_count <= "00000";
			stage_data_saved <= "00";

		elsif(clk'event and clk='1')then
			if (stage_data_saved /= stage_data) then
				--보스 변경됨 -> 대기패턴 강제 전환 및 1.75초 ~ 2.5초 대기
				pattern_num <= "00";
				pattern_count <= "00110" + ("000" & random_count(1 downto 0));
				stage_data_saved <= stage_data;
			end if;
			for i in 0 to 31 loop
				--화살 : 다음 패턴 클락에서 각 열의 마지막 칸-소멸, 그 외-한칸 좌측으로 이동.
				if (arrow_pixel(i) = '1') then
					arrow_pixel(i) <='0';
					if ((i /= 0) and (i /= 16)) then
						arrow_pixel(i - 1) <= '1';
					end if;
				end if;
				--픽셀 폭발 : 다음 패턴 클락에서 소멸
				if (pixel_explosion(i) = '1')then
					pixel_explosion(i) <= '0';
				end if;
				--경고_2 : 다음 패턴 클락에서 픽셀 폭발 유발	
				if (second_warning(i) = '1')then
					second_warning(i) <= '0';
					pixel_explosion(i) <= '1';
				end if;
				--경고_1 : 다음 패턴 클락에서 경고_2 유발(플레이어 눈에는 변화 없음.)
				if (first_warning(i) = '1')then
					first_warning(i) <= '0';
					second_warning(i) <= '1';
				end if;
			end loop;
			--보스 1 행동 정의
			if (stage_data = "01") then
				--대기 패턴
				if (pattern_num = "00") then
					--pattern_count가 0이 될 때 까지 1씩 감소시키며 대기
					if (pattern_count /= "00000") then
						pattern_count <= pattern_count - 1;
					--pattern_count가 0이 될 시 난수를 이용한 임의의 패턴 부여 (00 제외)
					else
						if (random_count (1 downto 0) = "00") then
							if (random_count (3 downto 2) = "00") then
								if (random_count (5 downto 4) = "00") then
									pattern_select := "01";
								else
									pattern_select := random_count (5 downto 4);
								end if;
							else
								pattern_select := random_count (3 downto 2);
							end if;
						else
							pattern_select := random_count (1 downto 0);
						end if;
						random_fixed := random_count(0);
						case pattern_select is
							when "01" =>
								pattern_num <= "01";
								pattern_count <= "10011";
							when "10" =>
								pattern_num <= "10";
								pattern_count <= "11001";
							when "11" =>
								pattern_num <= "11";
								pattern_count <= "11111";
							when others =>
								pattern_num <= "00";
								pattern_count <= "00001";
						end case;
					end if;
				--패턴 1 : 1줄 화살 x 3 -> 2줄 화살 x 3 -> 1줄 화살  x 3
				--      or 2줄 화살 x 3 -> 1줄 화살 x 3 -> 2줄 화살  x 3
				elsif (pattern_num = "01") then
					pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							when "10010" =>
								arrow_pixel(13) <= '1';
							when "10001" =>
								arrow_pixel(13) <= '1';
							when "10000" =>
								arrow_pixel(13) <= '1';
							when "01011" =>
								arrow_pixel(29) <= '1';
							when "01010" =>
								arrow_pixel(29) <= '1';
							when "01001" =>
								arrow_pixel(29) <= '1';
							when "00100" =>
								arrow_pixel(13) <= '1';
							when "00011" =>
								arrow_pixel(13) <= '1';
							when "00010" =>
								arrow_pixel(13) <= '1';
							--첫번째 패턴 종료. (0.5초 ~ 1.25초) 대기시간을 갖는 대기 패턴으로 넘어감
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					else
						case pattern_count is
							when "10010" =>
								arrow_pixel(29) <= '1';
							when "10001" =>
								arrow_pixel(29) <= '1';
							when "10000" =>
								arrow_pixel(29) <= '1';
							when "01011" =>
								arrow_pixel(13) <= '1';
							when "01010" =>
								arrow_pixel(13) <= '1';
							when "01001" =>
								arrow_pixel(13) <= '1';
							when "00100" =>
								arrow_pixel(29) <= '1';
							when "00011" =>
								arrow_pixel(29) <= '1';
							when "00010" =>
								arrow_pixel(29) <= '1';
							--첫번째 패턴 종료. (0.5초 ~ 1.25초) 대기시간을 갖는 대기 패턴으로 넘어감
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					end if;

				--패턴 2 : 상단 -> 4 패턴클락마다 상단 -> 화살 발사/ 하단 -> 전체공격 or 상단 -> 4패턴클락마다 전체공격 / 하단 -> 화살 발사 
				elsif (pattern_num = "10") then
					pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							when "11000" =>
								arrow_pixel(13) <= '1';
								first_warning(16) <= '1';
								first_warning(17) <= '1';
								first_warning(18) <= '1';
								first_warning(19) <= '1';
								first_warning(20) <= '1';
								first_warning(21) <= '1';
								first_warning(22) <= '1';
								first_warning(23) <= '1';
								first_warning(24) <= '1';
								first_warning(25) <= '1';
								first_warning(26) <= '1';
								first_warning(27) <= '1';
								first_warning(28) <= '1';
								first_warning(29) <= '1';
							when "10000" =>
								arrow_pixel(13) <= '1';
								first_warning(16) <= '1';
								first_warning(17) <= '1';
								first_warning(18) <= '1';
								first_warning(19) <= '1';
								first_warning(20) <= '1';
								first_warning(21) <= '1';
								first_warning(22) <= '1';
								first_warning(23) <= '1';
								first_warning(24) <= '1';
								first_warning(25) <= '1';
								first_warning(26) <= '1';
								first_warning(27) <= '1';
								first_warning(28) <= '1';
								first_warning(29) <= '1';
							when "01000" =>
								arrow_pixel(13) <= '1';
								first_warning(16) <= '1';
								first_warning(17) <= '1';
								first_warning(18) <= '1';
								first_warning(19) <= '1';
								first_warning(20) <= '1';
								first_warning(21) <= '1';
								first_warning(22) <= '1';
								first_warning(23) <= '1';
								first_warning(24) <= '1';
								first_warning(25) <= '1';
								first_warning(26) <= '1';
								first_warning(27) <= '1';
								first_warning(28) <= '1';
								first_warning(29) <= '1';
							--두번째 패턴 종료. (0.5초 ~ 1.25초) 대기시간을 갖는 대기 패턴으로 넘어감
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					else
						case pattern_count is
							when "11000" =>
								arrow_pixel(29) <= '1';
								first_warning(0) <= '1';
								first_warning(1) <= '1';
								first_warning(2) <= '1';
								first_warning(3) <= '1';
								first_warning(4) <= '1';
								first_warning(5) <= '1';
								first_warning(6) <= '1';
								first_warning(7) <= '1';
								first_warning(8) <= '1';
								first_warning(9) <= '1';
								first_warning(10) <= '1';
								first_warning(11) <= '1';
								first_warning(12) <= '1';
							when "10000" =>
								arrow_pixel(29) <= '1';
								first_warning(0) <= '1';
								first_warning(1) <= '1';
								first_warning(2) <= '1';
								first_warning(3) <= '1';
								first_warning(4) <= '1';
								first_warning(5) <= '1';
								first_warning(6) <= '1';
								first_warning(7) <= '1';
								first_warning(8) <= '1';
								first_warning(9) <= '1';
								first_warning(10) <= '1';
								first_warning(11) <= '1';
								first_warning(12) <= '1';
							when "01000" =>
								arrow_pixel(29) <= '1';
								first_warning(0) <= '1';
								first_warning(1) <= '1';
								first_warning(2) <= '1';
								first_warning(3) <= '1';
								first_warning(4) <= '1';
								first_warning(5) <= '1';
								first_warning(6) <= '1';
								first_warning(7) <= '1';
								first_warning(8) <= '1';
								first_warning(9) <= '1';
								first_warning(10) <= '1';
								first_warning(11) <= '1';
								first_warning(12) <= '1';
							--두번째 패턴 종료. (0.5초 ~ 1.25초) 대기시간을 갖는 대기 패턴으로 넘어감
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					end if;
				-- 패턴 3 : 2패턴 클락마다, 세로열 한줄 공격 및 전진. 8패턴 클락마다 반복하여 5회 진행
				elsif (pattern_num = "11") then
					pattern_count <= pattern_count - 1;
					case pattern_count is
						when "11110" =>
							first_warning(29) <= '1';
						when "11100" =>
							first_warning(12) <= '1';
							first_warning(28) <= '1';
						when "11010" =>
							first_warning(11) <= '1';
							first_warning(27) <= '1';
						when "11000" =>
							first_warning(10) <= '1';
							first_warning(26) <= '1';
						when "10110" =>
							first_warning(9) <= '1';
							first_warning(25) <= '1';
							first_warning(29) <= '1';
						when "10100" =>
							first_warning(8) <= '1';
							first_warning(24) <= '1';
							first_warning(12) <= '1';
							first_warning(28) <= '1';
						when "10010" =>
							first_warning(7) <= '1';
							first_warning(23) <= '1';
							first_warning(11) <= '1';
							first_warning(27) <= '1';	
						when "10000" =>
							first_warning(6) <= '1';
							first_warning(22) <= '1';
							first_warning(10) <= '1';
							first_warning(26) <= '1';
						when "01110" =>
							first_warning(5) <= '1';
							first_warning(21) <= '1';
							first_warning(9) <= '1';
							first_warning(25) <= '1';
							first_warning(29) <= '1';
						when "01100" =>
							first_warning(4) <= '1';
							first_warning(20) <= '1';
							first_warning(8) <= '1';
							first_warning(24) <= '1';
							first_warning(12) <= '1';
							first_warning(28) <= '1';
						when "01010" =>
							first_warning(3) <= '1';
							first_warning(19) <= '1';
							first_warning(7) <= '1';
							first_warning(23) <= '1';
							first_warning(11) <= '1';
							first_warning(27) <= '1';
						when "01000" =>
							first_warning(2) <= '1';
							first_warning(18) <= '1';
							first_warning(6) <= '1';
							first_warning(22) <= '1';
							first_warning(10) <= '1';
							first_warning(26) <= '1';	
						when "00100" =>
							first_warning(1) <= '1';
							first_warning(17) <= '1';
							first_warning(5) <= '1';
							first_warning(21) <= '1';
							first_warning(9) <= '1';
							first_warning(25) <= '1';
							first_warning(29) <= '1';
						when "00010" =>
							first_warning(0) <= '1';
							first_warning(16) <= '1';
							first_warning(4) <= '1';
							first_warning(20) <= '1';
							first_warning(8) <= '1';
							first_warning(24) <= '1';
							first_warning(12) <= '1';	
							first_warning(28) <= '1';							
						--세번째 패턴 종료. (1초 ~ 1.5초) 대기시간을 갖는 대기 패턴으로 넘어감
						when "00000" =>
							pattern_num <= "00";
							pattern_count <= "00100" + ("000" & random_count(1 downto 0));
						when others =>
							NULL;
					end case;
				end if;
-------------------------- stage 2 ----------------------------------
			--보스 2 행동 정의
			elsif (stage_data = "10") then
				if (pattern_num = "00") then
					--pattern_count가 0이 될 때 까지 1씩 감소시키며 대기
					if (pattern_count /= "00000") then
						pattern_count <= pattern_count - 1;
					--pattern_count가 0이 될 시 난수를 이용한 임의의 패턴 부여 (00 제외)
					else
						if (random_count (1 downto 0) = "00") then
							if (random_count (3 downto 2) = "00") then
								if (random_count (5 downto 4) = "00") then
									pattern_select := "01";
								else
									pattern_select := random_count (5 downto 4);
								end if;
							else
								pattern_select := random_count (3 downto 2);
							end if;
						else
							pattern_select := random_count (1 downto 0);
						end if;
						random_fixed := random_count(0);
						case pattern_select is
							when "01" =>
								pattern_num <= "01";
								pattern_count <= "10011";
							when "10" =>
								pattern_num <= "10";
								pattern_count <= "11001";
							when "11" =>
								pattern_num <= "11";
								pattern_count <= "11111";
							when others =>
								pattern_num <= "00";
								pattern_count <= "00001";
						end case;
					end if;
				--패턴 1-1 : |x|_|x|_|x|_|x|_|x|_|x|_|x|B|HP|HP|
				--			|_|x|_|x|_|x|_|x|_|x|_|x|_|x|HP|HP|
				elsif (pattern_num = "01") then
					pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							when "00100" | "00011"  =>
								first_warning(0) <= '1';
								first_warning(2) <= '1';
								first_warning(4) <= '1';
								first_warning(6) <= '1';
								first_warning(8) <= '1';
								first_warning(10) <= '1';
								first_warning(12) <= '1';
								first_warning(17) <= '1';
								first_warning(19) <= '1';
								first_warning(21) <= '1';
								first_warning(23) <= '1';
								first_warning(25) <= '1';
								first_warning(27) <= '1';
								first_warning(29) <= '1';
							-- Delay of 1s ~ 1.75s
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00100" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
						
				--패턴 1-2 : |_|x|_|x|_|x|_|x|_|x|_|x|_|B|HP|HP|
				--			  |x|_|x|_|x|_|x|_|x|_|x|_|x|_|HP|HP|
					else
						case pattern_count is
							when "11000" | "10000"  =>
								first_warning(1) <= '1';
								first_warning(3) <= '1';
								first_warning(5) <= '1';
								first_warning(7) <= '1';
								first_warning(9) <= '1';
								first_warning(11) <= '1';
								first_warning(13) <= '1';
								first_warning(16) <= '1';
								first_warning(18) <= '1';
								first_warning(20) <= '1';
								first_warning(22) <= '1';
								first_warning(24) <= '1';
								first_warning(26) <= '1';
								first_warning(28) <= '1';
							-- Delay of 1s ~ 1.75s
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00100" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					end if;
					
				-- 패턴 2 sine wave        |_|_|x|_|_|_|x|_|_|_|x|_|<|B|HP|HP|
				-- with arrow top/bot    |x|_|_|_|x|_|_|_|x|_|_|_|x|<|HP|HP|
				elsif (pattern_num = "10") then
					pattern_count <= pattern_count - 1;
					case pattern_count is
						when "11110" =>
							arrow_pixel(12) <= '1';
							first_warning(2) <= '1';
							first_warning(6) <= '1';
							first_warning(10) <= '1';
							first_warning(16) <= '1';
							first_warning(20) <= '1';
							first_warning(24) <= '1';
							first_warning(28) <= '1';
						when "11001" =>
							arrow_pixel(29) <= '1';
							first_warning(2) <= '1';
							first_warning(6) <= '1';
							first_warning(10) <= '1';
							first_warning(16) <= '1';
							first_warning(20) <= '1';
							first_warning(24) <= '1';
							first_warning(28) <= '1';
						when "11101" | "11100" | "11011" | "11010" |
							  "11000" | "10111" | "10110" | "10101" =>
							first_warning(2) <= '1';
							first_warning(6) <= '1';
							first_warning(10) <= '1';
							first_warning(16) <= '1';
							first_warning(20) <= '1';
							first_warning(24) <= '1';
							first_warning(28) <= '1';
							
						-- Delay of 1s ~ 1.75s
						when "00000" =>
							pattern_num <= "00";
							pattern_count <= "00100" + ("000" & random_count(1 downto 0));
						when others =>
							NULL;
					end case;
					
				-- **** needs to add one last pattern
				elsif (pattern_num = "10") then
					pattern_count <= pattern_count - 1;
					case pattern_count is
						when others =>
							NULL;
					end case;
				end if;
--------------- STAGE 3 ----------------------------
			-- boss 3
			elsif (stage_data = "11") then
				NULL;
			end if;
		end if;
	end process;

	--stage data 전달
	stage <= stage_data;
	--FPGA clock마다 작동하는 실시간 action. 피격 판정 등 유저 행동에 따른 code는 여기 작성 바람
	process(FPGA_RSTB,clk)
	begin
		if(FPGA_RSTB = '0')then
			for i in 0 to 31 loop
				hit_on(i) <= '0';
				reg_file(i) <= X"20";
			end loop;
			random_count <= "0000000";
			stage_data  <= "00";
			game_over <= '0';
			action <= '0';
		elsif(clk'event and clk='1')then
			-- 7bit 난수 random_count 생성
			random_count <= random_count + 1;
			if (random_count = "1111111") then
				random_count <= "0000000";
			end if;
			--시작 대기 중 일때
			if (stage_data = "00") then
				--   FPGA  SOUL
				-- PUSH ANY BUTTON
				reg_file(0) <= X"20";
				reg_file(1) <= X"20";
				reg_file(2) <= X"20";
				reg_file(3) <= X"46";
				reg_file(4) <= X"50";
				reg_file(5) <= X"47";
				reg_file(6) <= X"41";
				reg_file(7) <= X"20";
				reg_file(8) <= X"20";
				reg_file(9) <= X"53";
				reg_file(10) <= X"4F";
				reg_file(11) <= X"55";
				reg_file(12) <= X"4C";
				reg_file(13) <= X"20";
				reg_file(14) <= X"20";
				reg_file(15) <= X"20";
				reg_file(16) <= X"20";
				reg_file(17) <= X"50";
				reg_file(18) <= X"55";
				reg_file(19) <= X"53";
				reg_file(20) <= X"48";
				reg_file(21) <= X"20";
				reg_file(22) <= X"41";
				reg_file(23) <= X"4E";
				reg_file(24) <= X"59";
				reg_file(25) <= X"20";
				reg_file(26) <= X"42";
				reg_file(27) <= X"55";
				reg_file(28) <= X"54";
				reg_file(29) <= X"54";
				reg_file(30) <= X"4F";
				reg_file(31) <= X"4E";
				--어떤 버튼이라도 눌리면 : 첫 보스 시작
				if ((left_1 = '0') or (left_2 = '0') or (right_1 = '0') or (right_2 = '0') or (updown_1 = '0') or (updown_2 = '0')) then
					reg_file <= clear_reg; -- Clear LCD Screen
					stage_data <= "01";
					action <= '1';
				end if;
			else
				for i in 0 to 31 loop
					-- 보스 위치/플레이어 체력 표시 위치/보스 체력 표시 위치를 제외한 전 픽셀에서
					if ((i /= 13) or (i /= 14) or (i /= 15) or (i /= 30) or (i /= 31)) then
						-- 피격 판정 초기화
						hit_on(i) <= '0';
						
						--그 칸에 화살이 있으면 : "<"  & 피격판정 ON
						if (arrow_pixel(i) = '1') then
							hit_on(i) <= '1';
							reg_file(i) <= X"3C";
						-- 화살이 없으면서/픽셀 폭발 효과가 있으면 : "까만 네모" & 피격판정 ON
						elsif (pixel_explosion(i) = '1') then
							hit_on(i) <= '1';
							reg_file(i) <= X"FF";
						-- 화살/픽셀 폭발 효과가 없으면서 경고 효과 존재 : "!"
						elsif ((first_warning(i) = '1') or (second_warning(i) = '1')) then
							reg_file(i) <= X"21";
						end if;
					else
					end if;
					
				end loop;
			end if;
			
			
			
		end if;
		
	end process;

process(FPGA_RSTB, clk)
	Begin
		if FPGA_RSTB ='0' then
			cnt <= (others => '0');
			data_out <= '0';
		elsif clk='1' and clk'event then
			if w_enable = '1' then
				data <= reg_file (conv_integer(cnt));
				addr <= cnt;
				data_out <= '1';
				if cnt= X"1F" then
					cnt <= (others =>'0');
				else
					cnt <= cnt + 1;
				end if;
			else
				data_out <= '0';
			end if;
		end if;
end process;


end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity digital_clock is
    Port ( FPGA_RSTB: in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  attack_1: in std_logic;--공격이 들어오면1
			  attack_2: in std_logic;
           DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
           SEG_A : out  STD_LOGIC;
           SEG_B : out  STD_LOGIC;
           SEG_C : out  STD_LOGIC;
           SEG_D : out  STD_LOGIC;
           SEG_E : out  STD_LOGIC;
           SEG_F : out  STD_LOGIC;
           SEG_G : out  STD_LOGIC;
           SEG_DP : out  STD_LOGIC;
		   reattack_1 : inout std_logic;
			reattack_2 : inout std_logic);
end digital_clock;

architecture Behavioral of digital_clock is
--내부신호
signal s01_clk:std_logic;--1Hz에 맞는 clk 변수
--s01_clk에 맞게 count되는 시간 변수
signal cool1:std_logic_vector(3 downto 0);
signal cool2:std_logic_vector(3 downto 0);
signal min10_cnt,min01_cnt:std_logic_vector(3 downto 0);
signal sec10_cnt,sec01_cnt:std_logic_vector(3 downto 0);
signal sel:std_logic_vector(2 downto 0);
signal data:std_logic_vector(3 downto 0);
signal seg: std_logic_vector(7 downto 0);
signal cool_cnt1: std_logic_vector(3 downto 0);
signal cool_cnt2: std_logic_vector(3 downto 0);

begin
	process(sel)
	begin
		case sel is
		--분의 10의자리
			when "000"=> DIGIT<="000001";
								data<=min10_cnt;
		--분의 1의 자리
			when "001"=> DIGIT<="000010";
								data<=min01_cnt;
		--초의 10의 자리
			when "010"=> DIGIT<="000100";
								data<=sec10_cnt;
		--초의 1의 자리
			when "011"=> DIGIT<="001000";
								data<=sec01_cnt;
		--cool time의 자리(1p)
			when "100"=> DIGIT<="010000";
								data<=cool1;
		--cool time의 자리 (2p)
			when "101"=> DIGIT<="100000";
								data<=cool2;
			when others => null;
		end case;
	end process;
	
	--빠른 seg_clk에 따라 digit을 바꾸면서 결과도출, 육안으론 연속을 보임
	process(FPGA_RSTB,clk)
	--4MHZ>20kHZ을 위한 새로운 clk 변수 선언
	variable seg_clk_cnt:integer range 0 to 200;
	begin
		if(FPGA_RSTB='0')then
			sel<="000";
			seg_clk_cnt:=0;
		elsif(clk'event and clk='1')then
		--200이 되면 0으로 다시 초기화
			if(seg_clk_cnt=200)then
				seg_clk_cnt:=0;
				--200이 아니면 시>분>초 로 자리 옮김
				if(sel="101")then
					sel<="000";
				else
					sel<= sel+1;
				end if;
			else
			--200이 아니면 clk 변수 +1
				seg_clk_cnt:=seg_clk_cnt+1;
			end if;
		end if;
	end process;
	
	process(data)
	begin
	--segment display를 위한 array 설정
		case data is
			when "0000"=>seg<="00111111";--data displayed:0
			when "0001"=>seg<="00000110";--data displayed:1
			when "0010"=>seg<="01011011";--data displayed:2
			when "0011"=>seg<="01001111";--data displayed:3
			when "0100"=>seg<="01100110";--data displayed:4
			when "0101"=>seg<="01101101";--data displayed:5
			when "0110"=>seg<="01111101";--data displayed:6
			when "0111"=>seg<="00000111";--data displayed:7
			when "1000"=>seg<="01111111";--data displayed:8
			when "1001"=>seg<="01101111";--data displayed:9
			when "1010"=>seg<="01011111";--data displayed:A
			when "1011"=>seg<="01111100";--data displayed:B
			when "1100"=>seg<="00111001";--data displayed:C
			when "1101"=>seg<="01011110";--data displayed:D
			when "1110"=>seg<="01111001";--data displayed:E
			when others =>seg<="01110001";--data displayed:F
		end case;
	end process;
	
	SEG_A<=seg(0);
	SEG_B<=seg(1);
	SEG_C<=seg(2);
	SEG_D<=seg(3);
	SEG_E<=seg(4);
	SEG_F<=seg(5);
	SEG_G<=seg(6);
	SEG_DP<=seg(7);
	
	--1HZ의 clock(s01_clk)구현, 1초에 해당
	process(FPGA_RSTB,clk)
	--1HZ를 구현하기위한 clk 변수 count_clk 선언
	variable count_clk:integer range 0 to 2000000;
	begin
		if(FPGA_RSTB='0')then
			s01_clk<='1';
			count_clk:=0;
		elsif(clk'event and clk='1')then
		--0.5초 주기의 clk으로 clk 값 변화, 2000000 세고 0>1,1>0으로 바꿈
			if(count_clk=2000000)then
				count_clk:=0;
				s01_clk<=not s01_clk;
			else
			--2000000을 안세면 1씩 올림
				count_clk:=count_clk+1;
				s01_clk<=s01_clk;
			end if;
		end if;
	end process;
	
	process(s01_clk,FPGA_RSTB,attack_1)--공격했을때 쿨타임
	begin
		if (FPGA_RSTB='0')then
			cool_cnt1<="0011";
		elsif(attack_1='0' and cool_cnt2 = "0000" and reattack_1 = '0')then
			cool_cnt1<="0011";
			reattack_1 <= '1';
		elsif(s01_clk = '1' and s01_clk'event)then
			if (cool_cnt1 > "0000")then
				cool_cnt1<=cool_cnt1-1;
			else cool_cnt1 <= "0000"; reattack_1<='0';
			end if;
		end if;
		
	cool1<=cool_cnt1;
	end process;
		
	process(s01_clk,FPGA_RSTB,attack_2)--공격했을때 쿨타임
	begin
		if (FPGA_RSTB='0')then
			cool_cnt2<="0011";
		elsif(attack_2='0' and cool_cnt2 = "0000" and reattack_2 = '0')then
			cool_cnt2<="0011";
			reattack_2<='1';
		elsif(s01_clk = '1' and s01_clk'event)then
			if (cool_cnt2 > "0000")then
				cool_cnt2<=cool_cnt2-1;
			else cool_cnt2 <= "0000";reattack_2<='0';
			end if;
		end if;
		
	cool2<=cool_cnt2;
	end process;
	
	process(s01_clk,FPGA_RSTB)
	variable m10_cnt,m01_cnt:std_logic_vector(3 downto 0);
	variable s10_cnt,s01_cnt:std_logic_vector(3 downto 0);
	begin
		if(FPGA_RSTB='0')then
			--LED에 00:00:00표시
			m10_cnt:="0000";
			m01_cnt:="0000";
			s10_cnt:="0000";
			s01_cnt:="0000";
		elsif(s01_clk='1' and s01_clk'event)then
		--1Hz clock이 rising이면 1초 증가
		s01_cnt:=s01_cnt+1;
			if(s01_cnt>"1001")then
			--초의 1의자리수가10이되면 초의10의자리수 증가
				s01_cnt:="0000";
				s10_cnt:=s10_cnt+1;
			end if;
			if(s10_cnt>"0101")then
			--초의 10의자리수가6이되면 분의1의 자리수 증가
				s10_cnt:="0000";
				m01_cnt:=m01_cnt+1;
			end if;
			if(m01_cnt>"1001")then
			--분의 1의자리수가10이되면 분의10의 자리수 증가
				m01_cnt:="0000";
				m10_cnt:=m10_cnt+1;
			end if;
			if(m10_cnt>"0101")then
			--분의 10의자리수가6이되면 시간의1의 자리수 증가
				m10_cnt:="0000";
				m01_cnt:="0000";
				s10_cnt:="0000";
				s01_cnt:="0000";
			end if;
		end if;
	--계산된 시간값을 매칭
	sec01_cnt<=s01_cnt;
	sec10_cnt<=s10_cnt;
	min01_cnt<=m01_cnt;
	min10_cnt<=m10_cnt;
	end process;
	
end Behavioral;
