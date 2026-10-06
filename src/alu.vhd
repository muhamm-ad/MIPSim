--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : alu.vhd
-- Description: This file defines an Arithmetic Logic Unit (ALU) component named 'alu'.
-- The ALU performs various arithmetic and logical operations based on the input
-- function code 'aluctl'. The size of the input and output vectors can be
-- configured using generic parameters.
--
-- aluctl encoding (see docs/supported-instructions.md):
--   0000 A AND B        0100 A AND (NOT B)     1000 SLTU (unsigned A < B ? 1 : 0)
--   0001 A OR  B        0101 A OR  (NOT B)     1001 A XOR B
--   0010 A + B          0110 A - B             1010 B << shamt   (SLL)
--   0011 A NOR B        0111 SLT (signed)      1011 B >> shamt   (SRL, logical)
--                                              1100 B >> shamt   (SRA, arithmetic)
-- The shifts operate on B (the 'rt' register) by the constant 'shamt' field of
-- the instruction, as in MIPS (sll rd, rt, shamt).
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
        shamt : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Shift amount (instruction bits 10:6)
        aluctl : IN STD_LOGIC_VECTOR(3 DOWNTO 0); -- Function code to determine the operation
        zero : OUT STD_LOGIC; -- Zero flag output
        aluout : OUT STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0') -- Output vector
    );
END alu;

ARCHITECTURE behave OF alu IS
    SIGNAL tmp : STD_LOGIC_VECTOR(DATA_WIDTH - 1 DOWNTO 0); -- Internal result of the selected operation
BEGIN

    -- Process to perform operations based on function code
    PROCESS (srca, srcb, shamt, aluctl) BEGIN
        CASE aluctl IS
            WHEN "0000" => tmp <= srca AND srcb; -- AND
            WHEN "0001" => tmp <= srca OR srcb; -- OR
            WHEN "0010" => tmp <= STD_LOGIC_VECTOR(unsigned(srca) + unsigned(srcb)); -- ADD
            WHEN "0011" => tmp <= srca NOR srcb; -- NOR
            WHEN "0100" => tmp <= srca AND (NOT srcb); -- A AND (NOT B)
            WHEN "0101" => tmp <= srca OR (NOT srcb); -- A OR (NOT B)
            WHEN "0110" => tmp <= STD_LOGIC_VECTOR(unsigned(srca) - unsigned(srcb)); -- SUB
            WHEN "0111" => -- SLT (signed comparison, correct even when A - B overflows)
                IF signed(srca) < signed(srcb) THEN
                    tmp <= (0 => '1', OTHERS => '0');
                ELSE
                    tmp <= (OTHERS => '0');
                END IF;
            WHEN "1000" => -- SLTU (unsigned comparison)
                IF unsigned(srca) < unsigned(srcb) THEN
                    tmp <= (0 => '1', OTHERS => '0');
                ELSE
                    tmp <= (OTHERS => '0');
                END IF;
            WHEN "1001" => tmp <= srca XOR srcb; -- XOR
            WHEN "1010" => tmp <= STD_LOGIC_VECTOR(shift_left(unsigned(srcb), TO_INTEGER(unsigned(shamt)))); -- SLL
            WHEN "1011" => tmp <= STD_LOGIC_VECTOR(shift_right(unsigned(srcb), TO_INTEGER(unsigned(shamt)))); -- SRL
            WHEN "1100" => tmp <= STD_LOGIC_VECTOR(shift_right(signed(srcb), TO_INTEGER(unsigned(shamt)))); -- SRA
            WHEN OTHERS => tmp <= (OTHERS => '1'); -- Default case
        END CASE;
    END PROCESS;

    zero <= '1' WHEN unsigned(tmp) = 0 ELSE
        '0'; -- Zero flag set if result is zero
    aluout <= tmp; -- Output the result
END behave;
