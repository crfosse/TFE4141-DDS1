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
  signal m_r, m_nxt: std_logic_vector(C_block_size-1 downto 0);
  signal e_r, e_nxt: std_logic_vector(C_block_size-1 downto 0);
  
  -- Signals associated with the output registers
  signal c_r, c_nxt: std_logic_vector(C_block_size-1 downto 0);
  
  signal a_in, b_in: std_logic_vector(C_block_size-1 downto 0);
  
  signal r, r_nxt: std_logic_vector(C_block_size-1 downto 0);
  
  signal shift_counter, shift_counter_nxt: unsigned(7 downto 0); --256 bit counter register
  
  signal mult_start, mult_finished: std_logic;
  
  signal mult_in_a, mult_in_b, mult_out: std_logic_vector(C_block_size-1 downto 0);

  type state_type is (
    IDLE, 
    CHECK_E, 
    LOAD_CC,
    COMP_CC,
    LOAD_CM,
    COMP_CM,
    CHECK_FINISH);
  signal PS, NS : state_type;
begin

    i_modmult : entity work.exponentiation_modmult
        generic map (
            C_block_size => C_block_size
        )
        port map (
                
            -- Clocks and resets
            clk             => clk, 
            reset_n         => reset_n, 
            
            -- Control signals
            mult_start      => mult_start,
            mult_finished   => mult_finished,
            
            -- Data in interface       
            data_a_in         => mult_in_a, 
            data_b_in         => mult_in_b,          
            data_n_in         => modulus,
            
            -- Data out interface
            data_out          => mult_out
                
        );


    sync_state: process(clk, reset_n)
        begin
            if(reset_n = '0') then 
                PS <= IDLE;
            elsif (clk'event and clk='1') then 
                PS <= NS;
            end if;
    end process sync_state;   

    calc_ns: process (PS, valid_in, e_r, mult_finished, shift_counter, ready_out)
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
                NS <= COMP_CC;
           when COMP_CC =>
                if(mult_finished = '1') then
                    if(e_r(255) = '1') then
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
               if(mult_finished = '1') then
                    NS <= CHECK_FINISH;
                else
                    NS <= COMP_CM;
                end if;
           when CHECK_FINISH =>
                if(shift_counter >= (C_BLOCK_SIZE-2)) then -- Finished 
                    if(ready_out = '1') then 
                        NS <= IDLE;
                    else
                        NS <= CHECK_FINISH;
                    end if;
                else 
                    NS <= LOAD_CC;
                end if;   
            when others =>
                NS <= IDLE;    
        end case;        
    end process;
    
    sync_regs: process(clk, reset_n) is
      begin
      if(reset_n = '0') then
        m_r <= (others => '0');
        e_r <= (others => '0');  
        c_r <= (others => '0');  
        shift_counter <= (others => '0');
      elsif (clk'event and clk='1') then
         m_r           <= m_nxt;
         e_r           <= e_nxt;
         c_r           <= c_nxt;
         shift_counter <= shift_counter_nxt;
      end if;
    end process sync_regs;
    
    comp_proc: process (PS, valid_in, shift_counter, mult_finished, e_r, m_r, c_r, message, key, mult_out)
    
    begin
        valid_out  <= '0';
        ready_in   <= '0';
        mult_start <= '0';      
          
        m_nxt <= m_r;
        e_nxt <= e_r;  
        c_nxt <= c_r;  
        mult_in_a <= c_r;
        mult_in_b <= c_r;   
        shift_counter_nxt <= shift_counter;    
    
        case PS is 
           when IDLE => 
                shift_counter_nxt <= (others => '0');
                if(valid_in = '1') then
                    m_nxt <= message;
                    e_nxt <= key;
                end if;
           when CHECK_E =>
                ready_in <= '1'; --Data is loaded
                      
                e_nxt <= e_r(254 downto 0) & '0';
                
                if (e_r(255) = '1') then
                    c_nxt <= m_r;
                else 
                    c_nxt <= (0=>'1',others =>'0');
                end if;
                               
           when LOAD_CC =>
                mult_start <= '1';
                mult_in_a <= c_r;
                mult_in_b <= c_r;                
                          
           when COMP_CC =>
                if(mult_finished = '1') then
                    c_nxt <= mult_out;
                    
                    e_nxt <= e_r(254 downto 0) & '0';
                end if;
           when LOAD_CM =>
                mult_start <= '1';
                mult_in_a <= c_r;
                mult_in_b <= m_r; 
           when COMP_CM =>                  
               if(mult_finished = '1') then
                    c_nxt <= mult_out;
               end if;
           when CHECK_FINISH =>
           
                
                shift_counter_nxt <= shift_counter + 1;
           
                if(shift_counter >= (C_BLOCK_SIZE-2)) then -- Finished 
                    valid_out <= '1';
                end if; 
            when others =>
                m_nxt <= (others => '0');
                e_nxt <= (others => '0');  
                c_nxt <= (others => '0');  
                shift_counter_nxt <= (others => '0');
        end case;        
    end process;
    
    result <= c_r;
    
end expBehave;
