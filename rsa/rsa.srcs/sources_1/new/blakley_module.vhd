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
use ieee.numeric_std.all;

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
    reg_load        : in std_logic;
    
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

    --Input registers

    process (clk, reset_n) begin
        if(reset_n = '0') then
          a_r <= (others => '0');
          b_r <= (others => '0');      
        elsif(clk'event and clk='1') then
            if(reg_load='1') then
                a_r <= data_a_in;
                b_r <= data_b_in;
            else 
                a_r <= a_r(254 downto 0) & '0';
            end if;        
          end if;
      end process;
      
    --Output register
      
  process (clk, reset_n) begin
    if(reset_n = '0') then
      y_r <= (others => '0');     
    elsif(clk'event and clk='1') then
        y_r <= y_nxt;       
      end if;
  end process;
      
      
      process (y_r, a_r, b_r) 
      
       variable a_tmp: std_logic_vector(255 downto 0);

      
      begin
      
      a_tmp := ((others => a_r(255)));
      
      
      
      y_nxt <= std_logic_vector(shift_left(unsigned(y_r),2) + unsigned(a_tmp and data_b_in));
    
      if (y_nxt >= data_n_in) then
        y_nxt <= std_logic_vector(unsigned(y_nxt) - unsigned(data_n_in));
        if(y_nxt >= (data_n_in)) then
            y_nxt <= std_logic_vector(unsigned(y_nxt) - unsigned(data_n_in));
        end if;
      end if;
       
      data_out <= y_nxt;
       
      end process;
end Behavioral;
