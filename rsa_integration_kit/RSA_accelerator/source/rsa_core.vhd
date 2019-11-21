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
		N_CORES               : integer := 2
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
    signal core_start, core_finish : std_logic_vector(N_CORES-1 downto 0);
    signal cores_done, cores_clear : std_logic_vector(N_CORES-1 downto 0);
    
    -- Data type and decleration for output data
    type core_data is array (N_CORES - 1 downto 0) of std_logic_vector(C_BLOCK_SIZE-1 downto 0);
    
    signal core_data_out : core_data; 
    
begin

    
		
generating: for i in 0 to (N_CORES-1) generate 
     exp: entity work.exponentiation
		generic map (
			C_block_size => C_BLOCK_SIZE
		)
		port map (
			message   => msgin_data,
			key       => mod_reg     ,
			busy      => cores_busy(i),
			start     => core_start(i),
			clear     => cores_clear(i),
			done      => cores_done(i),
			result    => core_data_out(i) ,
			modulus   => key_reg       ,
			clk       => clk         ,
			reset_n   => reset_n
		);
	end generate;
	   
    
    Input_fsm : process(Input_State, NIS) 
    
    begin        
        case Input_State is
            when IDLE =>
                if(valid_in = '1') then
                    NIS <= CHECK_CORES;
                else
                    NIS <= IDLE;
                end if;
            when CHECK_CORES =>
                if !cores_busy(core_start_counter) then 
                    core_start(core_start_counter) = '1';
                    current_core_nxt <= current_core + 1;
                else 
                    NIS => CHECK_CORES;
                end if; 
         end case;
     end process;
     
     Output_fsm : process(Output_State, NOS)
     
     begin
         case Output_State is 
            when MONITOR_CORE_OUTPUT =>
                if(core_done(core_finished_counter) = '1')
                    NOS <= WRITE DATA;
                else 
                    NOS <= MONITOR_CORE_OUTPUT;
                endif;
            when WRITE_DATA =>
                msgout_data <= core_data_out(core_finished_counter); -- Read data from core
                cores_clear(core_finished_counter) <= '1'; --Notify core that it can release data and move to idle.
                if(core_finished_counter >= (N_CORES-1) then
                    core_finished_counter_nxt <= (others => '0');
                else 
                    core_finished_counter_nxt <= core_finished_counter + 1;
                end if;
                NOS <= MONITOR_CORE_OUTPUT;
          end case 
                
    end process;
    
	msgout_last  <= msgin_last;
	rsa_status   <= (others => '0');
end rtl;
