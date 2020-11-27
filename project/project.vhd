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
		updown_2 : in STD_LOGIC_VECTOR (3 downto 0));
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
			attack_1: in std_logic;
			attack_2: in std_logic;
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
			stage: out std_logic_vector(1 downto 0));
	end component;
	
	component digital_clock
		Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  attack:in std_logic;
           DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
           SEG_A : out  STD_LOGIC;
           SEG_B : out  STD_LOGIC;
           SEG_C : out  STD_LOGIC;
           SEG_D : out  STD_LOGIC;
           SEG_E : out  STD_LOGIC;
           SEG_F : out  STD_LOGIC;
           SEG_G : out  STD_LOGIC;
           SEG_DP : out  STD_LOGIC);
	end component;
-- ���ν�ȣ ����	
signal data_out_reg, w_enable_reg : std_logic; 
signal addr_reg : std_logic_vector(4 downto 0); 
signal data_reg : std_logic_vector(7 downto 0); 
	Begin
		lcd : LCD_test port map(FPGA_RSTB, CLK, LCD_A, LCD_EN, LCD_D,
				data_out_reg, addr_reg, data_reg, w_enable_reg,attack_1,attack_2);
		data : data_gen port map(FPGA_RSTB, CLK, w_enable_reg, data_out_reg,
				addr_reg, data_reg,left_1,right_1,updwon_1,left_2,right_2,updown_2,attack_1,attack_2);
		clock : digital_clock port map(FPGA_RSTB,clk,attack,DIGIT,SEG_A,SEG_B,SEG_C,
				SEG_D,SEG_E,SEG_F,SEG_G,SEG_DP);
end Behavioral;

library IEEE; --LED ���� �� �ʱ�ȭ �κ�
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
--���ν�ȣ ����
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 ); -- 2D array
signal reg_file : reg;
signal w_enable_reg : std_logic;
signal lcd_cnt : std_logic_vector (8 downto 0);
signal lcd_state : std_logic_vector (7 downto 0); --lcd_db�� �ް�, clock�� ���� �̵�
signal lcd_nstate : std_logic_vector (7 downto 0);-- lcd_state next state
signal lcd_db : std_logic_vector (7 downto 0);-- output�� �����ϴ� ���ν�ȣ
signal stage_cnt: std_logic_vector(1 downto 0);
begin
	process(FPGA_RSTB, CLK) 
	--clock�� ��¿����� ���� lcd_State�� �������·� �Ѿư�
		Begin
			if FPGA_RSTB = '0' then
				lcd_state <= (others =>'0');
			elsif rising_edge (CLK) then
				lcd_state <= lcd_nstate;
			end if;
	end process;
--LCD �ʱ�ȭ �ҽ� enable_reg�� 0, LCD�� ����ϴ����� ���� �Ǵ�
w_enable_reg <= '0' when lcd_state <= X"4E" else '1';

	process(FPGA_RSTB, CLK)
		Begin
			if FPGA_RSTB = '0' then -- reset = '0' �ϋ�
				for i in 0 to 31 loop
					reg_file(i) <= X"20"; -- LED �ʱ�ȭ,X"20" �� �� ���� �ǹ�
				end loop;
			elsif CLK'event and CLK='1' then
			-- LED�� data ���� ���� ���� ǥ��
				if w_enable_reg ='1' and data_out ='1' then--LCD�� ����� �Ҷ�
					reg_file(conv_integer(addr)) <= data;--reg_file�� ����
				end if;
			end if;
	end process;
	
	process(FPGA_RSTB, lcd_state, stage) -- lcd_state (X00~X26)
		Begin
			if FPGA_RSTB='0' then
				lcd_nstate <= X"00";
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
						stage_cnt<= stage;--state ��ȭ ����
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
						if (stage = "00")then
							lcd_db <= "00000000" ; --00000
						elsif(stage = "01")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "10")then
							lcd_db <= "00001110";--0***0
						end if;
					when X"23" => lcd_nstate <= X"24";
						if (stage = "00")then
							lcd_db <= "00001110" ; --0***0
						elsif(stage = "01")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"24" => lcd_nstate <= X"25";
						if (stage = "00")then
							lcd_db <= "00001010" ; --0*0*0
						elsif(stage = "01")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "10")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"25" => lcd_nstate <= X"26";
						if (stage = "00")then
							lcd_db <= "00001110" ; --0***0
						elsif(stage = "01")then
							lcd_db <= "00010001"; --*000*
						elsif(stage = "10")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"26" => lcd_nstate <= X"27";
						if (stage = "00")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "01")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"27" => lcd_nstate <= X"28";
						if (stage = "00")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "01")then
							lcd_db <= "00001010"; --0*0*0
						elsif(stage = "10")then
							lcd_db <= "00010001"; --*000*
						end if;
					when X"28" => lcd_nstate <= X"29";
						if (stage = "00")then
							lcd_db <= "00000100" ; --00*00
						elsif(stage = "01")then
							lcd_db <= "00001010"; --0*0*0
						elsif(stage = "10")then
							lcd_db <= "00010101"; --*0*0*
						end if;
					when X"29" => lcd_nstate <= X"2A";
						if (stage = "00")then
							lcd_db <= "00011111" ; --*****
						elsif(stage = "01")then
							lcd_db <= "00011111"; --*****
						elsif(stage = "10")then
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
							lcd_nstate <=X"4E"; --Return home(Stage�� ������)
						else
							lcd_nstate <= X"06"; --Cgram set(stage�� ���Ҷ�)
						end if;
					when others => lcd_db <= (others => '0') ;
				end case;
			end if;
	end process;
	
