----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/08/2019 05:50:30 PM
-- Design Name: 
-- Module Name: tester - Behavioral
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

entity tester is
--  Port ( );
end tester;

architecture behavioral of tester is

  -- Data input interface   
  signal  data_a_in         : std_logic_vector (255 downto 0);
  signal  data_b_in         : std_logic_vector (255 downto 0);
  signal  data_n_in         : std_logic_vector (255 downto 0);
  signal  data_ex_in        : std_logic_vector (255 downto 0);
           
  -- Data output interface            
  signal data_out       : std_logic_vector (255 downto 0);

begin

  -- DUT instantiation
  dut: entity work.mod_mult 
    port map (
      data_a_in      => data_a_in,
      data_b_in      => data_b_in,
      data_n_in      => data_n_in,
      data_ex_in      => data_ex_in,
      data_out       => data_out
         
    );


  -- Stimuli generation
  stimuli_proc: process
  begin
  
    -- Send in first test vector
    data_a_in       <= (others =>'1');
    data_b_in       <= (others =>'1');
    data_n_in       <= (others =>'1');
    data_ex_in      <= (others =>'0');
    
    -- Wait for results
    wait;
  end process;  


end Behavioral;
