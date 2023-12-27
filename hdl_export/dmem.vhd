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

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

-- Entity declaration of dmem (data memory)
entity dmem is
    GENERIC (
        MEM_SIZE : INTEGER := 64 -- Generic parameter for memory size, default is 64 locations
    );
    port(
        clk, we : in STD_LOGIC; -- Clock and write enable signals
        a : in STD_LOGIC_VECTOR(31 downto 0); -- Address input (32-bit)
        wd : in STD_LOGIC_VECTOR(31 downto 0); -- Write data input (32-bit)
        rd : out STD_LOGIC_VECTOR(31 downto 0) -- Read data output (32-bit)
    );
end dmem;

-- Architecture of dmem
architecture behave of dmem is
    -- Define the memory type based on the generic parameter MEM_SIZE
    type ramtype is array(MEM_SIZE - 1 downto 0) of STD_LOGIC_VECTOR(31 downto 0);
    signal mem : ramtype := (others => (others => '0')); -- Initialize memory to zeros
begin
    -- Process for handling memory operations
    process(clk, a)
    begin
        -- Synchronous write operation
        if rising_edge(clk) then
            if we = '1' and TO_INTEGER(unsigned(a)) < MEM_SIZE then 
                mem(TO_INTEGER(unsigned(a))) := wd; -- Write data to memory if within bounds
            end if;
        end if;
        -- Combinational read operation
        rd <= mem(TO_INTEGER(unsigned(a))) when TO_INTEGER(unsigned(a)) < MEM_SIZE else (others => '0'); -- Read data or return zeros if address is out of bounds
    end process;
end behave;
end behave;
