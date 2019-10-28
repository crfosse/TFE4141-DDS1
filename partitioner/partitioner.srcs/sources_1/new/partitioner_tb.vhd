----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2019 14:13:31
-- Design Name: 
-- Module Name: partitioner_tb - Behavioral
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

entity partitioner_tb is
end partitioner_tb;

architecture simulate of partitioner_tb is
    component partitioner
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        pStart  : in  std_logic;
        e       : in  std_logic_vector(255 downto 0);
        e_i     : out std_logic);
    end component;

    constant CLK_PERIOD : time := 100ns;
    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal pStart : std_logic;
    signal e : std_logic_vector(255 downto 0);
    signal e_i : std_logic;

begin
uut: partitioner
port map (
    clk => clk,
    reset_n => reset_n,
    pStart => pStart,
    e => e,
    e_i => e_i);
    
clk <= not clk after CLK_PERIOD/2;

reset : process
begin
    wait for CLK_PERIOD;
    reset_n <= '1';
    wait;
end process;

stimulus: process
    begin
        wait for 5*CLK_PERIOD;
    
        e <= (  0 => '1',
                1 => '1',
                others => '0');
        pStart <= '1';
    
    wait;
    end process; -- stimulus

end simulate;
