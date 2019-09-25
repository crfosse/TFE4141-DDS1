----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2019 01:49:15 PM
-- Design Name: 
-- Module Name: test_bench - Behavioral
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
use ieee.std_logic_1164.all ;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity test_bench is 
end entity test_bench;

architecture test_sr of test_bench is 
    signal A,B,Q,QN : std_logic;
begin 
    DUT: entity work.SR_latch(behaviour)
        port map(A => A, B => B, Q => Q, QN => QN);

    stimulus: process is
    begin 
        A <= '1' ; B <= '0' ;
        wait for 10 ns ;
        A <= '0' ;
        wait for 10 ns ;
        B <= '1' ;
        wait for 10 ns ;
        B <= '0' ;
        wait for 10 ns ;
        B <= '1' ; A <= '1' ;
        wait for 50 ns ;
    end process stimulus;
end architecture test_sr;
