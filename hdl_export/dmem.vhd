--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : dmem.vhd
-- Description: This file defines a generic data memory component named 'dmem'.
-- It allows for configurable memory size with a fixed 32-bit data width.
-- The memory supports synchronous write operations (on the rising edge of
-- the clock) and combinational read operations. A default memory size can be
-- overridden to accommodate different memory requirements.
--
-- Addressing: 'a' is a MIPS *byte* address of an aligned word (as produced by
-- lw/sw: R[rs] + SignExtImm). The word index is a(31 downto 2); the two low
-- bits are ignored. Out-of-range reads return zero, out-of-range writes are
-- ignored.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration of dmem (data memory)
ENTITY dmem IS
    GENERIC (
        MEM_SIZE : INTEGER := 64 -- Generic parameter for memory size in words, default is 64 locations
    );
    PORT (
        clk, we : IN STD_LOGIC; -- Clock and write enable signals
        a : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Byte address input (32-bit)
        wd : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Write data input (32-bit)
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- Read data output (32-bit)
    );
END dmem;

-- Architecture of dmem
ARCHITECTURE behave OF dmem IS
    -- Define the memory type based on the generic parameter MEM_SIZE
    TYPE ramtype IS ARRAY(MEM_SIZE - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : ramtype := (OTHERS => (OTHERS => '0')); -- Initialize memory to zeros
    SIGNAL word_index : INTEGER; -- Word index derived from the byte address
BEGIN
    -- An unknown address ('U'/'X') is treated as word 0 for indexing purposes
    word_index <= TO_INTEGER(unsigned(a(31 DOWNTO 2))) WHEN NOT is_x(a) ELSE
        0;

    -- Synchronous write operation
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF we = '1' AND NOT is_x(a) AND word_index < MEM_SIZE THEN
                mem(word_index) <= wd; -- Write data to memory if within bounds
            END IF;
        END IF;
    END PROCESS;

    -- Combinational read operation
    rd <= mem(word_index) WHEN word_index < MEM_SIZE ELSE
        (OTHERS => '0'); -- Read data or return zeros if address is out of bounds
END behave;
