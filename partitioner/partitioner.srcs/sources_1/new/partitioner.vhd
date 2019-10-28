----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 23.10.2019 10:00:39
-- Design Name: 
-- Module Name: partitioner - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity partitioner is
    generic (
        REGISTER_WIDTH : natural := 256);
    Port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        pStart  : in  std_logic;
        e       : in  std_logic_vector(REGISTER_WIDTH-1 downto 0);
        e_i     : out std_logic);
end partitioner;

architecture Behavioral of partitioner is
    signal q : std_logic_vector(REGISTER_WIDTH-1 downto 0);
    signal load_e : std_logic;
    signal shift_e : std_logic;
    signal reset_count : std_logic;
    signal counter : unsigned(7 downto 0);
    
    type state_type is (idle, load, shift); 
    signal state_reg, state_next : state_type;
    
begin
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            q <= (others => '0');
        elsif (clk'event and clk = '1') then
            if (load_e = '1') then
                q <= e;
            elsif shift_e = '1' then
                e_i <= q(0);
                q <= '0' & q(REGISTER_WIDTH-1 downto 1);
            end if;
        end if;
    end process;


    process(clk, reset_n)
    begin
        if reset_n = '0' then
 	      state_reg <= idle;
	   elsif (clk'event and clk='1') then
	       state_reg <= state_next;
	   end if;
    end process;
    
    
    process(clk, reset_n)
    begin
        if (reset_n = '0' or reset_count = '1') then
            counter <= (others => '1');
        elsif (clk'event and clk = '1') then
            if shift_e = '1' then
                counter <= counter - 1;
            end if;
        end if;
    end process;
    
    
    process(state_reg) --More?
    begin
        state_next <= idle;
        load_e <= '0';
        shift_e <= '1';
        reset_count <= '0';
        case state_reg is
            when idle =>
                reset_count <= '1';
                if pStart='1' then 
                    state_next <= load;
                else
                    state_next <= idle;
                end if;
            when load =>
                state_next <= shift;
                load_e <= '1';
            when shift =>
                state_next <= shift;
                shift_e <= '1';
                if counter = 0 then
                    state_next <= load;
                end if;
        end case;
    end process;
end Behavioral;