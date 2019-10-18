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
  generic (
    COUNTER_WIDTH : natural := 8);  
  port (
    -- Clocks and resets
    clk             : in std_logic;
    reset_n         : in std_logic;
    
    -- Ctrl signals
    cnt_en  : in  std_logic;
    cnt_up  : in  std_logic;
    
    
    -- Data in interface       
    data_a_in         : in std_logic_vector (255 downto 0);
    data_b_in         : in std_logic_vector (255 downto 0);          
    data_n_in         : in std_logic_vector (255 downto 0);
    
    -- Data out interface
    data_out          : out std_logic_vector (255 downto 0);
    
    -- Clock output
    y       : out std_logic_vector(COUNTER_WIDTH-1 downto 0)
    );      
end mod_mult;

architecture rtl of mod_mult is
    
begin
    
  counter: entity work.up_down_counter
    port map(
    clk => clk, 
    reset_n => reset_n, 
    cnt_en => cnt_en, 
    cnt_up => cnt_up, 
    y => y);
    
  blakley: entity work.blakley_module
    port map(
        clk => clk,
        reset_n => reset_n,
        data_a_in => data_a_in,
        data_b_in => data_b_in,
        data_n_in => data_n_in,
        
        data_out => data_out
    
    );

end rtl;