LCD_A <= "00" when(lcd_state=X"5F" or lcd_state = X"4E" or lcd_state <= X"06" 
	 or lcd_state=X"0F" or lcd_state=X"18" or lcd_state=X"21" or lcd_state=X"2A"
	 or lcd_state=X"33" or lcd_state=X"3C" or lcd_state=X"45");
LCD_A <= "01" when ((X"07"<=lcd_state and lcd_state<=X"0E")or
		 (X"10"<=lcd_state and lcd_state<=X"17")or
		 (X"19"<=lcd_state and lcd_state<=X"20")or
		 (X"22"<=lcd_state and lcd_state<=X"29")or
		 (X"2B"<=lcd_state and lcd_state<=X"32")or
		 (X"34"<=lcd_state and lcd_state<=X"3B")or
		 (X"3D"<=lcd_state and lcd_state<=X"44")or
		 (X"46"<=lcd_state and lcd_state<=X"4D"));
LCD_A <= "10" when ((X"4F"<=lcd_state and lcd_state<=X"5E")or
		 (X"60"<=lcd_state and lcd_state<=X"6F")or (lcd_state > X"6F"));
		 
-- LCD_state ���� LCD_A ����
					
LCD_EN <= CLK; --LCD_EN <= '0' when w_enable_reg='0' else clk_100;
LCD_D <= lcd_db; -- LCD display data
w_enable <= w_enable_reg;
end Behavioral;



library IEEE; -- �Է°� ���� �� ���� �κ�
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
			attack_2: out std_logic);
end data_gen;
architecture Behavioral of data_gen is
--���ν�ȣ ����
begin









end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity digital_clock is
    Port ( FPGA_RSTB: in  STD_LOGIC;
           CLK : in  STD_LOGIC;
			  attack_1: in std_logic;--������ ������1
			  attack_2: in std_logic;
           DIGIT : out  STD_LOGIC_VECTOR (6 downto 1);
           SEG_A : out  STD_LOGIC;
           SEG_B : out  STD_LOGIC;
           SEG_C : out  STD_LOGIC;
           SEG_D : out  STD_LOGIC;
           SEG_E : out  STD_LOGIC;
           SEG_F : out  STD_LOGIC;
           SEG_G : out  STD_LOGIC;
           SEG_DP : out  STD_LOGIC);
end digital_clock;

architecture Behavioral of digital_clock is
--���ν�ȣ
signal s01_clk:std_logic;--1Hz�� �´� clk ����
--s01_clk�� �°� count�Ǵ� �ð� ����
signal cool:std_logic_vector(3 downto 0);
signal min10_cnt,min01_cnt:std_logic_vector(3 downto 0);
signal sec10_cnt,sec01_cnt:std_logic_vector(3 downto 0);
signal sel:std_logic_vector(2 downto 0);
signal data:std_logic_vector(3 downto 0);
signal seg: std_logic_vector(7 downto 0);

