library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity exponentiation is
	generic (
		C_block_size : integer := 256
	);
	port (
		--input control
		valid_in	: in STD_LOGIC;
		ready_in	: out STD_LOGIC;

		--input data
		message 	: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
		key 		: in STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );

		--ouput control
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

    -- Signals associated with the input registers
  signal m_r, m_nxt: std_logic_vector(C_block_size downto 0);
  signal e_r, e_nxt: std_logic_vector(C_block_size downto 0);
  
  -- Signals associated with the output registers
  signal c_r, c_nxt: std_logic_vector(C_block_size downto 0);
  
  signal a_in, b_in: std_logic_vector(C_block_size downto 0);
  
  signal r, r_nxt: std_logic_vector(C_block_size downto 0);
  
  signal shift_counter_e, shift_counter_nxt: unsigned(7 downto 0); --256 bit counter register
  
  signal m_start, m_finished: std_logic;

  type state_type is (
    IDLE, 
    STORE_DATA_IN, 
    CHECK_E, 
    LOAD_CC,
    COMP_CC,
    LOAD_CM,
    COMP_CM,
    CHECK_FINISH);
  signal PS, NS : state_type;
begin

    calc_ns: process (PS, valid_in, e_i)
    begin
        case PS is 
           when IDLE => 
                if(valid_in = '1') then
                    NS <= CHECK_E;
                else
                    NS <= IDLE;
                end if;
           when CHECK_E =>
                NS <= LOAD_CC;
           when LOAD_CC =>
                m_start <= '1';
                NS <= COMP_CC;
           when COMP_CC =>
                if(m_finished = '1') then
                    if(e_i = '1') then
                        NS <= LOAD_CM;
                    else 
                        NS <= CHECK_FINISH;
                    end if;
                else
                    NS <= COMP_CC;
                end if;
           when LOAD_CM =>
                NS <= COMP_CM;
           when COMP_CM =>                  
               if(m_finished = '1') then
                        NS <= CHECK_FINISH;
                else
                    NS <= COMP_CC;
                end if;
           when CHECK_FINISH =>
                if(shift_counter_e = '0') then -- Finished 
                    NS <= IDLE;
                else 
                    NS => LOAD_CC;
                end if;       
        end case;        
    end process;
    
    
    comp_proc: process (PS, valid_in, e_i)
    
    begin
        case PS is 
           when IDLE => 
                if(valid_in = '1') then
                    ready_in <= '1';
                    m_nxt <= message;
                    e_nxt <= key;
                else
                    m_nxt <= m_r;
                    e_nxt <= e_r; 
                end if;
           when CHECK_E =>
                if (e_r(255) = '1') then
                    c_nxt <= m_r;
                else 
                    c_nxt <= (0=>'1',others =>'0');
                end if;
           when LOAD_CC =>
                m_start <= 1;
                a_in <= c_r;
                b_in <= c_r;                
           when COMP_CC =>
                if(m_finished = '1') then
                    if(e_i = '1') then
                        a_in <= c_r;
                        b_in <= m_r;
                        c_nxt <= m_out;
                    else 
                        a_in <= c_r;
                        b_in <= c_r;
                    end if;
                else
                    
                end if;
           when LOAD_CM =>
                m_start <= 1;
                NS <= COMP_CM;
           when COMP_CM =>                  
               if(m_finished = '1') then
                        NS <= CHECK_FINISH;
                else
                    NS <= COMP_CC;
                end if;
           when CHECK_FINISH =>
                if(shift_counter_e = '0') then -- Finished 
                    NS <= IDLE;
                    result_write <= 1;
                else 
                    NS => LOAD_CC;
                end if;       
        end case;        
    end process;
	result <= message xor modulus;
	ready_in <= ready_out;
	valid_out <= valid_in;
end expBehave;
