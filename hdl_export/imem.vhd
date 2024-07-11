--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : imem.vhd
-- Description: This file defines a generic instruction memory component named 'imem'.
-- It allows for a configurable address size with a fixed 32-bit instruction width.
-- TODO : Implement functionality to read instructions from a file.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration of imem (instruction memory)
ENTITY imem IS
    GENERIC (
        ADDR_SIZE : INTEGER := 6 -- Generic parameter for address size, default is 6 bits
    );
    PORT (
        a : IN STD_LOGIC_VECTOR(ADDR_SIZE - 1 DOWNTO 0); -- Address input (size determined by ADDR_SIZE)
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- 32-bit output for instruction data
    );
END imem;

-- Architecture definition of imem
ARCHITECTURE behave OF imem IS
    -- Calculate the number of memory locations based on address size
    CONSTANT MEM_SIZE : INTEGER := 2 ** ADDR_SIZE;
BEGIN
    PROCESS (a)
        TYPE ramtype IS ARRAY(MEM_SIZE - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0); -- RAM type based on MEM_SIZE
        VARIABLE mem : ramtype := (OTHERS => (OTHERS => '0')); -- Memory initialization with all zeros
    BEGIN
        -- Initialize memory with MIPS instructions

        -- Example initialization
        mem(0) := X"20020005"; --     addi $v0, $0, 5	    # $v0(2) = 5
        mem(1) := X"2003000c"; --     addi $v1, $0, 12	    # $v1(3) = 12
        mem(2) := X"2067fff7"; --     addi $a3, $v1,-9 	    # $a3(7) = $v1(3) - 9 = 3
        mem(3) := X"00e22025"; --     or   $a0, $a3, $v0	# $a0(4) = $a3(7) or $v0(2) = 3 or 5 = 7
        mem(4) := X"00642824"; --     and  $a1, $v1, $a0	# $a1(5) = $v1(3) and $a0(4)= 12 and 7 = 4
        mem(5) := X"00a42820"; --     add  $a1, $a1, $a0	# $a1(5) = $a1(5) + $a0(4) = 4 + 7 = 11

        -- Set the rest of the memory locations to zeros
        FOR ii IN 6 TO MEM_SIZE - 1 LOOP
            mem(ii) := X"00000000";
        END LOOP;

        -- Read memory operation: Sets the output 'rd' to the value at memory location 'a'
        rd <= mem(TO_INTEGER(unsigned(a))); -- Convert address 'a' to integer for memory indexing
    END PROCESS;
END behave;