----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/13/2019 12:56:24 PM
-- Design Name: 
-- Module Name: latch - Behavioral
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


library ieee;
use ieee.std_logic_1164.all ;

entity SR_latch is
    port(
        A,B  : in std_logic; 
        Q,QN : inout std_logic
    );
end entity SR_latch;

architecture behaviour of SR_latch is 
begin 
    Q <= A nor QN;
    QN <= B nor Q;
end architecture behaviour;


