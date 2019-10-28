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
    
    -- Control in
    start           : in std_logic;
    
    -- Control out
    modmult_finished : out std_logic;
    
    
    -- Data in interface       
    data_a_in         : in std_logic_vector (255 downto 0);
    data_b_in         : in std_logic_vector (255 downto 0);          
    data_n_in         : in std_logic_vector (255 downto 0);
    
    -- Data out interface
    data_out          : out std_logic_vector (255 downto 0)
    );      
end mod_mult;

architecture rtl of mod_mult is
    
begin
    
  blakley: entity work.blakley_module
    port map(
        clk     => clk,
        reset_n => reset_n,
        start   => start,
        modmult_finished => modmult_finished,
        
        data_a_in => data_a_in,
        data_b_in => data_b_in,
        data_n_in => data_n_in,
        
        data_out => data_out
    
    );


end rtl;