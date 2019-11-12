library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;


entity exponentiation_tb is
	generic (
		C_block_size : integer := 256
	);
end exponentiation_tb;


architecture expBehave of exponentiation_tb is
    
    constant CLK_PERIOD  : time := 10 ns;


	signal message 		: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal key 			: STD_LOGIC_VECTOR ( C_block_size-1 downto 0 );
	signal valid_in 	: STD_LOGIC;
	signal ready_in 	: STD_LOGIC;
	signal ready_out 	: STD_LOGIC := '1';
	signal valid_out 	: STD_LOGIC;
	signal result 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal modulus 		: STD_LOGIC_VECTOR(C_block_size-1 downto 0);
	signal clk 			: STD_LOGIC := '0';
	signal restart 		: STD_LOGIC;
	signal reset_n 		: STD_LOGIC;

begin
	i_exponentiation : entity work.exponentiation
		port map (
			message   => message  ,
			key       => key      ,
			valid_in  => valid_in ,
			ready_in  => ready_in ,
			ready_out => ready_out,
			valid_out => valid_out,
			result    => result   ,
			modulus   => modulus  ,
			clk       => clk      ,
			reset_n   => reset_n
		);

  -- Clock generation
  clk <= not clk after CLK_PERIOD/2;
  
  -- Reset generation
  reset_proc: process
  begin
    wait for CLK_PERIOD;
    reset_n <= '1';
    wait;
  end process;  
  
  stimuli_proc: process
  begin
  
    -- Send in first test vector
    wait for 5*CLK_PERIOD;
    valid_in        <= '1';
    message         <= (0      =>'1',
                        1      =>'1',  
                        2      =>'0',  
                        others =>'0');
    key             <= (0      =>'1',
                        1      =>'1',  
                        2      =>'0',  
                        others =>'0');
    modulus         <= (0      =>'1',
                        1      =>'1',  
                        2      =>'1',  
                        3      =>'1',
                        others =>'0');
    wait for 5*CLK_PERIOD;
   end process;

end expBehave;
