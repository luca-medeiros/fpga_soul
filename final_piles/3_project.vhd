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
      updown_2 : in STD_LOGIC;
      invin : in std_logic);
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
         attack_1: inout std_logic;
         attack_2: inout std_logic;
         stage: out std_logic_vector(1 downto 0);
         reattack_1 : in std_logic;
         reattack_2 : in std_logic;
         attack_1_trans : in std_logic;
         attack_2_trans : in std_logic;
         invin : in std_logic;
			score: in std_logic_vector(15 downto 0));
   end component;
   
   component digital_clock
      Port ( FPGA_RSTB : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           attack_1:inout std_logic;
           attack_2:inout std_logic;
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
         reattack_2 : inout std_logic;
         attack_1_trans : out std_logic;
         attack_2_trans : out std_logic;
          stage: in std_logic_vector(1 downto 0);
			 score: out std_logic_vector(15 downto 0));
   end component;
-- 내부신호
signal data_out_reg, w_enable_reg : std_logic; 
signal addr_reg : std_logic_vector(4 downto 0); 
signal data_reg : std_logic_vector(7 downto 0);
signal stage : std_logic_vector(1 downto 0);
signal reattack_1 , reattack_2 : std_logic;
signal attack_1 , attack_2 : std_logic;
signal attack_1_trans, attack_2_trans : std_logic;
signal score: std_logic_vector(15 downto 0);
   Begin
      lcd : LCD_test port map(FPGA_RSTB, CLK, LCD_A, LCD_EN, LCD_D,
            data_out_reg, addr_reg, data_reg, w_enable_reg,stage);
      data : data_gen port map(FPGA_RSTB, CLK, w_enable_reg, data_out_reg,
            addr_reg, data_reg,left_1,right_1,updown_1,left_2,right_2,updown_2,attack_1,attack_2,
				stage,reattack_1,reattack_2,attack_1_trans,attack_2_trans, invin,score);
      clock : digital_clock port map(FPGA_RSTB,CLK,attack_1,attack_2,DIGIT,SEG_A,SEG_B,SEG_C,
            SEG_D,SEG_E,SEG_F,SEG_G,SEG_DP,reattack_1,reattack_2,attack_1_trans,attack_2_trans,stage,score);
end Behavioral;

library IEEE; --LED 값 도출 
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
      stage: in std_logic_vector(1 downto 0));
end LCD_test;

architecture Behavioral of LCD_test is
--내부신호
type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 ); -- 2D array
signal reg_file : reg;
signal w_enable_reg : std_logic;
signal lcd_cnt : std_logic_vector (8 downto 0);
signal lcd_state : std_logic_vector (7 downto 0); --lcd_db를 받고, clock에 따라 이동
signal lcd_nstate : std_logic_vector (7 downto 0);-- lcd_state next state
signal lcd_db : std_logic_vector (7 downto 0);-- output전달하는 내부신호
signal stage_cnt: std_logic_vector (1 downto 0);-- stage변화를 기록하는 내부신호

signal load_100k : std_logic;
signal clk_100k : std_logic;-- 내부 clock 100kHz 
signal cnt_100k : std_logic_vector (7 downto 0);
signal load_50 : std_logic;
signal clk_50 : std_logic;-- 내부 clock 50Hz
signal cnt_50 : std_logic_vector (11 downto 0);

begin
   process(FPGA_RSTB,CLK,load_100k,cnt_100k) 
   --4MHz으로 내부 clock 100kHz 생성
      Begin
         if FPGA_RSTB = '0' then
            cnt_100k <= (others => '0');
            clk_100k <= '0';
         elsif rising_edge (CLK) then
            if load_100k = '1' then
               cnt_100k <= (others => '0');
               clk_100k <= not clk_100k;
            else
               cnt_100k <= cnt_100k + 1;
            end if;
         end if;
   end process;
   
load_100k <= '1' when (cnt_100k = X"13") else '0'; -- 19
--기존 clock period의 40배, 이를 세는 변수

   process(FPGA_RSTB,clk_100k,load_50,cnt_50) 
   --100kHz 으로 78.25Hz
      Begin
         if FPGA_RSTB = '0' then
            cnt_50 <= (others => '0');
            clk_50 <= '0';
         elsif rising_edge (clk_100k) then
            if load_50 = '1' then
               cnt_50 <= (others => '0');
               clk_50 <= not clk_50;
            else
               cnt_50 <= cnt_50 + 1;
            end if;
         end if;
   end process;
   
load_50 <= '1' when (cnt_50 = X"40") else '0'; --64

   process(FPGA_RSTB, CLK) 
   --clock의 rising_edge에 state 변화
      Begin
         if FPGA_RSTB = '0' then
            lcd_state <= (others =>'0');
         elsif rising_edge (clk_50) then
            lcd_state <= lcd_nstate;
         end if;
   end process;
--LCD 의 출력 여부 판단
w_enable_reg <= '0' when lcd_state <= X"4E" else '1';

   process(FPGA_RSTB, CLK)
      Begin
         if FPGA_RSTB = '0' then -- reset = '0' ?
            for i in 0 to 31 loop
               reg_file(i) <= X"20"; -- LED 빈칸으로 초기화 X"20":빈칸저장
            end loop;
         elsif CLK'event and CLK='1' then
         -- LEDdata 를 CLK 마다 전달
            if w_enable_reg ='1' and data_out ='1' then--LCD출력할때
               reg_file(conv_integer(addr)) <= data;--reg_file 에 저장
            end if;
         end if;
   end process;
   
   process(FPGA_RSTB, lcd_state, stage) -- lcd_state (X00~X26)
      Begin
         if FPGA_RSTB='0' then
            lcd_nstate <= X"00";
            stage_cnt <= "00"; --stage 초기변수,이후 stage변화와 비교
         else
            case lcd_state is
               when X"00" => lcd_db <= "00000011" ; -- Return home
                  lcd_nstate <= X"01" ;
               when X"01" => lcd_db <= "00001000" ; -- Display OFF
                  lcd_nstate <= X"02" ;
               when X"02" => lcd_db <= "00000001" ; -- Display clear
                  lcd_nstate <= X"03" ;
               when X"03" => lcd_db <= "00000110" ; -- Entry mode set
                  lcd_nstate <= X"04" ;
               when X"04" => lcd_db <= "00001100" ; -- Display ON
                  lcd_nstate <= X"05" ;
               when X"05" => lcd_db <= "00111000" ; -- Function set
                  lcd_nstate <= X"06" ;
               when X"06" => lcd_db <= "01000000" ; --set CGRAM(X"00") player1
                  lcd_nstate <= X"07";
                  stage_cnt<= stage;--초기에만 실행, stage변화시 stage=/ stage_cnt
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
               when X"2A" => lcd_db <= "01100000" ; --set CGRAM(X"04") full HP bar
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
               when X"33" => lcd_db <= "01101000" ; --set CGRAM(X"05") 3/4 HP bar
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
               when X"3C" => lcd_db <= "01110000" ; --set CGRAM(X"06")2/4 HP bar
                  lcd_nstate <= X"3D";
               when X"3D" => lcd_db <= "00000000" ; --00000
                  lcd_nstate <= X"3E";
               when X"3E" => lcd_db <= "00000000" ; --00000
                  lcd_nstate <= X"3F";
               when X"3F" => lcd_db <= "00000000" ; --00000
                  lcd_nstate <= X"40";
               when X"40" => lcd_db <= "00000000" ; --00000
                  lcd_nstate <= X"41";
               when X"41" => lcd_db <= "00011111" ; --*****
                  lcd_nstate <= X"42";
               when X"42" => lcd_db <= "00011111" ; --*****
                  lcd_nstate <= X"43";
               when X"43" => lcd_db <= "00011111" ; --*****
                  lcd_nstate <= X"44";
               when X"44" => lcd_db <= "00011111" ; --*****
                  lcd_nstate <= X"45";
               when X"45" => lcd_db <= "01111000" ; --set CGRAM(X"07") 1/4 HP bar
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
               when X"4E" => lcd_db <= "10000000" ; --(1,1)"00000011"
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
                     lcd_nstate <=X"4E"; --goto (1,1) of LCD
                  else
                     lcd_nstate <= X"06"; --Cgram set(stage가 바뀌어 monster cgram set)
                  end if;
               when others => lcd_db <= (others => '0') ;
            end case;
         end if;
   end process;
   
