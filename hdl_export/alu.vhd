--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : alu.vhd
-- Description: This file defines an Arithmetic Logic Unit (ALU) component named 'alu'.
-- The ALU performs various arithmetic and logical operations based on the input
-- function code 'aluctl'. The size of the input and output vectors can be
-- configured using generic parameters.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY alu IS
    GENERIC (
        DATA_WIDTH : INTEGER := 32 -- Generic parameter for the size of input and output vectors
    );
    PORT (
        srca, srcb : IN STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Input vectors
        aluctl : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Function code to determine the operation
        zero : OUT STD_LOGIC; -- Zero flag output
        aluout : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0') -- Output vector
    );
END alu;

ARCHITECTURE behave OF alu IS
    SIGNAL diff, tmp : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Internal signals for operations
BEGIN

    diff <= srca - srcb; -- Pre-compute the difference for use in subtraction and SLT

    -- Process to perform operations based on function code
    PROCESS (srca, srcb, aluctl, diff, tmp) BEGIN
        CASE aluctl IS
            WHEN "0000" => tmp <= srca AND srcb; -- AND
            WHEN "0001" => tmp <= srca OR srcb; -- OR
            WHEN "0010" => tmp <= srca + srcb; -- ADD
            WHEN "0100" => tmp <= srca AND (NOT srcb); -- NAND
            WHEN "0101" => tmp <= srca OR (NOT srcb); -- NOR
            WHEN "0110" => tmp <= diff; -- SUB
            WHEN "0111" => tmp <= X"0000000" & "000" & diff(DATA_WIDTH - 1); -- SLT
            WHEN OTHERS => tmp <= (OTHERS => '1'); -- Default case
        END CASE;
    END PROCESS;

    zero <= '1' WHEN tmp = (OTHERS => '0') ELSE
        '0'; -- Zero flag set if result is zero
    aluout <= tmp; -- Output the result
END behave;