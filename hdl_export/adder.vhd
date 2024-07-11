--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : adder.vhd
-- Description: This file defines a generic adder component named 'adder'.
-- The adder performs addition of two input vectors 'v1' and 'v2'. The size of
-- the input and output vectors is configurable using a generic parameter.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration of adder (generic adder)
ENTITY adder IS
    GENERIC (
        VECTOR_SIZE : INTEGER := 32 -- Generic parameter for the size of input and output vectors
    );
    PORT (
        v1, v2 : IN STD_LOGIC_VECTOR(VECTOR_SIZE - 1 DOWNTO 0); -- Input vectors for addition
        vr : OUT STD_LOGIC_VECTOR(VECTOR_SIZE - 1 DOWNTO 0) -- Output vector for the sum
    );
END adder;

-- Architecture of adder
ARCHITECTURE behave OF adder IS
BEGIN
    vr <= v1 + v2; -- Perform addition operation
END behave;