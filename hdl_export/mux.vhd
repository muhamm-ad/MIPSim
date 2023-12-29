--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : mux.vhd
-- Description: This file defines a generic multiplexer component named 'mux'.
-- The multiplexer selects one of the 'N' input signals based on the select line
-- and forwards it to the output. The width of the data inputs and the number
-- of inputs are configurable using generic parameters. The functionality is
-- similar to data_out = data_in[select].
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL; -- For using the TO_INTEGER function

-- Entity declaration of mux (generic multiplexer)
ENTITY mux IS
    GENERIC (
        DATA_WIDTH : INTEGER := 1; -- Width of each input data line
        N_INPUTS : INTEGER := 2 -- Number of input data lines
    );
    PORT (
        data_in : IN STD_LOGIC_VECTOR(N_INPUTS * DATA_WIDTH - 1 DOWNTO 0); -- Concatenated input data lines
        select_ : IN STD_LOGIC_VECTOR(INTEGER'ceil(log2(real(N_INPUTS))) - 1 DOWNTO 0); -- Select line
        data_out : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) -- Output data line
    );
END mux;

-- Architecture of mux
ARCHITECTURE behave OF mux IS
BEGIN
    -- Process for multiplexing the input data based on the select line
    PROCESS (data_in, select_)
        VARIABLE selected_index : INTEGER;
    BEGIN
        selected_index := TO_INTEGER(unsigned(select_)) * DATA_WIDTH;
        data_out <= data_in(selected_index + DATA_WIDTH - 1 DOWNTO selected_index);
    END PROCESS;
END behave;