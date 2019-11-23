--------------------------------------------------------------------------------
-- Original Author: Oystein Gjermundnes
-- Organization   : Norwegian University of Science and Technology (NTNU)
--                  Department of Electronic Systems
--                  https://www.ntnu.edu/ies
-- Course         : TFE4141 Design of digital systems 1 (DDS1)
-- Year           : 2018-2019
-- Project        : RSA accelerator
-- License        : This is free and unencumbered software released into the
--                  public domain (UNLICENSE)
--------------------------------------------------------------------------------
-- Student Author : Carl Richard Steen Fosse
-- Organization   : Norwegian University of Science and Technology (NTNU)
--                  Department of Electronic Systems
--                  https://www.ntnu.edu/ies
-- Course         : TFE4141 Design of digital systems 1 (DDS1)
-- Year           : 2018-2019
-- Project        : RSA accelerator
-- License        : This is free and unencumbered software released into the
--                 public domain (UNLICENSE)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
ENTITY rsa_core IS
    GENERIC (
        -- Users to add parameters here
        C_BLOCK_SIZE : INTEGER := 256;
        N_CORES : INTEGER := 21
    );
    PORT (
        -----------------------------------------------------------------------------
        -- Clocks and reset
        -----------------------------------------------------------------------------
        clk : IN std_logic;
        reset_n : IN std_logic;

        -----------------------------------------------------------------------------
        -- Slave msgin interface
        -----------------------------------------------------------------------------
        -- Message that will be sent out is valid
        msgin_valid : IN std_logic;
        -- Slave ready to accept a new message
        msgin_ready : OUT std_logic;
        -- Message that will be sent out of the rsa_msgin module
        msgin_data : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        -- Indicates boundary of last packet
        msgin_last : IN std_logic;

        -----------------------------------------------------------------------------
        -- Master msgout interface
        -----------------------------------------------------------------------------
        -- Message that will be sent out is valid
        msgout_valid : OUT std_logic;
        -- Slave ready to accept a new message
        msgout_ready : IN std_logic;
        -- Message that will be sent out of the rsa_msgin module
        msgout_data : OUT std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        -- Indicates boundary of last packet
        msgout_last : OUT std_logic;

        -----------------------------------------------------------------------------
        -- Interface to the register block
        -----------------------------------------------------------------------------
        key_e_d : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        key_n : IN std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
        rsa_status : OUT std_logic_vector(31 DOWNTO 0)

    );
END rsa_core;

ARCHITECTURE rtl OF rsa_core IS
    ----------------------------------------------------------------------
    -- Input registers
    ----------------------------------------------------------------------
    SIGNAL mod_reg, key_reg : std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);

    ----------------------------------------------------------------------
    -- Counters
    ----------------------------------------------------------------------
    -- Counters pointing to next core to start and next core to finish
    SIGNAL next_to_start, next_to_finish : INTEGER RANGE 0 TO N_CORES - 1;
    SIGNAL next_to_start_nxt, next_to_finish_nxt : INTEGER RANGE 0 TO N_CORES - 1;

    ----------------------------------------------------------------------
    -- Vectors handling input and output control signals of all the cores.
    ----------------------------------------------------------------------
    -- Control vector for starting cores
    SIGNAL cores_start, cores_start_nxt : std_logic_vector(N_CORES - 1 DOWNTO 0);
    -- Control vector for clearing cores when data on output has been read
    SIGNAL cores_clear, cores_clear_nxt : std_logic_vector(N_CORES - 1 DOWNTO 0);

    -- Current state of the cores. 
    SIGNAL cores_done, cores_busy : std_logic_vector(N_CORES - 1 DOWNTO 0);

    ----------------------------------------------------------------------
    -- Output signals
    ----------------------------------------------------------------------
    SIGNAL core_flag_out : std_logic_vector(N_CORES - 1 DOWNTO 0);

    -- Data type and decleration for output data
    TYPE core_data IS ARRAY (N_CORES - 1 DOWNTO 0) OF std_logic_vector(C_BLOCK_SIZE - 1 DOWNTO 0);
    SIGNAL core_data_out : core_data;

    ----------------------------------------------------------------------
    -- FSM type declerations
    ----------------------------------------------------------------------   
    TYPE state_type_input IS (
        IDLE,
        CHECK_CORES,
        WAIT_FOR_CORE_START);
    SIGNAL Input_State, NIS : state_type_input;

    TYPE state_type_output IS (
        MONITOR_CORE_OUTPUT,
        WRITE_DATA);
    SIGNAL Output_State, NOS : state_type_output;

