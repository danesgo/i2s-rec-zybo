----------------------------------------------------------------------------------
-- Engineer: Daniel González 
-- 
-- Create Date:    22:08:55 09/27/2015 
-- Design Name: 	 
-- Module Name:    i2s_rec - Behavioral 
-- Project Name: 
-- Target Devices: Zybo Developing Board
-- Tool versions:  
-- Description: i2s comunication module for recording audio trough the on board codec SSM2603 in slave mode, using default 
--  configurations, Mic input(mono) 24-bit ADC @ 48KHz. 
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- SSM2603 Codec on the zybo
-- Rec Mono (One Channel) Fs=48Khz, MCLK = 1.152MHz (48000Hz * 24bits = 1.152Mhz)

entity i2s_rec is
	generic(
		width: integer := 24 -- Single Channel 24 bit ADC.
	);
	
	port(
		clk: in std_logic; -- main zybo clock 125 MHz 
		recdat: in std_logic; -- data to be recorded
		rst: in std_logic; --reset
		--output
		mclk: out std_logic; -- 12.2MHz (obtained from the SSM2603 codec datasheet)
		bclk: out std_logic; -- 1.152MHz
		reclrc: out std_logic; -- always low = '0' because it's always channel 1
		mute: out std_logic; -- always high = '1' because it's never muted
		done: out std_logic; 
		d_out: out std_logic_vector(width-1 downto 0)
	);
end i2s_rec;

architecture Behavioral of i2s_rec is
	--Signals Declarations
	signal bclk_s: std_logic; --bit serial clock signal
	signal mclk_s: std_logic; --master clock signal
	signal CLKcount: integer range 0 to 55 := 0; -- Clock counter and divider 125MHz/1.152MHz = 108.5
	signal CLKcnt: integer range 0 to 6 := 0; -- Clock counter an divider 125MHz/12.288MHz = 10.17 
	signal b_cnt: integer range 0 to width := 0;-- received bit counter
	signal b_reg: std_logic_vector (width-1 downto 0); --received data vector
	
	
begin
	Frec_DividerBCLK: process(clk, rst) begin
		if (rst = '1') then
		--reset state
			bclk_s <= '0';
			CLKcount <= 0;
		elsif rising_edge(clk) then
			if (CLKcount = 53) then --supposed to be 54 but that generates 1.136MHz
				bclk_s <= not(bclk_s);
				CLKcount <= 0;
			else
				CLKcount <= CLKcount + 1;
			end if;
		end if;
	end process;
	
	Frec_DividerMCLK: process(clk, rst) begin
		if (rst = '1') then
		--reset state
			mclk_s <= '0';
			CLKcnt <= 0;
		elsif rising_edge(clk) then
			if (CLKcnt = 4) then --supposed to be 5 but that generates 10.416MHz
				mclk_s <= not(mclk_s);
				CLKcnt <= 0;
			else
				CLKcnt <= CLKcnt + 1;
			end if;
		end if;
	end process;
	
	Data_ret: process(bclk_s, rst) begin
		if (rst = '1') then
		--reset state
		elsif rising_edge(bclk_s) then
			if (b_cnt = width-1) then
				b_reg <= b_reg(width - 2 downto 0) & recdat; --Chapus!
				b_cnt <= 0;
				done <= '1';
			else
				b_reg <= b_reg(width - 2 downto 0) & recdat;
				b_cnt <= b_cnt + 1;
				done <= '0';
			end if;
		end if;
	end process;
	
	bclk <= bclk_s;
	mclk <= mclk_s;
	reclrc <= '0';
	mute <= '1';
	d_out <= b_reg;
end Behavioral;



