entity dff_reset_n is
  port (
    clk     : in  std_logic;
    reset_n : in  std_logic;
    d       : in  std_logic;
    q       : out std_logic);
end dff_reset_n;