BEGIN

    load_keys : PROCESS (clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            mod_reg <= (OTHERS => '0');
            key_reg <= (OTHERS => '0');
        ELSIF (clk'event AND clk = '1') THEN
            mod_reg <= key_n;
            key_reg <= key_e_d;
        END IF;
    END PROCESS;

    -- Generating expnonentiation cores. They share the msgin_data 
    -- bus, but will only sample when promted. Hence avoiding 
    -- collisions. 
    generating : FOR i IN 0 TO (N_CORES - 1) GENERATE
        exp : ENTITY work.exponentiation
            GENERIC MAP(
                C_block_size => C_BLOCK_SIZE
            )
            PORT MAP(
                message  => msgin_data,
                key      => key_reg,
                busy     => cores_busy(i),
                start    => cores_start(i),
                clear    => cores_clear(i),
                done     => cores_done(i),
                result   => core_data_out(i),
                modulus  => mod_reg,
                flag_in  => msgin_last,
                flag_out => core_flag_out(i),
                clk      => clk,
                reset_n  => reset_n
            );
    END GENERATE;

    -- Clocked process for updating input_state register and counters
    Sync_input : PROCESS (clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            cores_start <= (OTHERS => '0');
            next_to_start <= 0;
            Input_State <= IDLE;
        ELSIF (clk'event AND clk = '1') THEN
            cores_start <= cores_start_nxt;
            next_to_start <= next_to_start_nxt;
            Input_State <= NIS;
        END IF;

    END PROCESS;

    -- Combinatorial process for determining next input state(NIS)
    -- and starting cores when applicable. 
    Input_fsm : PROCESS (Input_State, NIS, msgin_valid, cores_busy)
    BEGIN
        msgin_ready <= '0';

        cores_start_nxt <= (OTHERS => '0');
        next_to_start_nxt <= next_to_start;

        CASE Input_State IS
            WHEN IDLE =>
                IF (msgin_valid = '1') THEN
                    NIS <= CHECK_CORES;
                ELSE
                    NIS <= IDLE;
                END IF;
            WHEN CHECK_CORES =>
                IF (NOT (cores_busy(next_to_start) = '1')) THEN
                    cores_start_nxt(next_to_start) <= '1';

                    -- Check if counter should increment or reset
                    IF (next_to_start >= (N_CORES - 1)) THEN
                        next_to_start_nxt <= 0;
                    ELSE
                        next_to_start_nxt <= next_to_start + 1;
                    END IF;

                    NIS <= WAIT_FOR_CORE_START;
                ELSE
                    NIS <= CHECK_CORES;
                END IF;
            WHEN WAIT_FOR_CORE_START =>
                msgin_ready <= '1';
                NIS <= IDLE;
            WHEN OTHERS =>
                NIS <= IDLE;
        END CASE;
    END PROCESS;

    -- Clocked process for updating output_state registers, 
    -- counters and core control signals.
    Sync_output : PROCESS (clk, reset_n)
    BEGIN
        IF (reset_n = '0') THEN
            cores_clear    <= (OTHERS => '0');
            next_to_finish <= 0;
            Output_State   <= MONITOR_CORE_OUTPUT;
        ELSIF (clk'event AND clk = '1') THEN
            cores_clear    <= cores_clear_nxt;
            next_to_finish <= next_to_finish_nxt;
            Output_State   <= NOS;
        END IF;
    END PROCESS;

    -- Combinatorial process for determinig next output state(NOS) and
    -- writing data out when a core is done.
    Output_fsm : PROCESS (Output_State, NOS, next_to_finish, cores_done, msgout_ready)
    BEGIN
        msgout_data <= (OTHERS => '0');
        msgout_valid <= '0';
        msgout_last <= '0';

        cores_clear_nxt <= (OTHERS => '0');
        next_to_finish_nxt <= next_to_finish;

        CASE Output_State IS
            WHEN MONITOR_CORE_OUTPUT =>
                IF ((cores_done(next_to_finish) = '1')) THEN
                    NOS <= WRITE_DATA;
                ELSE
                    NOS <= MONITOR_CORE_OUTPUT;
                END IF;
            WHEN WRITE_DATA =>
                IF (msgout_ready = '1') THEN
                    msgout_data  <= core_data_out(next_to_finish); -- Read data from core
                    msgout_last  <= core_flag_out(next_to_finish);
                    msgout_valid <= '1';

                    cores_clear_nxt(next_to_finish) <= '1'; --Notify core that it can release data and move to idle.

                    -- Check if counter should increment or reset
                    IF (next_to_finish >= (N_CORES - 1)) THEN
                        next_to_finish_nxt <= 0;
                    ELSE
                        next_to_finish_nxt <= next_to_finish + 1;
                    END IF;

                    NOS <= MONITOR_CORE_OUTPUT;
                ELSE
                    NOS <= WRITE_DATA;
                END IF;
            WHEN OTHERS =>
                NOS <= MONITOR_CORE_OUTPUT;
        END CASE;
    END PROCESS;

    rsa_status <= (OTHERS => '0');
END rtl;