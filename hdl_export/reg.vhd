---------------------------------------------------------------------------------------
-- Project : MIPSim
-- File    : reg.vhd
-- Description: This file defines a three-port register component named 'reg'.
-- The register includes two read ports and one write port. It is designed
-- for use in MIPS processor simulations, providing read and write functionalities
-- to the registers based on the control signals. The write operation is
-- synchronized with the rising edge of the clock, while the read operations are
-- combinational.
---------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Entity declaration of three-port register
ENTITY reg IS
    PORT (
        clk : IN STD_LOGIC; -- Clock input
        we3 : IN STD_LOGIC; -- Write enable for the third port
        a1, a2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Read address for ports 1 and 2
        wa3 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); -- Write address for port 3
        wd3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- Write data for port 3
        rd1, rd2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) -- Read data from ports 1 and 2
    );
END reg;

-- Architecture definition of register
ARCHITECTURE behave OF reg IS
    -- Define the register array type
    TYPE ramtype IS ARRAY(31 DOWNTO 0) OF STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL mem : ramtype; -- Memory signal to store the register values
BEGIN
    -- Process for handling write operations to the register
    PROCESS (clk) BEGIN
        IF rising_edge(clk) THEN -- Trigger on the rising edge of the clock
            IF we3 = '1' THEN
                mem(TO_INTEGER(unsigned(wa3))) <= wd3; -- Write to the register when write enable is asserted
            END IF;
        END IF;
    END PROCESS;

    -- Read operations for ports 1 and 2 are combinational
    rd1 <= X"00000000" WHEN a1 = "00000" ELSE
        mem(TO_INTEGER(unsigned(a1))); -- Output zero or the register data based on the read address

    rd2 <= X"00000000" WHEN a2 = "00000" ELSE
        mem(TO_INTEGER(unsigned(a2))); -- Output zero or the register data based on the read address
END behave;