begin
	process(sel)
	begin
		case sel is
		--���� 10���ڸ�
			when "000"=> DIGIT<="000001";
								data<=min10_cnt;
		--���� 1�� �ڸ�
			when "001"=> DIGIT<="000010";
								data<=min01_cnt;
		--���� 10�� �ڸ�
			when "010"=> DIGIT<="000100";
								data<=sec10_cnt;
		--���� 1�� �ڸ�
			when "011"=> DIGIT<="001000";
								data<=sec01_cnt;
		--cool time�� �ڸ�(1p)
			when "100"=> DIGIT<="010000";
								data<=cool1;
		--cool time�� �ڸ� (2p)
			when "101"=> DIGIT<="100000";
								data<=cool2;
			when others => null;
		end case;
	end process;
	
	--���� seg_clk�� ���� digit�� �ٲٸ鼭 �������, �������� ������ ����
	process(FPGA_RSTB,clk)
	--4MHZ>20kHZ�� ���� ���ο� clk ���� ����
	variable seg_clk_cnt:integer range 0 to 200;
	begin
		if(FPGA_RSTB='0')then
			sel<="000";
			seg_clk_cnt:=0;
		elsif(clk'event and clk='1')then
		--200�� �Ǹ� 0���� �ٽ� �ʱ�ȭ
			if(seg_clk_cnt=200)then
				seg_clk_cnt:=0;
				--200�� �ƴϸ� ��>��>�� �� �ڸ� �ű�
				if(sel="101")then
					sel<="000";
				else
					sel<= sel+1;
				end if;
			else
			--200�� �ƴϸ� clk ���� +1
				seg_clk_cnt:=seg_clk_cnt+1;
			end if;
		end if;
	end process;
	
	process(data)
	begin
	--segment display�� ���� array ����
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
	
	--1HZ�� clock(s01_clk)����, 1�ʿ� �ش�
	process(FPGA_RSTB,clk)
	--1HZ�� �����ϱ����� clk ���� count_clk ����
	variable count_clk:integer range 0 to 2000000;
	begin
		if(FPGA_RSTB='0')then
			s01_clk<='1';
			count_clk:=0;
		elsif(clk'event and clk='1')then
		--0.5�� �ֱ��� clk���� clk �� ��ȭ, 2000000 ���� 0>1,1>0���� �ٲ�
			if(count_clk=2000000)then
				count_clk:=0;
				s01_clk<=not s01_clk;
			else
			--2000000�� �ȼ��� 1�� �ø�
				count_clk:=count_clk+1;
				s01_clk<=s01_clk;
			end if;
		end if;
	end process;
	
	process(s01_clk,FPGA_RSTB,attack_1)--���������� ��Ÿ��
	variable cool_cnt1: std_logic_vector(3 downto 0);
	begin
		if (FPGA_RSTB='0')then
			cool_cnt1:="0011";
		elsif(attack_1='0' and cool_cnt2 = "0000")then
			cool_cnt1:="0011";
		elsif(s01_cnt = '1' and s01_clk'event)then
			if (cool_cnt1 > "0000")then
				cool_cnt1:=cool_cnt1-1;
			else cool_cnt1 := "0000";
			end if;
		end if;
		
	cool1<=cool_cnt1;
	end process;
		
	process(s01_clk,FPGA_RSTB,attack_2)--���������� ��Ÿ��
	variable cool_cnt2: std_logic_vector(3 downto 0);
	begin
		if (FPGA_RSTB='0')then
			cool_cnt2:="0011";
		elsif(attack_2='0' and cool_cnt2 = "0000")then
			cool_cnt2:="0011";
		elsif(s01_cnt = '1' and s01_clk'event)then
			if (cool_cnt2 > "0000")then
				cool_cnt2:=cool_cnt2-1;
			else cool_cnt2 := "0000";
			end if;
		end if;
		
	cool2<=cool_cnt2;
	end process;
	
	process(s01_clk,FPGA_RSTB)
	variable m10_cnt,m01_cnt:std_logic_vector(3 downto 0);
	variable s10_cnt,s01_cnt:std_logic_vector(3 downto 0);
	begin
		if(FPGA_RSTB='0')then
			--LED�� 00:00:00ǥ��
			m10_cnt:="0000";
			m01_cnt:="0000";
			s10_cnt:="0000";
			s01_cnt:="0000";
		elsif(s01_clk='1' and s01_clk'event)then
		--1Hz clock�� rising�̸� 1�� ����
		s01_cnt:=s01_cnt+1;
			if(s01_cnt>"1001")then
			--���� 1���ڸ�����10�̵Ǹ� ����10���ڸ��� ����
				s01_cnt:="0000";
				s10_cnt:=s10_cnt+1;
			end if;
			if(s10_cnt>"0101")then
			--���� 10���ڸ�����6�̵Ǹ� ����1�� �ڸ��� ����
				s10_cnt:="0000";
				m01_cnt:=m01_cnt+1;
			end if;
			if(m01_cnt>"1001")then
			--���� 1���ڸ�����10�̵Ǹ� ����10�� �ڸ��� ����
				m01_cnt:="0000";
				m10_cnt:=m10_cnt+1;
			end if;
			if(m10_cnt>"0101")then
			--���� 10���ڸ�����6�̵Ǹ� �ð���1�� �ڸ��� ����
				m10_cnt:="0000";
				m01_cnt:="0000";
				s10_cnt:="0000";
				s01_cnt:="0000";
			end if;
		end if;
	--���� �ð����� ��Ī
	sec01_cnt<=s01_cnt;
	sec10_cnt<=s10_cnt;
	min01_cnt<=m01_cnt;
	min10_cnt<=m10_cnt;
	end process;
	
end Behavioral;


