----------------------------------------------------------------------------------
-- Company: NTNU
-- Engineer: Carl Richard Steen Fosse
-- 
-- Create Date: 10/31/2019 02:58:41 PM
-- Design Name: modular exponentiator - binary
-- Module Name: exponentiation - expBehave
-- Project Name: RSA 
-- Target Devices: PYNQ-Z1
-- Description: 
--  an implementation of the binary modular exponentiation algorithm, using a 
--  Blakley modular multiplier for the computations.
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY exponentiation IS
    GENERIC (
        C_block_size : INTEGER := 256
    );
    PORT (
        --input control
        start : IN STD_LOGIC;
        busy : OUT STD_LOGIC;

        --input data
        message : IN STD_LOGIC_VECTOR (C_block_size - 1 DOWNTO 0);
        key : IN STD_LOGIC_VECTOR (C_block_size - 1 DOWNTO 0);

        ---
        -- flags --
        -- Used to make sure that the current msgin_last follows it's
        -- respective message, so that msgout_last is determined
        -- correctly.
        ---
        flag_in : IN STD_LOGIC;
        flag_out : OUT STD_LOGIC;

        --ouput control
        clear : IN STD_LOGIC;
        done : OUT STD_LOGIC;

        --output data
        result : OUT STD_LOGIC_VECTOR(C_block_size - 1 DOWNTO 0);

        --modulus
        modulus : IN STD_LOGIC_VECTOR(C_block_size - 1 DOWNTO 0);

        --utility
        clk : IN STD_LOGIC;
        reset_n : IN STD_LOGIC
    );
END exponentiation;
ARCHITECTURE expBehave OF exponentiation IS

    -- Signals associated with the input registers
    SIGNAL m_r, m_nxt : std_logic_vector(C_block_size - 1 DOWNTO 0);
    SIGNAL e_r, e_nxt : std_logic_vector(C_block_size - 1 DOWNTO 0);

    -- Signals associated with the output registers
    SIGNAL c_r, c_nxt : std_logic_vector(C_block_size - 1 DOWNTO 0);
    SIGNAL flag_reg, flag_reg_nxt : STD_LOGIC;

    -- Local signals for control and handling of modular multiplier
    SIGNAL shift_counter, shift_counter_nxt : unsigned(7 DOWNTO 0); --256 bit counter register
    SIGNAL mult_start, mult_finished : std_logic;
    SIGNAL mult_in_a, mult_in_b, mult_out : std_logic_vector(C_block_size - 1 DOWNTO 0);

    -- Type definition for FSM. (CC) computes C*C mod n, (CM) computes C*M mod n.
    TYPE state_type IS (
        IDLE,
        CHECK_E,
        LOAD_CC,
        COMP_CC,
        LOAD_CM,
        COMP_CM,
        CHECK_FINISH);
    SIGNAL PS, NS : state_type;
