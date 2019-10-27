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
    start           : in std_logic;
    
    modmult_finished : out std_logic;
    
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
  
  signal a_test: std_logic;
  
  -- Signals associated with the output registers
  signal y_r, y_nxt: std_logic_vector(255 downto 0);
  
  signal sum: std_logic_vector(255 downto 0);
  
  signal shift_counter: unsigned(7 downto 0); --256 bit counter register
  
  type state_type is (INIT, MODCALC, MODCOMP, MODFIN, MODDONE);
  signal PS : state_type;

begin

    process (clk, reset_n) 
    
    variable a_tmp: std_logic_vector(255 downto 0);
    
    begin
        modmult_finished <= '0';
        
        if(reset_n = '0') then
          a_r <= (others => '0'); 
          y_r <= (others => '0');         
          shift_counter <= (others => '0');
        elsif(clk'event and clk='1') then
            case PS is
                when INIT =>
                    y_r <= (others => '0'); --resetting result register
                    a_r <= data_a_in;                    
                    if (start = '1') then
                        PS <= MODCALC;
                    end if;
                when MODCALC =>
                    a_r <= a_r(254 downto 0) & '0';
                    a_tmp := (others => a_r(255));
                    sum <= std_logic_vector(shift_left(unsigned(y_r),1) + unsigned(a_tmp and data_b_in));      
                    
                    PS <= MODCOMP;
                 when MODCOMP =>
                    if (sum >= data_n_in) then
                       sum <= std_logic_vector(unsigned(sum) - unsigned(data_n_in));
                    else 
                        y_nxt <= sum;
                        shift_counter <= shift_counter + 1;
                        PS <= MODFIN;
                    end if;                       
                 when MODFIN =>
                    y_r <= y_nxt;
                    if(shift_counter >= 255) then
                        data_out <= y_nxt;
                        modmult_finished <= '1';
                        shift_counter <= (others => '0');
                        PS <= INIT;
                    else
                        PS <= MODCALC;
                    end if;
                 when others =>
                    PS <= INIT;
             end case;
        end if;
      end process;
end Behavioral;
