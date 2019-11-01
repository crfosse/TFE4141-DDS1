library ieee;
use ieee.std_logic_1164.all;

entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input controll
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput controll
		ready_out	: in STD_LOGIC;
		valid_out	: out STD_LOGIC;

		--output data
		result 		: out STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--modulus
		modulus 	: in STD_LOGIC_VECTOR(C_block_size-1 downto 0);

		--utility
		clk 		: in STD_LOGIC;
		reset_n 	: in STD_LOGIC
	);
end exponentiation;


architecture expBehave of exponentiation is
begin
	
	exp_fsm: process ()
		begin
			case PS is 
				when IDLE

					if start = '1' then
							NS <= PRECOMPUTE_INIT;
				    end if;

				when PRECOMPUTE_INIT =>
					-- Initialize and start/reset partitioner and counters.
					-- Ensure that neccesary signals(p_start, counter1=0) is set.
					-- 
					
					--Conditons for further next state?
					NS <= PRECOMUTE_LD;
				when PRECOMPUTE_LD =>
					-- Load registers with message(chosen with a mux)
					-- Set PMEM[counter1] = M (initial message)

				    -- Conditions for ensuring this is finished?
				when PRECOMPUTE =>
					-- Start modular multiplier. If it's finished, set C on the output. 
			end case;

	end exp_fsm;



	result <= message xor modulus;
	ready_in <= ready_out;
	valid_out <= valid_in;
end expBehave;