BEGIN

    i_modmult : ENTITY work.exponentiation_modmult
        GENERIC MAP(
            C_block_size => C_block_size
        )
        PORT MAP(

            -- Clocks and resets
            clk => clk,
            reset_n => reset_n,

            -- Control signals
            mult_start => mult_start,
            mult_finished => mult_finished,

            -- Data in interface       
            data_a_in => mult_in_a,
            data_b_in => mult_in_b,
            data_n_in => modulus,

            -- Data out interface
            data_out => mult_out

        );

    -- Clocked process for updating the state register
    sync_state : PROCESS (clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            PS <= IDLE;
        ELSIF (clk'event AND clk = '1') THEN
            PS <= NS;
        END IF;
    END PROCESS sync_state;

    -- Determination of next state(NS)
    calc_ns : PROCESS (PS, start, e_r, mult_finished, shift_counter, clear)
    BEGIN
        CASE PS IS
            WHEN IDLE =>
                IF (start = '1') THEN
                    NS <= CHECK_E;
                ELSE
                    NS <= IDLE;
                END IF;
            WHEN CHECK_E =>
                NS <= LOAD_CC;
            WHEN LOAD_CC =>
                NS <= COMP_CC;
            WHEN COMP_CC =>
                IF (mult_finished = '1') THEN
                    IF (e_r(255) = '1') THEN
                        NS <= LOAD_CM;
                    ELSE
                        NS <= CHECK_FINISH;
                    END IF;
                ELSE
                    NS <= COMP_CC;
                END IF;
            WHEN LOAD_CM =>
                NS <= COMP_CM;
            WHEN COMP_CM =>
                IF (mult_finished = '1') THEN
                    NS <= CHECK_FINISH;
                ELSE
                    NS <= COMP_CM;
                END IF;
            WHEN CHECK_FINISH =>
                -- Finished when the counter reaches 254 
                IF (shift_counter >= (C_BLOCK_SIZE - 2)) THEN
                    IF (clear = '1') THEN
                        NS <= IDLE;
                    ELSE
                        NS <= CHECK_FINISH;
                    END IF;
                ELSE
                    NS <= LOAD_CC;
                END IF;
            WHEN OTHERS =>
                NS <= IDLE;
        END CASE;
    END PROCESS;

    -- Clocked process for updating the different registers
    sync_regs : PROCESS (clk, reset_n) IS
    BEGIN
        IF (reset_n = '0') THEN
            m_r <= (OTHERS => '0');
            e_r <= (OTHERS => '0');
            c_r <= (OTHERS => '0');
            flag_reg <= '0';
            shift_counter <= (OTHERS => '0');
        ELSIF (clk'event AND clk = '1') THEN
            m_r <= m_nxt;
            e_r <= e_nxt;
            c_r <= c_nxt;
            flag_reg <= flag_reg_nxt;
            shift_counter <= shift_counter_nxt;
        END IF;
    END PROCESS sync_regs;

    -- Combinatorial process for calculations and operations. Determines calculations to be performed based
    -- the current state(PS).
    comp_proc : PROCESS (PS, start, shift_counter, mult_finished, e_r, m_r, c_r, message, key, mult_out, clear)
    BEGIN
        done <= '0';
        mult_start <= '0';
        busy <= '0';

        m_nxt <= m_r;
        e_nxt <= e_r;
        c_nxt <= c_r;
        flag_reg_nxt <= flag_reg;
        mult_in_a <= c_r;
        mult_in_b <= c_r;
        shift_counter_nxt <= shift_counter;

        CASE PS IS
            WHEN IDLE =>
                shift_counter_nxt <= (OTHERS => '0');
                IF (start = '1') THEN
                    busy <= '1';
                    m_nxt <= message;
                    e_nxt <= key;
                    flag_reg_nxt <= flag_in;
                END IF;

            WHEN CHECK_E =>
                busy <= '1';

                e_nxt <= e_r(254 DOWNTO 0) & '0';

                IF (e_r(255) = '1') THEN
                    c_nxt <= m_r;
                ELSE
                    c_nxt <= (0 => '1', OTHERS => '0');
                END IF;

            WHEN LOAD_CC =>
                busy <= '1';
                mult_start <= '1';
                mult_in_a <= c_r;
                mult_in_b <= c_r;

            WHEN COMP_CC =>
                busy <= '1';
                IF (mult_finished = '1') THEN
                    c_nxt <= mult_out;

                    e_nxt <= e_r(254 DOWNTO 0) & '0';
                END IF;

            WHEN LOAD_CM =>
                busy <= '1';
                mult_start <= '1';
                mult_in_a <= c_r;
                mult_in_b <= m_r;

            WHEN COMP_CM =>
                busy <= '1';
                IF (mult_finished = '1') THEN
                    c_nxt <= mult_out;
                END IF;
            WHEN CHECK_FINISH =>
                busy <= '1';

                IF (shift_counter >= (C_BLOCK_SIZE - 2)) THEN -- Finished 
                    done <= '1';
                    IF (clear = '1') THEN
                        busy <= '0'; --Ready for new data
                    END IF;
                ELSE
                    shift_counter_nxt <= shift_counter + 1;
                END IF;
            WHEN OTHERS =>
                m_nxt <= (OTHERS => '0');
                e_nxt <= (OTHERS => '0');
                c_nxt <= (OTHERS => '0');
                shift_counter_nxt <= (OTHERS => '0');
        END CASE;
    END PROCESS;

    -- Writes result and flag out.
    flag_out <= flag_reg;
    result <= c_r;

END expBehave;