LCD_A(1) <= '0';
LCD_A(0) <= '0' when (lcd_state=X"5F" or lcd_state=X"4E" or lcd_state<=X"06"
               or lcd_state=X"0F" or lcd_state=X"18" or lcd_state=X"21"
               or lcd_state=X"2A" or lcd_state=X"33" or lcd_state=X"3C"
               or lcd_state=X"45")
               else '1';
-- LCD_state 에따른 LCD_A 구분
               
LCD_EN <= clk_50; --LCD_EN <= '0' when w_enable_reg='0' else clk_100;
LCD_D <= lcd_db; -- LCD display data
w_enable <= w_enable_reg;
end Behavioral;



library IEEE; -- 입력값 생성 및 연산부분
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
         attack_1: inout std_logic;
         attack_2: inout std_logic;
         stage: out std_logic_vector(1 downto 0);
         reattack_1 : in std_logic;
         reattack_2 : in std_logic;
         attack_1_trans : in std_logic;
         attack_2_trans : in std_logic;
         invin : in std_logic;
	 score: in std_logic_vector(15 downto 0));
end data_gen;
architecture Behavioral of data_gen is
--내부신호 정의
	signal patern_clk : std_logic; -- 패턴 변화 주기를 나타내는 clock	
	signal random_count : std_logic_vector (3 downto 0); -- 랜덤 신호 구현을 위한 signal
	signal stage_data : std_logic_vector (1 downto 0); -- stage 변화시 이 값이 변경
	signal stage_data_saved : std_logic_vector (1 downto 0); -- stage 변화 감지를 위해 저장하는 data
	signal pattern_num : std_logic_vector (1 downto 0); -- boss 패턴 번호를 나타내는 signal
	signal pattern_count : std_logic_vector (4 downto 0); -- boss 패턴의 진행 경과를 나타내는 signal
	signal cnt : std_logic_vector(4 downto 0); -- reg file 출력을 위한 address 변화를 저장
	signal hitted_cnt : std_logic_vector(4 downto 0); -- 전체 게임에서 피격된 횟수를 저장
	signal hitted_cnt_ten : std_logic_vector(4 downto 0); -- 전체 게임에서 피격된 횟수를 저장(10의 자리)

	type reg is array( 0 to 31 ) of std_logic_vector( 7 downto 0 ); -- 2D array
	signal reg_file : reg;
	signal clear_reg : reg;
   
	type pixel_data is array( 0 to 31 ) of std_logic; -- 2D array
	signal arrow_pixel : pixel_data; -- 화살 패턴용 신호
	signal reverse_arrow_pixel : pixel_data; -- 반대 방향 화살 패턴용 신호 2
	signal first_warning : pixel_data; -- 픽셀 폭발 경고 1 용 신호
	signal second_warning : pixel_data; -- 픽셀 폭발 경고 2 용 신호
	signal pixel_explosion : pixel_data; -- 픽셀 폭발용 신호
	signal hit_on : pixel_data; -- 피격 판정용 신호

	signal Mhp : integer range 8 downto 0; -- 보스 HP 저장
	signal Uhp : integer range 4 downto 0; -- 플레이어 HP 저장
   
	signal p1_curSt : integer range 31 downto 0; -- 플레이어 1 현재 위치
	signal p2_curSt : integer range 31 downto 0; -- 플레이어 2 현재 위치
	signal p1_preSt : integer range 31 downto 0; -- 플레이어 1 이전 위치
	signal p2_preSt : integer range 31 downto 0; -- 플레이어 2 이전 위치
	signal position_arrow : integer; -- 보스 3 패턴 생성용 signal
   
	signal special : std_logic; -- 플레이어가 겹친 상태 판별용 signal
   	signal game_over : std_logic; -- game over 상태 판별용 signal
	signal move_clk:std_logic; -- 움직임을 허용하는 상태를 판별하기 위한 clock
	signal move_admit_1 : std_logic; -- 플레이어 1이 움직일 수 있는 상태인지 나타냄
	signal move_admit_2 : std_logic; -- 플레이어 2가 움직일 수 잇는 상태인지 나타냄
	signal shield_admit : std_logic; -- 현재 무적 상태인지 아닌지 나타냄
	signal boss_dead : std_logic; -- 보스가 죽었는지 아닌지 나타냄
	signal game_clear : std_logic; -- 게임을 끝까지 깻는지 아닌지 나타냄
	signal score_cnt: std_logic_vector(15 downto 0); -- 최종 score 출력
	
   
