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
	signal start    	: STD_LOGIC;
	signal busy     	: STD_LOGIC;
	signal clear    	: STD_LOGIC := '1';
	signal done     	: STD_LOGIC;
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
			start     => start ,
			busy      => busy ,
			clear     => clear,
			done      => done,
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
    start        <= '1';
   /*message         <=  (0      =>'1',
                        1      =>'1',
                        2      =>'0',
                        3      =>'1',
                        others =>'0');
    key             <= (0      =>'1',
                        1      =>'0',  
                        2      =>'1',
                        3      =>'0',
                        4      =>'1',  
                        others =>'0');
    modulus         <= (0      =>'0',
                        1      =>'1',  
                        2      =>'1',  
                        3      =>'1',
                        4      =>'1',
                        6      =>'1',
                        7      =>'1',
                        8      =>'1',
                        9      =>'1',
                        10      =>'1',
                        others =>'0');*/

    message         <= x"0a232020207478742e6e695f307470203a2020202020202020202020454d414e";
    key             <= x"0000000000000000000000000000000000000000000000000000000000010001";
    modulus         <= x"99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d";
    
    
   end process;

end expBehave;
