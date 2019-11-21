--------------------------------------------------------------------------------
-- Author       : Oystein Gjermundnes
-- Organization : Norwegian University of Science and Technology (NTNU)
--                Department of Electronic Systems
--                https://www.ntnu.edu/ies
-- Course       : TFE4141 Design of digital systems 1 (DDS1)
-- Year         : 2018-2019
-- Project      : RSA accelerator
-- License      : This is free and unencumbered software released into the
--                public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Purpose:
--   RSA encryption core template. This core currently computes
--   C = M xor key_n
--
--   Replace/change this module so that it implements the function
--   C = M**key_e mod key_n.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity rsa_core is
	generic (
		-- Users to add parameters here
		C_BLOCK_SIZE          : integer := 256;
		N_CORES               : integer := 20
	);
	port (
		-----------------------------------------------------------------------------
		-- Clocks and reset
		-----------------------------------------------------------------------------
		clk                    :  in std_logic;
		reset_n                :  in std_logic;

		-----------------------------------------------------------------------------
		-- Slave msgin interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgin_valid             : in std_logic;
		-- Slave ready to accept a new message
		msgin_ready             : out std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgin_data              :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgin_last              :  in std_logic;

		-----------------------------------------------------------------------------
		-- Master msgout interface
		-----------------------------------------------------------------------------
		-- Message that will be sent out is valid
		msgout_valid            : out std_logic;
		-- Slave ready to accept a new message
		msgout_ready            :  in std_logic;
		-- Message that will be sent out of the rsa_msgin module
		msgout_data             : out std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		-- Indicates boundary of last packet
		msgout_last             : out std_logic;

		-----------------------------------------------------------------------------
		-- Interface to the register block
		-----------------------------------------------------------------------------
		key_e_d                 :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		key_n                   :  in std_logic_vector(C_BLOCK_SIZE-1 downto 0);
		rsa_status              : out std_logic_vector(31 downto 0)

	);
end rsa_core;

architecture rtl of rsa_core is

    signal mod_reg, key_reg : std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    signal next_to_start, next_to_finish : integer range 0 to N_CORES-1;
    signal next_to_start_nxt, next_to_finish_nxt : integer range 0 to N_CORES-1;
    
    signal cores_done, cores_clear, cores_start, cores_busy : std_logic_vector(N_CORES-1 downto 0);
    signal cores_done_nxt, cores_clear_nxt, cores_start_nxt, cores_busy_nxt : std_logic_vector(N_CORES-1 downto 0);
    signal core_flag_out : std_logic_vector(N_CORES-1 downto 0);

    
    -- Data type and decleration for output data
    type core_data is array (N_CORES - 1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    signal core_data_out : core_data; 
    
      type state_type_input is (
        IDLE, 
        CHECK_CORES,
        WAIT_FOR_CORE_START);
      signal Input_State, NIS : state_type_input;  
      
      type state_type_output is (
        MONITOR_CORE_OUTPUT,
        WRITE_DATA);
      signal Output_State, NOS : state_type_output;
          
begin

load_keys: process(clk, reset_n)
    begin
      if(reset_n = '0') then
        mod_reg    <= (others => '0');  
        key_reg    <= (others => '0');          
      elsif (clk'event and clk='1') then
            mod_reg    <= key_n;  
            key_reg    <= key_e_d;   
      end if;
    end process;
    
		
generating: for i in 0 to (N_CORES-1) generate 
     exp: entity work.exponentiation
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			message   => msgin_data,
			key       => key_reg     ,
			busy      => cores_busy(i),
			start     => cores_start(i),
			clear     => cores_clear(i),
			done      => cores_done(i),
			result    => core_data_out(i) ,
			modulus   => mod_reg       ,
			flag_in   => msgin_last,
			flag_out  => core_flag_out(i),
			clk       => clk         ,
			reset_n   => reset_n
		);
	end generate;
	   
    Sync_input: process(clk, reset_n) 
     begin
      if(reset_n = '0') then
        cores_start    <= (others => '0');  
        next_to_start  <= 0;          
        Input_State    <= IDLE;
      elsif (clk'event and clk='1') then
        cores_start    <= cores_start_nxt;  
        next_to_start  <= next_to_start_nxt;
        Input_State    <= NIS;
      end if;

     end process;
     
    
    Input_fsm : process(Input_State, NIS, msgin_valid, cores_busy) 
   
    begin  
        
        msgin_ready <= '0';
        
        cores_start_nxt <= (others => '0');
        next_to_start_nxt <= next_to_start;
             
        case Input_State is
            when IDLE =>
                if(msgin_valid = '1') then
                    NIS <= CHECK_CORES;
                else
                    NIS <= IDLE;
                end if;
            when CHECK_CORES =>
                if (not (cores_busy(next_to_start)='1')) then 
                    cores_start_nxt(next_to_start) <= '1';
                    if(next_to_start >= (N_CORES-1)) then
                        next_to_start_nxt <= 0;
                    else 
                        next_to_start_nxt <= next_to_start + 1;
                    end if;
                    
                    NIS <= WAIT_FOR_CORE_START;
                else 
                    NIS <= CHECK_CORES;
                end if; 
            when WAIT_FOR_CORE_START =>
                msgin_ready <= '1';
                NIS <= IDLE;
            when others =>
                NIS <= IDLE;
         end case;
     end process;
     
     Sync_output: process(clk, reset_n) 
     begin
      if(reset_n = '0') then
        cores_clear    <= (others => '0');  
        next_to_finish <= 0;  
        Output_State <= MONITOR_CORE_OUTPUT;
      elsif (clk'event and clk='1') then
        cores_clear    <= cores_clear_nxt;  
        next_to_finish <= next_to_finish_nxt;
        Output_State   <= NOS;
      end if;

     end process;
     
     Output_fsm : process(Output_State, NOS, next_to_finish, cores_done, msgout_ready)
     
     begin
        msgout_data <= (others => '0');
        msgout_valid <= '0';    
        msgout_last <= '0';
        
        cores_clear_nxt <= (others => '0');
        next_to_finish_nxt <= next_to_finish;
        
        case Output_State is 
            when MONITOR_CORE_OUTPUT =>
                if((cores_done(next_to_finish) = '1')) then
                    NOS <= WRITE_DATA;
                else 
                    NOS <= MONITOR_CORE_OUTPUT;
                end if;
            when WRITE_DATA =>                
                if(msgout_ready = '1') then 
                    msgout_data <= core_data_out(next_to_finish); -- Read data from core
                    cores_clear_nxt(next_to_finish) <= '1'; --Notify core that it can release data and move to idle.
                    msgout_last <= core_flag_out(next_to_finish);
                    msgout_valid <= '1';
                    if(next_to_finish >= (N_CORES-1)) then
                        next_to_finish_nxt <= 0;
                    else 
                        next_to_finish_nxt <= next_to_finish + 1;
                    end if;
                    NOS <= MONITOR_CORE_OUTPUT;
                else
                    NOS <= WRITE_DATA;
                end if;
             when others =>
                NOS <= MONITOR_CORE_OUTPUT;
          end case; 
                
    end process;
    
	rsa_status   <= (others => '0');
end rtl;
