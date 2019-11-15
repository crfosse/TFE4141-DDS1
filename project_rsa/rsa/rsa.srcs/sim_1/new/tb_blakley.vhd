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
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity tb_blakley is
--  Port ( );
end tb_blakley;

architecture behavioral of tb_blakley is

      -- Constants
  --constant COUNTER_WIDTH : natural := 8;
    constant CLK_PERIOD    : time := 10 ns;
  --constant RESET_TIME    : time := 100 ns;

    signal clk              :  std_logic := '0';
    signal reset_n          :  std_logic := '0';
    
    -- Control in
    signal start            :  std_logic := '0';
    
    -- Control out
    signal modmult_finished :  std_logic := '0';    
    
    -- Data in interface       
    signal data_a_in         :  std_logic_vector (255 downto 0);
    signal data_b_in         :  std_logic_vector (255 downto 0);          
    signal data_n_in         :  std_logic_vector (255 downto 0);
    
    -- Data out interface
    signal data_out          :  std_logic_vector (255 downto 0);
    
begin

  -- DUT instantiation
  dut: entity work.mod_mult 
    port map (
       clk              => clk,
       reset_n          => reset_n,
       mult_start            => start,
       mult_finished => modmult_finished,
    
    
      data_a_in      => data_a_in,
      data_b_in      => data_b_in,
      data_n_in      => data_n_in,
      data_out       => data_out
         
    );

  -- Clock generation
  clk <= not clk after CLK_PERIOD/2;
  
    -- Reset generation
  reset_proc: process
  begin
    wait for CLK_PERIOD;
    reset_n <= '1';
    wait;
  end process;
  
  -- Stimuli generation
  stimuli_proc: process
  begin
  
    -- Send in first test vector
    wait for 5*CLK_PERIOD;
    start           <= '1';
    data_a_in       <= x"80f0a0ec4c0247ab0ca6c63c0f54d372cb120ebb893035c750c37b1971a7734d";
    data_b_in       <= x"0a23232323232323232323232323232323232323232323232323232323232323";
    data_n_in       <= x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
    -- Wait for results
    wait;
  end process;  


end Behavioral;
