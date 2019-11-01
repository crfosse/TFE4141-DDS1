----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2019 04:04:14 PM
-- Design Name: 
-- Module Name: inferring_latch - Behavioral
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

entity inferring_latch is
  Port (
    in1, in2 : in std_logic;
    out1 : out std_logic
  );
end inferring_latch;

architecture Behavioral of inferring_latch is
begin
    process(in1, in2)
    begin    
        if (in1=in2) then
            out1 <= '1';
        end if;
    end process;
end Behavioral;
