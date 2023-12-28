--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : alu.vhd
-- Description: This file defines an Arithmetic Logic Unit (ALU) component named 'alu'.
-- The ALU performs various arithmetic and logical operations based on the input
-- function code 'f'. The size of the input and output vectors can be
-- configured using generic parameters.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY alu IS
    GENERIC (
        VECTOR_SIZE : INTEGER := 32 -- Generic parameter for the size of input and output vectors
    );
    PORT (
        a, b : IN STD_LOGIC_VECTOR(VECTOR_SIZE - 1 DOWNTO 0); -- Input vectors
        f : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Function code to determine the operation
        z : OUT STD_LOGIC; -- Zero flag output
        y : OUT STD_LOGIC_VECTOR(VECTOR_SIZE - 1 DOWNTO 0) := (OTHERS => '0') -- Output vector
    );
END alu;

ARCHITECTURE behave OF alu IS
    SIGNAL diff, tmp : STD_LOGIC_VECTOR(VECTOR_SIZE - 1 DOWNTO 0); -- Internal signals for operations
BEGIN

    diff <= a - b; -- Pre-compute the difference for use in subtraction and SLT

    -- Process to perform operations based on function code
    PROCESS (a, b, f, diff, tmp) BEGIN
        CASE f IS
            WHEN "0000" => tmp <= a AND b; -- AND operation
            WHEN "0001" => tmp <= a OR b; -- OR operation
            WHEN "0010" => tmp <= a + b; -- Addition
            WHEN "0100" => tmp <= a AND (NOT b); -- NAND operation
            WHEN "0101" => tmp <= a OR (NOT b); -- NOR operation
            WHEN "0110" => tmp <= diff; -- Subtraction
            WHEN "0111" => tmp <= X"0000000" & "000" & diff(VECTOR_SIZE - 1); -- SLT
            WHEN OTHERS => tmp <= (OTHERS => '1'); -- Default case
        END CASE;
    END PROCESS;

    z <= '1' WHEN tmp = (OTHERS => '0') ELSE
        '0'; -- Zero flag set if result is zero
    y <= tmp; -- Output the result
END behave;