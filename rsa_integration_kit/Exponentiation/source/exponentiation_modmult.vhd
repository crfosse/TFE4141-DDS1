----------------------------------------------------------------------------------
-- Company: NTNU
-- Engineer: Carl Richard Steen Fosse
-- 
-- Create Date: 10/31/2019 02:58:41 PM
-- Design Name: modular multiplier - blakley
-- Module Name: exponentiation_mult - expBehave
-- Project Name: RSA 
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

entity exponentiation_modmult is
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
end exponentiation_modmult;

architecture expBehave of exponentiation_modmult is

  -- Signals associated with the input registers
  signal a_r, a_nxt: std_logic_vector(255 downto 0);
  signal b_r, b_nxt: std_logic_vector(255 downto 0);
  
  -- Signals associated with the output registers
  signal y_r, y_nxt: std_logic_vector(255 downto 0);
  
  signal sum, sum_nxt: std_logic_vector(255 downto 0);
  
  signal shift_counter, shift_counter_nxt: unsigned(7 downto 0); --256 bit counter register
  
  type state_type is (INIT, MODCALC, MODCOMP, MODFIN, MODDONE);
  signal PS, NS : state_type;

begin   
    sync_state: process(clk, reset_n, NS)
        begin
            if(reset_n = '0') then 
                PS <= INIT;
            elsif (clk'event and clk='1') then 
                PS <= NS;
            end if;
    end process sync_state;             

    calc_ns: process (PS, start, sum, data_n_in, shift_counter) 
        begin
             case PS is
                when INIT =>                
                    if (start = '1') then                    
                        NS <= MODCALC;
                    else
                        NS <= INIT;
                    end if;
                 when MODCALC =>
                    NS <= MODCOMP;
                 when MODCOMP =>
                    if (sum >= data_n_in) then
                        NS <= MODCOMP;
                    else
                        NS <= MODFIN;
                    end if;                       
                 when MODFIN =>
                    if(shift_counter >= 255) then                     
                        NS <= INIT;
                    else
                        NS <= MODCALC;
                    end if;
                 when others =>
                    NS <= INIT;
             end case;
      end process calc_ns;
      
      sync_regs: process(clk, reset_n) is
      begin
      if(reset_n = '0') then
         a_r           <= (others => '0');
         b_r           <= (others => '0');
         y_r           <= (others => '0');
         sum           <= (others => '0');
         shift_counter <= (others => '0');
      elsif (clk'event and clk='1') then
         a_r           <= a_nxt;
         b_r           <= b_nxt;
         y_r           <= y_nxt;
         sum           <= sum_nxt;
         shift_counter <= shift_counter_nxt;  
      end if;
      
      end process sync_regs;
      
      comp_proc: process(data_a_in,data_b_in,a_r,b_r,y_r,sum,shift_counter,PS)
      
      variable a_tmp: std_logic_vector(255 downto 0);
      variable a_mult_b_res: std_logic_vector(255 downto 0);
      
      begin
      modmult_finished <= '0';
            case PS is
                when INIT =>
                    y_nxt             <= (others => '0'); --resetting result register
                    sum_nxt           <= (others => '0');
                    shift_counter_nxt <= (others => '0');
                    a_nxt             <= data_a_in;  
                    b_nxt             <= data_b_in;  
                when MODCALC =>
                    a_nxt <= a_r(254 downto 0) & a_r(255);
                    
                    a_tmp := (others => a_r(254));
                    a_mult_b_res:= a_tmp and data_b_in; 
                    
                    
                    sum_nxt <= std_logic_vector(shift_left(unsigned(y_r),1) + unsigned(a_mult_b_res));                    
                    b_nxt <= b_r;
                    y_nxt <= y_r;
                    shift_counter_nxt <= shift_counter;                    
                    
                 when MODCOMP =>

                    if (sum >= data_n_in) then
                       sum_nxt <= std_logic_vector(unsigned(sum) - unsigned(data_n_in));
                       y_nxt <= y_r;
                       shift_counter_nxt <= shift_counter;  
                    else 
                       sum_nxt <= sum;
                       y_nxt <= sum;
                       shift_counter_nxt <= shift_counter + 1;
                    end if;
                    
                    b_nxt <= b_r;
                    a_nxt <= a_r;                                            
                 when MODFIN =>
                    if(shift_counter >= 255) then                        
                        modmult_finished <= '1';
                    end if;
                    y_nxt             <= y_r; 
                    sum_nxt           <= sum;
                    shift_counter_nxt <= shift_counter;
                    a_nxt             <= a_r;  
                    b_nxt             <= b_r;      
                    
                   
                 when others =>
                    -- Move to idle state
                    y_nxt             <= (others => '0');
                    sum_nxt           <= (others => '0');
                    shift_counter_nxt <= (others => '0');
                    a_nxt             <= data_a_in;  
                    b_nxt             <= data_b_in;                   
             end case;      
      
      end process comp_proc;
      
      data_out <= y_r;  
end expBehave;
