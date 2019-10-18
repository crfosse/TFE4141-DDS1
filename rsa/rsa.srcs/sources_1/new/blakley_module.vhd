----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/17/2019 05:24:55 PM
-- Design Name: 
-- Module Name: blakley_module - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
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
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity blakley_module is
  port (
    -- Clocks and resets
    clk             : in std_logic;
    reset_n         : in std_logic;
    
    -- Data in interface       
    data_a_in         : in std_logic_vector (255 downto 0);
    data_b_in         : in std_logic_vector (255 downto 0);          
    data_n_in         : in std_logic_vector (255 downto 0);
    
    -- Data out interface
    data_out          : out std_logic_vector (255 downto 0)
    
   );      
end blakley_module;

architecture Behavioral of blakley_module is

  -- Signals associated with the input registers
  signal a_r, a_nxt: std_logic_vector(255 downto 0);
  signal b_r, b_nxt: std_logic_vector(255 downto 0);
  
  -- Signals associated with the output registers
  signal y_r, y_nxt: std_logic_vector(255 downto 0);

begin
    process (clk, reset_n) begin
        if(reset_n = '0') then
          a_r <= (others => '0');
          b_r <= (others => '0');      
        elsif(clk'event and clk='1') then
          if(input_reg_en ='1') then
            a_r <= a_nxt;
            b_r <= b_nxt;        
          end if;
        end if;
      end process;
      
       process (data_in, a_r, b_r) begin
        a_nxt <= data_in;
        b_nxt <= a_r;
      end process; 
      
      process (data_a_in, data_b_in, data_n_in, data_ex_in)
      
        variable res : unsigned(255 downto 0);
      
      begin
      
      res := shift_left(unsigned(data_ex_in),2) + unsigned((data_a_in and data_b_in));
    
      if (res >= unsigned(data_n_in)) then
        res := res - unsigned(data_n_in);
        if(res >= unsigned(data_n_in)) then
            res := res - unsigned(data_n_in);
        end if;
      end if;
       
      data_out <= std_logic_vector(res);
       
      end process;
end Behavioral;
