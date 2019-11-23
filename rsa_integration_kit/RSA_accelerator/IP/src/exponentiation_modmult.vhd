----------------------------------------------------------------------------------
-- Company: NTNU
-- Engineer: Carl Richard Steen Fosse
-- 
-- Create Date: 10/31/2019 02:58:41 PM
-- Design Name: modular multiplier - blakley
-- Module Name: exponentiation_modmult - expBehave
-- Project Name: RSA 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
--  A Blakley modular multiplier.

----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY exponentiation_modmult IS
    GENERIC (
        C_block_size : INTEGER := 256

    );
    PORT (
        -- Clocks and resets
        clk : IN std_logic;
        reset_n : IN std_logic;
        mult_start : IN std_logic;

        -- Data in interface       
        data_a_in : IN std_logic_vector (C_block_size - 1 DOWNTO 0);
        data_b_in : IN std_logic_vector (C_block_size - 1 DOWNTO 0);
        data_n_in : IN std_logic_vector (C_block_size - 1 DOWNTO 0);

        -- Data out interface
        data_out : OUT std_logic_vector(C_block_size - 1 DOWNTO 0);
        mult_finished : OUT std_logic

    );
END exponentiation_modmult;

ARCHITECTURE expBehave OF exponentiation_modmult IS

    -- Signals associated with the input registers
    SIGNAL a_r, a_nxt : std_logic_vector(C_block_size - 1 DOWNTO 0);
    SIGNAL b_r, b_nxt : std_logic_vector(C_block_size - 1 DOWNTO 0);

    -- Signals associated with the output registers
    SIGNAL y_r, y_nxt : std_logic_vector(C_block_size DOWNTO 0); -- Overflow compansated

    -- Local signals for intermediate calculation and counting
    SIGNAL sum, sum_nxt : unsigned(C_block_size + 2 DOWNTO 0); --Overflow compansated
    SIGNAL shift_counter, shift_counter_nxt : unsigned(7 DOWNTO 0); --256 bit counter register

    TYPE state_type IS (INIT, MODCALC, MODCOMP, MODFIN);
    SIGNAL PS, NS : state_type;

BEGIN
    -- Clocked process for updating the state register  
    sync_state : PROCESS (clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            PS <= INIT;
        ELSIF (clk'event AND clk = '1') THEN
            PS <= NS;
        END IF;
    END PROCESS sync_state;

    -- Combinatorial process for calculating next state(NS)
    calc_ns : PROCESS (PS, mult_start, sum, data_n_in, shift_counter)
    BEGIN
        CASE PS IS
            WHEN INIT =>
                IF (mult_start = '1') THEN
                    NS <= MODCALC;
                ELSE
                    NS <= INIT;
                END IF;
            WHEN MODCALC =>
                NS <= MODCOMP;
            WHEN MODCOMP =>
                -- Check if current result is bigger than n, if so 
                -- subtract. 
                IF (sum >= (b"000" & unsigned(data_n_in))) THEN
                    NS <= MODCOMP;
                ELSE
                    NS <= MODFIN;
                END IF;
            WHEN MODFIN =>
                -- Finished when we have shifted through 256 bits. 
                IF (shift_counter >= C_BLOCK_SIZE - 1) THEN
                    NS <= INIT;
                ELSE
                    NS <= MODCALC;
                END IF;
            WHEN OTHERS =>
                NS <= INIT;
        END CASE;
    END PROCESS calc_ns;

    -- Clocked process for updating the different registers
    sync_regs : PROCESS (clk, reset_n) IS
    BEGIN
        IF (reset_n = '0') THEN
            a_r <= (OTHERS => '0');
            b_r <= (OTHERS => '0');
            y_r <= (OTHERS => '0');
            sum <= (OTHERS => '0');
            shift_counter <= (OTHERS => '0');
        ELSIF (clk'event AND clk = '1') THEN
            a_r <= a_nxt;
            b_r <= b_nxt;
            y_r <= y_nxt;
            sum <= sum_nxt;
            shift_counter <= shift_counter_nxt;
        END IF;

    END PROCESS sync_regs;

    -- Combinatorial process for calculations
    comp_proc : PROCESS (data_a_in, data_b_in, data_n_in, a_r, b_r, y_r, sum, shift_counter, PS)

        VARIABLE a_tmp : std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        VARIABLE a_mult_b_res : std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        VARIABLE sum_geq : unsigned(C_BLOCK_SIZE + 2 DOWNTO 0);

    BEGIN
        mult_finished <= '0';

        a_nxt <= a_r;
        b_nxt <= b_r;
        sum_nxt <= sum;
        y_nxt <= y_r;
        shift_counter_nxt <= shift_counter;
        CASE PS IS
            WHEN INIT =>
                y_nxt <= (OTHERS => '0'); --resetting result register
                sum_nxt <= (OTHERS => '0');
                shift_counter_nxt <= (OTHERS => '0');
                a_nxt <= data_a_in;
                b_nxt <= data_b_in;
            WHEN MODCALC =>
                a_nxt <= a_r(C_BLOCK_SIZE - 2 DOWNTO 0) & '0';

                a_tmp := (OTHERS => a_r(C_BLOCK_SIZE - 1));
                a_mult_b_res := a_tmp AND b_r;
                sum_nxt <= (b"00" & shift_left(unsigned(y_r), 1)) + (b"000" & unsigned(a_mult_b_res));

            WHEN MODCOMP =>
                sum_geq := (b"000" & unsigned(data_n_in));
                IF (sum >= sum_geq) THEN
                    sum_nxt <= sum - (sum_geq);
                ELSE
                    y_nxt <= std_logic_vector(sum(C_BLOCK_SIZE DOWNTO 0));
                END IF;
            WHEN MODFIN =>

                shift_counter_nxt <= shift_counter + 1;

                IF (shift_counter >= C_block_size - 1) THEN
                    mult_finished <= '1';
                END IF;

            WHEN OTHERS =>
                -- Move to idle state
                y_nxt <= (OTHERS => '0');
                sum_nxt <= (OTHERS => '0');
                shift_counter_nxt <= (OTHERS => '0');
                a_nxt <= data_a_in;
                b_nxt <= data_b_in;
        END CASE;

    END PROCESS comp_proc;

    data_out <= y_r(C_BLOCK_SIZE - 1 DOWNTO 0);
END expBehave;