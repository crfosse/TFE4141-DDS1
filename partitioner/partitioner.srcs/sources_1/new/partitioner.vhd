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
        e_i     : inout std_logic);
end partitioner;

architecture Behavioral of partitioner is
    signal q : std_logic_vector(REGISTER_WIDTH-1 downto 0);
    signal load_e : std_logic;
    signal shift_e : std_logic;
    signal reset_count : std_logic;
    signal counter : unsigned(7 downto 0);
    signal wordcounter : unsigned(1 downto 0);
    signal word : std_logic_vector(3 downto 0);
    signal write : std_logic; --Protected name "write". Must be changed
    signal read : std_logic;  --Protected name "read". Must be changed
    signal addr : std_logic_vector(5 downto 0);
    signal read_addr : std_logic_vector(5 downto 0);
    signal memory_out : std_logic_vector(word'length + counter'length downto 0);
    signal inc_addr : std_logic;
        
    type ram_type is array (0 to (2**addr'length)-1) of std_logic_vector(word'length + counter'length downto 0);
    signal ram : ram_type;
    
    type state_type is (idle, load, shift); 
    signal state_reg, state_next : state_type;
    
    type state_type2 is (idle, zero, nzero);
    signal state_reg2, state_next2 : state_type2;
    
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
    
    process(clk, reset_n)
    begin
        if reset_n = '0' then
 	      state_reg2 <= idle;
	   elsif (clk'event and clk='1') then
	       state_reg2 <= state_next2;
	   end if;
    end process;
    
    process(state_reg2) --More?
    begin
        state_next2 <= idle;
        wordcounter <= (others => '0');
        case state_reg2 is
            when idle =>
                if pStart='1' then
                    if e_i = '0' then
                        state_next2 <= zero;
                    else
                        state_next2 <= nzero;
                        word <= x"000" & e_i;
                    end if;
                else
                    state_next2 <= idle;
                end if;
            when zero =>
                if e_i = '0' then
                    state_next2 <= zero;
                else
                    state_next2 <= nzero;
                    word <= x"000" & e_i;
                end if;
            when nzero =>
                if wordcounter = 3 then
                    if e_i = '0' then
                        state_next2 <= zero;
                    else
                        state_next2 <= nzero;
                    end if;
                end if;
                word <= word(2 downto 0) & e_i;
        end case;
    end process;
    
    RamProc: process(clk) is
    begin
        if (clk'event and clk='1') then
            if write = '1' then
                ram(to_integer(unsigned(addr))) <= word & std_logic_vector(counter);
            end if;
            read_addr <= addr;
        end if;
    end process RamProc;
    
    memory_out <= ram(to_integer(unsigned(read_addr)));
    
    process(load_e, inc_addr) is
    begin
        if load_e = '1' then
 	      addr <= (others => '0');
 	    elsif inc_addr = '1' then
 	      addr <= std_logic_vector(unsigned(addr) + 1);
 	    end if;    
    end process;
    
end Behavioral;