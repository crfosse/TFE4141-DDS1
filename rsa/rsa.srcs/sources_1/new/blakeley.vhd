----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/08/2019 02:38:24 PM
-- Design Name: 
-- Module Name: blakeley - Behavioral
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mod_mult is
  port (
    -- Clocks and resets
    clk             : in std_logic;
    reset_n         : in std_logic;
    
    -- Data in interface       
    data_a_in         : in std_logic_vector (255 downto 0);
    data_b_in         : in std_logic_vector (255 downto 0);          
    data_n_in         : in std_logic_vector (255 downto 0);
    
    -- Data out interface
    data_out        : out std_logic_vector (255 downto 0));
        
end mod_mult;

architecture rtl of mod_mult is

  -- Signals associated with the input registers
  signal a_r, a_nxt: std_logic_vector(255 downto 0);
  signal b_r, b_nxt: std_logic_vector(255 downto 0);
  
  -- Signals associated with the output registers
  signal y_r, y_nxt: std_logic_vector(255 downto 0);
    
begin

  -- ***************************************************************************
  -- Register a_r, b_r 
  -- ***************************************************************************  
  
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

end rtl;