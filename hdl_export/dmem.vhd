--------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : dmem.vhd
-- Description: This file defines a generic data memory component named 'dmem'.
-- It allows for configurable memory size with a fixed 32-bit data width. 
-- The memory supports synchronous write operations (on the rising edge of 
-- the clock) and combinational read operations. A default memory size can be 
-- overridden to accommodate different memory requirements.
-- TODO Adjust the memory allocation according to the MIPS architecture.
--------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration of dmem (data memory)
ENTITY dmem IS
    GENERIC (
        MEM_SIZE : INTEGER := 64 -- Generic parameter for memory size, default is 64 locations
    );
    PORT (
        clk, we : IN STD_LOGIC; -- Clock and write enable signals
        a : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Address input (32-bit)
        wd : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Write data input (32-bit)
        rd : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- Read data output (32-bit)
    );
END dmem;

-- Architecture of dmem
ARCHITECTURE behave OF dmem IS
    -- Define the memory type based on the generic parameter MEM_SIZE
    TYPE ramtype IS ARRAY(MEM_SIZE - 1 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : ramtype := (OTHERS => (OTHERS => '0')); -- Initialize memory to zeros
BEGIN
    PROCESS (clk, a)
    BEGIN
        -- Synchronous write operation
        IF rising_edge(clk) THEN
            IF we = '1' AND TO_INTEGER(unsigned(a)) < MEM_SIZE THEN
                mem(TO_INTEGER(unsigned(a))) := wd; -- Write data to memory if within bounds
            END IF;
        END IF;
        -- Combinational read operation
        rd <= mem(TO_INTEGER(unsigned(a))) WHEN TO_INTEGER(unsigned(a)) < MEM_SIZE ELSE
            (OTHERS => '0'); -- Read data or return zeros if address is out of bounds
    END PROCESS;
END behave;