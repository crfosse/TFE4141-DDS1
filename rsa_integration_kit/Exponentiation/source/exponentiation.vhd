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
	
	signal start_exp : in STD_LOGIC();


begin
	exp_fsm: process (PS, start_exp)
		begin
			case PS is 
				m_start <= '0';
				p_start <= '0';
				when IDLE
					
			            if start_exp = '1' then
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

					NS <= PRECOMPUTE_COMPUTE;
				when PRECOMPUTE_MODMULT =>
					-- Start modular multiplier. If it's finished, set C on the output. 
					m_start <= '1'; --
					if(m_finished) then
						-- Increment counter
						-- Set PMEM[counter1] = R(Current result)
						-- Load A
						NS <= CHECK_POWER;
					else 
						NS <= PRECOMPUTE;
				        end if;
				when PRECOMPUTE_CHECK_POWER =>
					-- Check if the counter1 equals 2^(d-1)-1. (we can also increment counter1 by 2, but I don't know if wheter that is smart or not)
					-- We can always check this maybe? 
					if(equal = '1') then
						if(p_finished) then
							NS<=EXP_START;
							read_partitioner <= 1;
						end if;
					else
						NS <= PRECOMPUTE_MOD_MULT;
					end if;
				when EXP_READ_PARTITIONER =>
					read_power_memory <=1;
					counter1 <= word.value; -- The value of the current word
					counter2 <= word.length; -- The length of the current word(applicable if zero word) 
				when EXP_CHECK_COUNTERS =>
					-- LOAD A
					-- LOAD B
					if(zero_counter_2 = '0') then 
						NS => EXP_LD_ONLY_B;
					end if;
					if(zero_partitioner = '0') then
						NS => EXP_FINISHED;
					end if;
					


				 	 
					    
						
			end case;

	end exp_fsm;

	result <= message xor modulus;
	ready_in <= ready_out;
	valid_out <= valid_in;
end expBehave;
