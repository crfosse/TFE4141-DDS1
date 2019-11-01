----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 28.10.2019 18:55:01
-- Design Name: 
-- Module Name: power_memory - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


entity power_memory is
generic(
    address_length: natural := 64;
    data_length: natural := 256
);
    Port ( ReadEnable : in STD_LOGIC;
           WriteEnable : in STD_LOGIC;
           Address : in STD_LOGIC_VECTOR((address_length-1) downto 0);
           Data : inout STD_LOGIC_VECTOR((data_length-1) downto 0); 
           RAM_clk : in STD_LOGIC);
end power_memory;

architecture Behavioral of power_memory is
    type ram_type is array (0 to (2**(address_length)-1)) of std_logic_vector((data_length - 1) downto 0);
    signal ram: ram_type;

begin
process(RAM_clk) is
begin
    if rising_edge(RAM_clk) then
        if(ReadEnable= '1') then
            Data <= ram(conv_integer(unsigned(Address)));
        elsif (WriteEnable = '1') then
            ram(conv_integer(unsigned(Address))) <= Data;
        end if;
    end if;
end process;

end Behavioral;