begin
   --2.67HZ patern_clock구현, 0.375초 해당
   process(FPGA_RSTB,clk)
      --2.67HZ를 구현하기위한 clk 변수 count_clk 선언
      variable patern_clk_cnt : integer range 0 to 750000;
   begin
      if(FPGA_RSTB = '0')then
         patern_clk <= '1';
         patern_clk_cnt := 0;
      elsif(clk'event and clk='1')then
         --반주기로 clk 값 750000 세고 0>1,1>0로 바꿈
         if(patern_clk_cnt = 750000)then
            patern_clk_cnt := 0;
            patern_clk <= not patern_clk;
         else
            --750000보다 작으면 1 증가
            patern_clk_cnt := patern_clk_cnt +1;
         end if;
      end if;
   end process;   
	
	--랜덤 구현을 위한 process	      
	process(FPGA_RSTB,clk)
      variable random_cnt : integer range 0 to 7;
   begin
      if(FPGA_RSTB = '0')then
         random_count <= "0000";
         random_cnt := 0;
      elsif(clk'event and clk='1')then
	      --랜덤 카운트가 7이면 0으로
         if(random_cnt = 7)then
            random_cnt := 0;
		--랜덤 용 signal이 최대치면 0000으로
	 if (random_count = "1111") then
	 random_count <= "0000";
				--랜덤 용 signal이 최대치가 아니라면 1 증가
				else
					random_count <= random_count + 1;
				end if;
	--랜덤 카운트가 최대치가 아니라면 1 증가
         else
            random_cnt := random_cnt +1;
         end if;
      end if;
   end process;   



   --매 pattern clock(0.375초)마다 action을 정의
   process(FPGA_RSTB,patern_clk)
      variable pattern_select : std_logic_vector (1 downto 0); -- 패턴 선택에 사용하는 임시 변수
		variable pattern_previous : std_logic_vector (1 downto 0); -- 바로 직전에 사용한 패턴을 저장하는 변수
      variable random_fixed : std_logic;

   begin
      if(FPGA_RSTB = '0')then
         for i in 0 to 31 loop
            arrow_pixel(i) <= '0';
				reverse_arrow_pixel(i) <= '0';
            pixel_explosion(i) <= '0';
            second_warning(i) <= '0';
            first_warning(i) <= '0';
				
         end loop;
         pattern_num <= "00";
         pattern_count <= "00000";
         stage_data_saved <= "00";
			pattern_previous := "00";
			pattern_select := "00";

      elsif(patern_clk'event and patern_clk='1')then
			
         if (stage_data_saved /= stage_data) then
             --보스 변경됨 -> 대기패턴 강제 전환 및 랜덤에 따른 임의 시간 대기
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
				-- 역방향 화살: 화살과 기본적으로 같으나 이동 방향이 우측
				if (reverse_arrow_pixel(i) = '1') then
               reverse_arrow_pixel(i) <= '0';
               if ((i /= 15) and (i /= 31)) then
                  reverse_arrow_pixel(i + 1) <= '1';
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
                     if (random_count (2 downto 1) = "00") then
                        if (random_count (3 downto 2) = "00") then
                           pattern_select := "01";
                        else
                           pattern_select := random_count (3 downto 2);
                        end if;
                     else
                        pattern_select := random_count (2 downto 1);
                     end if;
                  else
                     pattern_select := random_count (1 downto 0);
                  end if;
			  --random_fixed : 0 or 1 
                  random_fixed := random_count(3);
		    				-- 랜덤으로 선택된 패턴이 바로 직전 패턴과 동일할 경우 : 그 다음 번호 패턴으로 변경
						if (pattern_select = pattern_previous) then
							if (pattern_select = "11") then
								pattern_select := "01";
							end if;
							pattern_select := pattern_select + 1;
						end if;
						--선택된 패턴에 따라 올바른 패턴 실행시간 부여 및 실행 패턴을 이전 패턴값으로 저장
                  case pattern_select is
                     when "01" =>
                        pattern_num <= "01";
                        pattern_count <= "10011";
								pattern_previous := "01";
                     when "10" =>
                        pattern_num <= "10";
                        pattern_count <= "11001";
								pattern_previous := "10";
                     when "11" =>
                        pattern_num <= "11";
                        pattern_count <= "11111";
								pattern_previous := "11";
                     when others =>
                        pattern_num <= "00";
                        pattern_count <= "00001";
                  end case;
               end if;
            --패턴 1 : 1줄 화살 x 3 -> 2줄 화살 x 3 -> 1줄 화살  x 3
            --      or 2줄 화살 x 3 -> 1줄 화살 x 3 -> 2줄 화살  x 3 둘중 뭐가 나올지는 random_fixed가 결정
            elsif (pattern_num = "01") then
               pattern_count <= pattern_count - 1;
               if (random_fixed = '0') then
                  case pattern_count is
                     when "10010" =>
                        arrow_pixel(12) <= '1';
                     when "10001" =>
                        arrow_pixel(12) <= '1';
                     when "10000" =>
                        arrow_pixel(12) <= '1';
                     when "01011" =>
                        arrow_pixel(29) <= '1';
                     when "01010" =>
                        arrow_pixel(29) <= '1';
                     when "01001" =>
                        arrow_pixel(29) <= '1';
                     when "00100" =>
                        arrow_pixel(12) <= '1';
                     when "00011" =>
                        arrow_pixel(12) <= '1';
                     when "00010" =>
                        arrow_pixel(12) <= '1';
                     --첫번째 패턴 종료. 임의의 대기시간을 갖는 대기 패턴으로 넘어감
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00100" + ("000" & random_count(1 downto 0));
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
                        arrow_pixel(12) <= '1';
                     when "01010" =>
                        arrow_pixel(12) <= '1';
                     when "01001" =>
                        arrow_pixel(12) <= '1';
                     when "00100" =>
                        arrow_pixel(29) <= '1';
                     when "00011" =>
                        arrow_pixel(29) <= '1';
                     when "00010" =>
                        arrow_pixel(29) <= '1';
                     --첫번째 패턴 종료. 임의의 대기시간을 갖는 대기 패턴으로 넘어감
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00100" + ("000" & random_count(1 downto 0));
                     when others =>
                        NULL;
                  end case;
               end if;

            --패턴 2 : 상단 -> 4 패턴클락마다 상단 -> 화살 발사/ 하단 -> 전체공격
            --상단 -> 4패턴클락마다 전체공격 / 하단 -> 화살 발사 둘중 뭐가 나올지는 random_fixed가 결정
            elsif (pattern_num = "10") then
               pattern_count <= pattern_count - 1;
               if (random_fixed = '0') then
                  case pattern_count is
                     when "11000" =>
                        arrow_pixel(12) <= '1';
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
                        arrow_pixel(12) <= '1';
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
                        arrow_pixel(12) <= '1';
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
                     --두번째 패턴 종료. 임의의 대기시간을 갖는 대기 패턴으로 넘어감
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00100" + ("000" & random_count(1 downto 0));
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
                     --두번째 패턴 종료. 임의의 대기시간을 갖는 대기 패턴으로 넘어감
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00100" + ("000" & random_count(1 downto 0));
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
                  --세번째 패턴 종료. 임의의 대기시간을 갖는 대기 패턴으로 넘어감
                  when "00000" =>
                     pattern_num <= "00";
                     pattern_count <= "00101" + ("000" & random_count(1 downto 0));
                  when others =>
                     NULL;
               end case;
            end if;
--------------- STAGE 2 ----------------------------
         elsif (stage_data = "10") then
				if (pattern_num = "00") then
               --pattern_count가 0이 될 때 까지 1씩 감소시키며 대기
               if (pattern_count /= "00000") then
                  pattern_count <= pattern_count - 1;
               --pattern_count가 0이 될 시 난수를 이용한 임의의 패턴 부여 (00 제외)
               else
                  if (random_count (1 downto 0) = "00") then
                     if (random_count (2 downto 1) = "00") then
                        if (random_count (3 downto 2) = "00") then
                           pattern_select := "01";
                        else
                           pattern_select := random_count (3 downto 2);
                        end if;
                     else
                        pattern_select := random_count (2 downto 1);
                     end if;
                  else
                     pattern_select := random_count (1 downto 0);
                  end if;
                  random_fixed := random_count(3);
						if (pattern_select = pattern_previous) then
							if (pattern_select = "11") then
								pattern_select := "01";
							end if;
							pattern_select := pattern_select + 1;
						end if;
                  case pattern_select is
                     when "01" =>
                        pattern_num <= "01";
                        pattern_count <= "10011";
								pattern_previous := "01";
                     when "10" =>
                        pattern_num <= "10";
                        pattern_count <= "11001";
								pattern_previous := "10";
                     when "11" =>
                        pattern_num <= "11";
                        pattern_count <= "10000";
								pattern_previous := "11";
                     when others =>
                        pattern_num <= "00";
                        pattern_count <= "00001";
                  end case;
               end if;
            --Pattern 1-1 : |x|_|x|_|x|_|_|_|x|_|x|_|x|B|HP|HP|
            --              |_|x|_|_|_|x|_|x|_|_|_|x|_|<|HP|HP|
            elsif (pattern_num = "01") then
               pattern_count <= pattern_count - 1;
               if (random_fixed = '0') then
                  case pattern_count is
                     when "10010" | "01011"  | "01000" =>
								arrow_pixel(29) <= '1';
                        first_warning(0) <= '1';
                        first_warning(2) <= '1';
                        first_warning(4) <= '1';
                        first_warning(8) <= '1';
                        first_warning(10) <= '1';
                        first_warning(12) <= '1';
                        first_warning(17) <= '1';
                        first_warning(21) <= '1';
                        first_warning(23) <= '1';
                        first_warning(27) <= '1';
                        first_warning(29) <= '1';
							when "00101" =>
								reverse_arrow_pixel(16) <= '1';
                     -- Delay of 1s ~ 1.75s
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00010" + ("00" & random_count(2 downto 0));
                     when others =>
                        NULL;
                  end case;
                  
            --Pattern 1-2 : |_|x|_|x|_|x|_|x|_|x|_|x|_|B|HP|HP|
            --           	 |x|_|x|_|x|_|x|_|x|_|x|_|x|_|HP|HP|
               else
                  case pattern_count is
                     when "10010" | "01011"  | "01000" =>
								reverse_arrow_pixel(16) <= '1';
                        first_warning(1) <= '1';
                        first_warning(3) <= '1';
                        first_warning(5) <= '1';
                        first_warning(7) <= '1';
                        first_warning(11) <= '1';
                        first_warning(13) <= '1';
                        first_warning(16) <= '1';
                        first_warning(20) <= '1';
                        first_warning(24) <= '1';
                        first_warning(26) <= '1';
                        first_warning(28) <= '1';


                     -- Delay of 0.5s ~ 1.25s
                     when "00000" =>
                        pattern_num <= "00";
                        pattern_count <= "00010" + ("000" & random_count(1 downto 0));
                     when others =>
                        NULL;
                  end case;
               end if;
               
            -- 패턴 2 sine wave        |_|_|x|_|_|_|x|_|_|_|x|_|<|B|HP|HP|
            -- with arrow top/bot     |x|_|_|_|x|_|_|_|x|_|_|_|x|<|HP|HP|
            elsif (pattern_num = "10") then
               pattern_count <= pattern_count - 1;
               case pattern_count is
                  when "11000" =>
                     arrow_pixel(12) <= '1';
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';
                  when "10000" =>
                     arrow_pixel(29) <= '1';
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';
                  when "01000" =>
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';
							
						when "00111" =>
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';
							
						when "00110" =>
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';

						when "00101" =>
                     first_warning(2) <= '1';
                     first_warning(6) <= '1';
                     first_warning(10) <= '1';
                     first_warning(16) <= '1';
                     first_warning(20) <= '1';
                     first_warning(24) <= '1';
                     first_warning(28) <= '1';
                     
                  when "00000" =>
                     pattern_num <= "00";
                     pattern_count <= "00010" + ("000" & random_count(1 downto 0));
                  when others =>
                     NULL;
               end case;
				-- Pattern 3 
				-- 		|0|1|2|3|4|5|6|7|8|9|0|1|2|B|HP|HP|
				-- 		|6|7|8|9|0|1|2|3|4|5|6|7|8|9|HP|HP|
				-- 		|>|_|_|_|_|_|_|_|_|_|_|_|<|B|HP|HP|
				-- 		|X|X|X|_|_|_|X|X|_|_|_|X|X|X|HP|HP|
				elsif (pattern_num = "11") then
					pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							-- Reverse and normal arrow
							when "01111" =>
								reverse_arrow_pixel(0) <= '1';
								arrow_pixel(12) <= '1';
							when "01101"  =>
								first_warning(22) <= '1';
								first_warning(23) <= '1';
								
							when "00111"  =>
								first_warning(16) <= '1';
								first_warning(29) <= '1';
								
							when "00110"  =>
								first_warning(17) <= '1';
								first_warning(28) <= '1';
					
							when "00101"  =>
								first_warning(18) <= '1';
								first_warning(27) <= '1';
								
							-- Delay of 0.5s ~ 1.25s
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					else 
				-- 		|X|X|X|_|_|_|X|X|_|_|_|X|X|B|HP|HP|
				-- 		|>|_|_|_|_|_|_|_|_|_|_|_|_|<|HP|HP|
						case pattern_count is
							when "01111" =>
								reverse_arrow_pixel(0) <= '1';
								arrow_pixel(12) <= '1';
							when "01101"  =>
								first_warning(6) <= '1';
								first_warning(7) <= '1';
								
							when "00111"  => 
								first_warning(0) <= '1';
								first_warning(12) <= '1';
								
							when "00110"  =>
								first_warning(1) <= '1';
								first_warning(11) <= '1';
					
							when "00101"  =>
								first_warning(2) <= '1';
	
							-- Delay of 0.5s ~ 1.25s
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
					end if;
				end if;
-------------------------- stage 3 ----------------------------------
			elsif (stage_data = "11") then
            if (pattern_num = "00") then
               if (pattern_count /= "00000") then
                  pattern_count <= pattern_count - 1;
               else
                  if (random_count (1 downto 0) = "00") then
                     if (random_count (2 downto 1) = "00") then
                        if (random_count (3 downto 2) = "00") then
                           pattern_select := "01";
                        else
                           pattern_select := random_count (3 downto 2);
                        end if;
                     else
                        pattern_select := random_count (2 downto 1);
                     end if;
                  else
                     pattern_select := random_count (1 downto 0);
                  end if;
                  random_fixed := random_count(3);
						if (pattern_select = "11") then
							pattern_select := "01";
						end if;
                  case pattern_select is
                     when "01" =>
                        pattern_num <= "01";
                        pattern_count <= "01111";
								pattern_previous := pattern_select;
                     when "10" =>
                        pattern_num <= "10";
                        pattern_count <= "00110";
								pattern_previous := pattern_select;
                     when "11" =>
                        pattern_num <= "01";
								random_fixed := '1';
                        pattern_count <= "01111";
								pattern_previous := pattern_select;
                     when others =>
                        pattern_num <= "00";
                        pattern_count <= "00001";
                  end case;
               end if;
					-- 	|X|_|_|_|_|1<|>|_|_|2<|>|_|_|B|HP|HP| OR
					-- 	|X|_|_|_|_|2<|>|_|_|1<|>|_|_|_|HP|HP| 
				elsif (pattern_num = "01") then
					pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							when "01110" =>
								if p1_curSt >= 15 then -- If player1 is on line 2
									if p1_curSt >= 23 then -- And right side of map
										position_arrow <= 21;
									else
										position_arrow <= 5;
									arrow_pixel(position_arrow) <= '1';
									reverse_arrow_pixel(position_arrow + 1) <= '1';
									end if;
								else -- Line 1
									if p1_curSt >= 7 then -- Right side of map
										position_arrow <= 5;
									else
										position_arrow <= 21;
									end if;
								end if;
								
							when "01101" =>
								arrow_pixel(position_arrow) <= '1';
								reverse_arrow_pixel(position_arrow + 1) <= '1';
								
								
							when "01001" =>
								if (position_arrow = 21) then
									arrow_pixel(position_arrow - 12) <= '1';
									reverse_arrow_pixel(position_arrow - 11) <= '1';
								else
									arrow_pixel(position_arrow + 20) <= '1';
									reverse_arrow_pixel(position_arrow +21) <= '1';
								end if;
								first_warning(0) <= '1';
								first_warning(16) <= '1';

						-- 	|_|_|_|_|_|_|_|_|_|_|_|_|X|B|HP|HP|
						-- 	|_|_|_|_|_|_|_|_|_|_|_|_|_|X|HP|HP|
							when "00110" =>
								first_warning(12) <= '1';
								first_warning(29) <= '1';
								
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("00" & random_count(2 downto 0));
							when others =>
								NULL;
						end case;
					else
						case pattern_count is
						-- 	|_|_|_|_|X|P|X|_|_|X|_|_|_|B|HP|HP|
						-- 	|_|_|_|_|_|X|_|_|X|P|X|_|_|_|HP|HP|
						-- Warning on all 3 blocks around player 1 and 2
							when "01101" =>
								if p1_curSt >= 15 then
									first_warning(p1_curSt - 16 ) <= '1';
								else
									first_warning(p1_curSt + 16 ) <= '1';
								end if;
								first_warning(p1_curSt -1 ) <= '1';
								first_warning(p1_curSt + 1 ) <= '1';
								
								if p2_curSt >= 15 then
									first_warning(p2_curSt - 16 ) <= '1';
								else
									first_warning(p2_curSt + 16 ) <= '1';
								end if;
								first_warning(p2_curSt -1 ) <= '1';
								first_warning(p2_curSt + 1 ) <= '1';
								
						-- 	|_|_|_|_|_|P|_|_|_|_|_|_|<|B|HP|HP|
						-- 	|>|_|_|_|_|_|_|_|_|P|_|_|_|_|HP|HP|
							when "01010" =>
								if p1_curSt >= 15 then -- If player1 is on line 2
									if p1_curSt >= 23 then -- And right side of map
										reverse_arrow_pixel(16) <= '1'; -- Send reverse on line 2
									else
										arrow_pixel(29) <= '1'; -- Send arrow on line 2
									end if;
								else -- Line 1
									if p1_curSt >= 7 then -- Right side of map
										reverse_arrow_pixel(0) <= '1'; -- Send reverse on line 1
									else
										arrow_pixel(12) <= '1'; -- Send arrow on line 1
									end if;
								end if;
						-- 	|_|_|_|_|_|_|_|_|_|_|_|_|X|B|HP|HP|
						-- 	|_|_|_|_|_|_|_|_|_|_|_|_|_|X|HP|HP|
							when "00010" =>
								first_warning(12) <= '1';
								first_warning(29) <= '1';
								
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("00" & random_count(2 downto 0));
							when others =>
								NULL;
						end case;
					end if;
				-- 	|X|X|X|_|_|_|_|_|_|_|_|_|_|B|HP|HP|
				-- 	|X|X|X|_|_|_|_|_|_|_|_|_|_|_|HP|HP|
				elsif (pattern_num = "10") then
               pattern_count <= pattern_count - 1;
					if (random_fixed = '0') then
						case pattern_count is
							when "00101" =>
								first_warning(0) <= '1';
								first_warning(16) <= '1';
							when "00011" =>
								first_warning(1) <= '1';
								first_warning(17) <= '1';
							when "00010" =>
								first_warning(2) <= '1';
								first_warning(18) <= '1';  
							                    
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
				-- 	|_|_|_|_|_|_|_|_|_|_|X|X|X|B|HP|HP|
				-- 	|_|_|_|_|_|_|_|_|_|_|X|X|X|X|HP|HP|
					else
						case pattern_count is
							when "00101" =>
								first_warning(29) <= '1';
								first_warning(12) <= '1';
								first_warning(28) <= '1';
							when "00011" =>
								first_warning(11) <= '1';
								first_warning(27) <= '1';
							when "00010" =>
								first_warning(10) <= '1';
								first_warning(26) <= '1';                 
							when "00000" =>
								pattern_num <= "00";
								pattern_count <= "00010" + ("000" & random_count(1 downto 0));
							when others =>
								NULL;
						end case;
               end if;
				end if;

         end if;
      end if;
   end process;

   --stage data 전달
   stage <= stage_data;

  
   --FPGA 동작과, 쿨타임설정, 초기값, CLK 에따른 전반적인 move
   process(FPGA_RSTB,clk,attack_1_trans,attack_2_trans,move_clk)
   variable move_cnt_1 : integer range 0 to 1000000;
   variable move_cnt_2 : integer range 0 to 1000000;
   variable shield_cnt : integer range 0 to 3000000;
   begin
		--초기화 시 설정값
      if(FPGA_RSTB = '0')then
         for i in 0 to 31 loop
            hit_on(i) <= '0';
            reg_file(i) <= X"20";
         end loop;
         stage_data  <= "00";
         game_over <= '0';
			game_clear <= '0';
        
         p1_curSt <= 0;
         p2_curSt <= 16;
         p1_preSt <= 1;
         p2_preSt <= 17;
         special <= '0';
         Uhp <= 4;
         move_admit_1 <= '1';
         move_cnt_1 := 0;
         move_admit_2 <= '1';
         move_cnt_2 := 0;
         shield_admit<='0';
         shield_cnt :=0;
         Mhp <= 0;
			hitted_cnt <= "00000";
			boss_dead <= '0';
      elsif(clk'event and clk='1')then
		--player의 피격에 따른 쿨타임
         if (shield_admit='1') then
            shield_cnt:= shield_cnt +1;
            if(shield_cnt=3000000) then
               shield_cnt:=0;
               shield_admit<='0';
            end if;
         end if;
         if (move_admit_1 = '0') then
			--player1 의 움직임에 따른 쿨타임
            move_cnt_1 := move_cnt_1 + 1;
            if (move_cnt_1 = 1000000) then
               move_cnt_1 := 0;
               move_admit_1 <= '1';
            end if;
         end if;
         if (move_admit_2 = '0') then
			--player2 의 움직임에 따른 쿨타임
            move_cnt_2 := move_cnt_2 + 1;
            if (move_cnt_2 = 1000000) then
               move_cnt_2 := 0;
               move_admit_2 <= '1';
            end if;
         end if;
      
			
			
         if (stage_data = "00") then
            --   FPGA  SOUL (screen text)
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
            --입력이 들어오면, game start
            if ((left_1 = '0') or (left_2 = '0') or (right_1 = '0') or (right_2 = '0') or (updown_1 = '0') or (updown_2 = '0')) then
               reg_file <= clear_reg; -- Clear LCD Screen
               stage_data <= "01"; -- Start stage
               
               Mhp <= 8;
               move_admit_1 <= '0';
               move_admit_2 <= '0';
               shield_admit<= '1';
            end if;
         elsif( game_over = '0') then
               --player 이동
					
            --player1 왼쪽으로 이동 설정
            if (left_1 = '0' and move_admit_1 = '1') then
               --player1 왼쪽 한계 설정
               if( p1_curSt = 0 or p1_curSt = 16 ) then
                  p1_curSt <= p1_curSt;
                  p1_preSt <= p1_preSt;
               else 
                  p1_preSt <= p1_curSt;
                  p1_curSt <= p1_curSt - 1;
                  move_admit_1 <= '0';
               end if;
            --player1 오른쪽으로 이동 설정
            elsif (right_1 = '0' and move_admit_1 = '1') then
               --player1 오른쪽 한계 설정
               if( p1_curSt = 12 or p1_curSt = 29) then
                  p1_curSt <= p1_curSt;
                  p1_preSt <= p1_preSt;
               else
                  p1_preSt <= p1_curSt;
                  p1_curSt <= p1_curSt + 1;
                  move_admit_1 <= '0';
               end if;   
            --player1 위/아래 줄 바꿈 설정
            elsif (updown_1 = '0' and move_admit_1 = '1') then
               if( p1_curSt = 29) then
                  p1_curSt <= p1_curSt;
                  p1_preSt <= p1_preSt;
               else
                  if(p1_curSt >= 0 and p1_curSt <= 12) then
                     p1_preSt <= p1_curSt;
                     p1_curSt <= p1_curSt + 16;
                     move_admit_1 <= '0';
                  elsif(p1_curSt >= 16 and p1_curSt <= 28) then
                     p1_preSt <= p1_curSt;
                     p1_curSt <= p1_curSt - 16;
                     move_admit_1 <= '0';
                  end if;
               end if;
            end if;
            
            --player2 왼쪽으로 이동 설정
            if (left_2 = '0' and move_admit_2 = '1') then
               --player2 왼쪽 한계 설정
               if( p2_curSt = 0 or p2_curSt = 16 ) then
                  p2_curSt <= p2_curSt;
                  p2_preSt <= p2_preSt;
               else 
                  p2_preSt <= p2_curSt;
                  p2_curSt <= p2_curSt - 1;
                  move_admit_2 <= '0';
               end if;
            --player2 오른쪽으로 이동 설정
            elsif (right_2 = '0' and move_admit_2 = '1') then
               --player2 오른쪽 한계 설정
               if( p2_curSt = 12 or p2_curSt = 29) then
                  p2_curSt <= p2_curSt;
                  p2_preSt <= p2_preSt;
               else
                  p2_preSt <= p2_curSt;
                  p2_curSt <= p2_curSt + 1;
                  move_admit_2 <= '0';
               end if;    
            
            --player2 위/아래 줄 바꿈 설정
            elsif (updown_2 = '0' and move_admit_2 = '1') then
               if( p2_curSt = 29) then
                  p2_curSt <= p2_curSt;
                  p2_preSt <= p2_preSt;
               else
                  if(p2_curSt >= 0 and p2_curSt <= 12) then
                     p2_preSt <= p2_curSt;
                     p2_curSt <= p2_curSt + 16;
                     move_admit_2 <= '0';
                  elsif(p2_curSt >= 16 and p2_curSt <= 28) then
                     p2_preSt <= p2_curSt;
                     p2_curSt <= p2_curSt - 16;
                     move_admit_2 <= '0';
                  end if;
               end if;
            end if;
            if(attack_1_trans = '0')then
               attack_1<='0';
            end if;
            if(attack_2_trans = '0')then
               attack_2<='0';
            end if;
            --player 공격
            --player가 몬스터와 일정 거리 안에서 겹쳤을 때 공격
            if (special = '1') then
					if reattack_1 = '1' and reattack_2='1' then
						if (p1_curSt = 29) then	
							if(updown_1 = '0' or updown_2 = '0') then
								if (Mhp = 0) then
									boss_dead <= '1';
								else
									Mhp <= Mhp - 1;
								end if;
								p1_curSt <= p1_curSt;
								p2_curSt <= p2_curSt;
								attack_1<='1';
								attack_2<='1';   
							end if;
						elsif (right_1 = '0' or right_2 = '0') then
							if (Mhp = 0) then
								boss_dead <= '1';
							else
								Mhp <= Mhp - 1;
							end if;
							p1_curSt <= p1_curSt;
							p2_curSt <= p2_curSt;
							attack_1<='1';
							attack_2<='1';
						end if;
						if(left_1 = '0') then
							p1_curSt <= p1_curSt-1;
						elsif (left_2 = '0') then
							p2_curSt <= p2_curSt-1;
						end if;	
					end if;
					
            --player가 겹치지 않은 경우
            else
					--player1 공격 설정
               if (reattack_1 = '1') then
                  if (p1_curSt = 12) then
                     if (right_1 = '0') then
								if (Mhp = 0) then
									boss_dead <= '1';
								else
									Mhp <= Mhp - 1;
								end if;
                        attack_1<='1';
                     end if;
                  elsif (p1_curSt = 29) then
                     if (updown_1 = '0') then
                        if (Mhp = 0) then
									boss_dead <= '1';
								else
									Mhp <= Mhp - 1;
								end if;
                        attack_1<='1';
                     end if;
                  end if;
               end if;
					
					--player2 공격 설정
               if (reattack_2 = '1') then
                  if (p2_curSt = 12) then
                     if (right_2 = '0') then
                        if (Mhp = 0) then
									boss_dead <= '1';
								else
									Mhp <= Mhp - 1;
								end if;
                        attack_2<='1';
                     end if;
                  elsif (p2_curSt = 29) then
                     if (updown_2 = '0') then
                        if (Mhp = 0) then
									boss_dead <= '1';
								else
									Mhp <= Mhp - 1;
								end if;
                        attack_2<='1';
                     end if;
                  end if;
               end if;
            end if;
            
            --monster관련 hit_on and reg_file 대입
            for i in 0 to 31 loop
               -- 게임 플레이가 이루어지는 픽셀 안에서
               if ((i /= 13) or (i /= 14) or (i /= 15) or (i /= 30) or (i /= 31)) then
                  -- 피격 판정을 나타내는 hit_on을 loop 시작시 초기화
                  hit_on(i) <= '0';
                  --화살이 해당 pixel에 있는 상태라면 "<" 표시 및 피격 판정 ON
                  if (arrow_pixel(i) = '1') then
                     hit_on(i) <= '1';
                     reg_file(i) <= X"3C";
                  -- 역방향 화살이 해당 pixel에 있는 상태라면 ">" 표시 및 피격 판정 ON
						elsif (reverse_arrow_pixel(i) = '1') then
							hit_on(i) <= '1';
							reg_file(i) <= X"3E";
		  -- pixel 폭발이 해당 pixel에 있는 상태라면 "까만 네모" 표시 및 피격 판정 ON
                  elsif (pixel_explosion(i) = '1') then
                     hit_on(i) <= '1';
                     reg_file(i) <= X"FF";
                  -- 첫번쨰 경고/ 두번째 경고가 해당 pixel에 있는 상태라면 "!" 표시
                  elsif ((first_warning(i) = '1') or (second_warning(i) = '1')) then
                     reg_file(i) <= X"21";
                  -- 전부 아님 : 빈칸으로 변경
                  else
                     reg_file(i) <= X"20";
                  end if;
               else
               end if;
               
            end loop;
            --보스 몬스터 항상 표시
            reg_file(13) <= X"03";
            if (stage_data /= "00") then
            --CGRAM에 입력한 배터리를 이용하여 보스 체력 표시
               case Mhp is
                  when 8 => reg_file(30) <= X"FF";
                            reg_file(31) <= X"FF";
                  when 7 => reg_file(30) <= X"05";
                            reg_file(31) <= X"FF";
                  when 6 => reg_file(30) <= X"06";
                            reg_file(31) <= X"FF";
                  when 5 => reg_file(30) <= X"07";
                            reg_file(31) <= X"FF";
                  when 4 => reg_file(30) <= X"20";
                            reg_file(31) <= X"FF";
                  when 3 => reg_file(30) <= X"20";
                            reg_file(31) <= X"05";
                  when 2 => reg_file(30) <= X"20";
                            reg_file(31) <= X"06";
                  when 1 => reg_file(30) <= X"20";
                            reg_file(31) <= X"07";
                  when 0 => reg_file(30) <= X"20";
                            reg_file(31) <= X"20";
                  when others => Null;
               end case;
     
            --ASCII code 기호를 이용하여 플레이어 체력 표시
               case Uhp is
                  when 4 => reg_file(14) <= X"2A";
                            reg_file(15) <= X"2A";
						when 3 => reg_file(14) <= X"2E";
                            reg_file(15) <= X"2A";
                  when 2 => reg_file(14) <= X"20";
                            reg_file(15) <= X"2A";
                  when 1 => reg_file(14) <= X"20";
                            reg_file(15) <= X"2E";
                  when 0 => reg_file(14) <= X"20"; 
                            reg_file(15) <= X"20";
                  when others => Null;
               end case;
            end if;
				
				--보스 사망 : 다음 스테이지로 넘어가기
				if (boss_dead = '1') then
					hitted_cnt <= 4 - Uhp + hitted_cnt;
					Uhp <= 4;
					MHp <= 8;
					boss_dead <= '0';
					if (stage_data = "11")  then
						score_cnt(15 downto 12)<="1001"-score(15 downto 12);
						score_cnt(11 downto 8)<="1001"-score(11 downto 8);
						score_cnt(7 downto 4)<="1001"-score(7 downto 4);
						score_cnt(3 downto 0)<="1001"-score(3 downto 0);
						game_clear <= '1';
						game_over <= '1';
					else
						stage_data <= stage_data + 1;
					end if;
					p1_curSt <= 0;
					p2_curSt <= 16;
				end if;
				
            --player 피격에 따른 hp 감소
            if (shield_admit = '0' and invin = '0' and((hit_on(p1_curSt) = '1') or (hit_on(p2_curSt) = '1'))) then
               if (Uhp = 0) then
                  game_over <= '1';
               else
                  Uhp <= Uhp - 1;
                  shield_admit<='1';
               end if;
            end if;
            
               --player1과  player2가 겹쳤을 때
            if (p1_curSt = p2_curSt) then
               reg_file(p1_curSt) <= X"02";
               if (p1_curSt >= 10 and p1_curSt < 13) or (p1_curSt >= 26 and p1_curSt <= 29) then
                  special <= '1';
               else
                  special <= '0';
               end if;
            --player1 이전 위치와 player2 현재 위치가 겹쳤을 때 : player2 현재 상태가 우선
            elsif (p2_curSt = p1_preSt) then
               special <= '0';
               reg_file(p1_curSt) <= X"00";
               reg_file(p2_curSt) <= X"01";
            --player2 이전 위치와 player1 현재 위치가 겹쳤을 때 : player1 현재 상태가 우선
            elsif (p1_curSt = p2_preSt) then
               special <= '0';
               reg_file(p1_curSt) <= X"00";
               reg_file(p2_curSt) <= X"01";             
            --player 위치 reg_file로 전달(LCD DATA)
            else
               special <= '0';
               reg_file(p1_curSt) <= X"00";
               reg_file(p2_curSt) <= X"01";
            end if;
         
			--game이 끝났을 때
         else
				--모든 stage clear 
				if (game_clear = '1') then
					if (hitted_cnt >= 10) then
						hitted_cnt <= hitted_cnt - 10;
						hitted_cnt_ten <= hitted_cnt_ten + 1;
					end if;
					reg_file(0) <= X"20";
					reg_file(1) <= X"20";
					reg_file(2) <= X"53";--S
					reg_file(3) <= X"43";--C
					reg_file(4) <= X"4F";--O
					reg_file(5) <= X"52";--R
					reg_file(6) <= X"45";--E
					reg_file(7) <= X"20";
					reg_file(8) <=score_cnt(15 downto 12) + X"30";--점수 표현
					reg_file(9) <= score_cnt(11 downto 8) + X"30";
					reg_file(10) <= score_cnt(7 downto 4) + X"30";
					reg_file(11) <= score_cnt(3 downto 0) + X"30";
					reg_file(12) <= X"20";
					reg_file(13) <= X"20";
					reg_file(14) <= X"20";
					reg_file(15) <= X"20";
					reg_file(16) <= X"20";
					reg_file(17) <= X"20";
					reg_file(18) <= X"4C";--L
					reg_file(19) <= X"4F";--O
					reg_file(20) <= X"53";--S
					reg_file(21) <= X"54";--T
					reg_file(22) <= X"20";--
					reg_file(23) <= X"4C";--L
					reg_file(24) <= X"49";--I
					reg_file(25) <= X"46";--F
					reg_file(26) <= X"45";--E
					reg_file(27) <= X"20";
					reg_file(28) <= hitted_cnt_ten + X"30";--LIFE 표현
					reg_file(29) <= hitted_cnt + X"30";
					reg_file(30) <= X"20";
					reg_file(31) <= X"20";
					
				--GAME OVER (모든 stage가 끝나기 전에 player hp가 0이된 경우)
				else
					reg_file(0) <= X"20";
					reg_file(1) <= X"20";
					reg_file(2) <= X"20";
					reg_file(3) <= X"47";--G
					reg_file(4) <= X"41";--A
					reg_file(5) <= X"4D";--M
					reg_file(6) <= X"45";--E
					reg_file(7) <= X"20";
					reg_file(8) <= X"20";
					reg_file(9) <= X"4F";--O
					reg_file(10) <= X"56";--V
					reg_file(11) <= X"45";--E
					reg_file(12) <= X"52";--R
					reg_file(13) <= X"20";
					reg_file(14) <= X"20";
					reg_file(15) <= X"20";
					reg_file(16) <= X"20";
					reg_file(17) <= X"20";
					reg_file(18) <= X"50";--P
					reg_file(19) <= X"52";--R
					reg_file(20) <= X"45";--E
					reg_file(21) <= X"53";--S
					reg_file(22) <= X"53";--S
					reg_file(23) <= X"20";
					reg_file(24) <= X"20";
					reg_file(25) <= X"52";--R
					reg_file(26) <= X"45";--E
					reg_file(27) <= X"53";--S
					reg_file(28) <= X"45";--E
					reg_file(29) <= X"54";--T
					reg_file(30) <= X"20";
					reg_file(31) <= X"20";
				end if;
         end if;
         
      end if;
      
   end process;

process(FPGA_RSTB, clk)
   Begin
      if FPGA_RSTB ='0' then
         cnt <= (others => '0');
         data_out <= '0';
      elsif clk='1' and clk'event then
		--lcdtest 로 data 와 addr를 전달
         if w_enable = '1' then
            data <= reg_file (conv_integer(cnt));
            addr <= cnt;
            data_out <= '1';
            if cnt= X"1F" then--regfile(31)까지 저장
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
           attack_1: inout std_logic;--attack 변수
           attack_2: inout std_logic;
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
         reattack_2 : inout std_logic;
         attack_1_trans : out std_logic;
         attack_2_trans : out std_logic;
          stage: in std_logic_vector(1 downto 0);
			 score: out std_logic_vector(15 downto 0));
end digital_clock;

architecture Behavioral of digital_clock is
--내부신호
signal s01_clk:std_logic;--1Hz clock
--s01_clk에 맞게 count 되는 시간 변수
signal cool1:std_logic_vector(3 downto 0);
signal cool2:std_logic_vector(3 downto 0);
signal min10_cnt,min01_cnt:std_logic_vector(3 downto 0);
signal sec10_cnt,sec01_cnt:std_logic_vector(3 downto 0);
signal sel:std_logic_vector(2 downto 0);
signal data:std_logic_vector(3 downto 0);
signal seg: std_logic_vector(7 downto 0);
signal cool_cnt1: std_logic_vector(3 downto 0);
signal cool_cnt2: std_logic_vector(3 downto 0);
signal hitted_num : std_logic_vector (5 downto 0);
signal reattack_1_temp : std_logic;
signal reattack_2_temp : std_logic;

begin
   process(sel)
   begin
      case sel is
      --segment 첫번째 자리: 분의 십의자리
         when "000"=> DIGIT<="000001";
                        data<=min10_cnt;
      --segment 두번째 자리: 분의 일의자리
         when "001"=> DIGIT<="000010";
                        data<=min01_cnt;
      --segment 세번째 자리: 초 십의자리
         when "010"=> DIGIT<="000100";
                        data<=sec10_cnt;
      --segment 네번째 자리: 초의 일의자리
         when "011"=> DIGIT<="001000";
                        data<=sec01_cnt;
      --segment 다섯번째 자리: player1 attack cooltime
         when "100"=> DIGIT<="010000";
                        data<=cool1;
      --segment 여섯번째 자리: player2 attack cooltime
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
   
	reattack_1 <= reattack_1_temp;
	reattack_2 <= reattack_2_temp;
   process(s01_clk,FPGA_RSTB,attack_1)-- player1 공격시 쿨타임 표현
   begin
      if (FPGA_RSTB='0')then--3초의 쿨타임, 재공격 시그널:1, datagen으로 전달
         cool_cnt1<="0000"; 
			attack_1_trans <= '1';
			reattack_1_temp <= '1';
      elsif(attack_1='1' and reattack_1_temp = '1')then
         cool_cnt1<="0010";--쿨타임 3초
         attack_1_trans<='0';--attack신호를 datagen에서 0으로 초기화
         reattack_1_temp <= '0';--재공격 X신호를 datagen 전달
      elsif(s01_clk = '1' and s01_clk'event)then
         if (cool_cnt1 > "0000")then
            attack_1_trans<='1';
            cool_cnt1<=cool_cnt1-1;
         else reattack_1_temp<='1';--0초가 되면,재공격 가능
         end if;
      end if;
      
   cool1<=cool_cnt1;--시간data 전달
   end process;
      
   process(s01_clk,FPGA_RSTB,attack_2)-- player2 공격시 쿨타임 표현
   begin
      if (FPGA_RSTB='0')then--3초의 쿨타임, 재공격 시그널:1, datagen으로 전달
         cool_cnt2<="0000";
			reattack_2_temp<='1';
			attack_2_trans <= '1';
      elsif(attack_2='1' and reattack_2_temp = '1')then
         attack_2_trans<='0';--attack신호를 datagen에서 0으로 초기화
         cool_cnt2<="0010";--쿨타임 3초
         reattack_2_temp<='0';--재공격 X신호를 datagen 전달
      elsif(s01_clk = '1' and s01_clk'event)then
         if (cool_cnt2 > "0000")then
            attack_2_trans<='1';
            cool_cnt2<=cool_cnt2-1;
         else
            reattack_2_temp<='1';--0초가 되면,재공격 가능
         end if;
      end if;
      
   cool2<=cool_cnt2;--시간 data 전달
   end process;
   
   process(s01_clk,FPGA_RSTB,stage)
   variable m10_cnt,m01_cnt:std_logic_vector(3 downto 0);
   variable s10_cnt,s01_cnt:std_logic_vector(3 downto 0);
   begin
      if(FPGA_RSTB='0')then
         --LED00:00:00초기화
         m10_cnt:="0000";
         m01_cnt:="0000";
         s10_cnt:="0000";
         s01_cnt:="0000";
      elsif(s01_clk='1' and s01_clk'event and stage>="01")then
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
         --분의 10의자리수가10이되면 초기화
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
	--시간data를 합쳐서 datagen에서 연산
	score<= min10_cnt & min01_cnt & sec10_cnt & sec01_cnt;
   end process;
   
end Behavioral;
